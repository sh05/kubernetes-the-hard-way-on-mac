# jumpbox インスタンス用 Kubernetes The Hard Way セットアップ計画

## 目的
jumpboxインスタンスに対して、Kubernetes The Hard Way のガイド（https://raw.githubusercontent.com/kelseyhightower/kubernetes-the-hard-way/refs/heads/master/docs/02-jumpbox.md）に従った自動セットアップを実装する。

## 現在の構成分析

### 既存のTerraform設定
- `instance.tf`: 全インスタンスが同一のcloud-init設定を使用
- `variables.tf`: jumpbox, server, node-0, node-1の4インスタンス定義
- `cloud-init.yaml`: 全インスタンス共通の設定（SSH root login有効化済み）

### jumpboxの役割
- **管理専用マシン**: Kubernetesクラスターのセットアップと管理を行う「ベースキャンプ」
- **作業ディレクトリ**: `/root/kubernetes-the-hard-way`
- **バイナリ管理**: Kubernetes関連バイナリの整理と配布

## 実装計画

### 1. jumpbox専用cloud-init設定作成

#### ファイル: `cloud-init-jumpbox.yaml`
```yaml
#cloud-config
package_update: true
package_upgrade: true

# 基本パッケージ + jumpbox専用ツール
packages:
  - curl
  - wget
  - vim
  - htop
  - net-tools
  - apt-transport-https
  - ca-certificates
  - gnupg
  - lsb-release
  - openssl    # jumpbox専用
  - git        # jumpbox専用

# SSH root login設定（既存設定と同様）
ssh_pwauth: true
disable_root: false
write_files:
  - path: /etc/ssh/sshd_config.d/50-root-login.conf
    content: |
      PermitRootLogin yes
    owner: root:root
    permissions: '0644'

users:
  - name: root
    lock_passwd: false
    passwd: "..."

# Kubernetes The Hard Way セットアップの自動化
runcmd:
  - systemctl restart sshd
  
  # 1. リポジトリクローン（作業ディレクトリ: /root/kubernetes-the-hard-way）
  - git clone --depth 1 https://github.com/kelseyhightower/kubernetes-the-hard-way.git /root/kubernetes-the-hard-way
  - cd /root/kubernetes-the-hard-way
  
  # 2. アーキテクチャ検出とバイナリダウンロード
  - ARCH=$(dpkg --print-architecture)
  - wget -q --show-progress --https-only --timestamping -P downloads -i downloads-${ARCH}.txt
  
  # 3. バイナリ整理用ディレクトリ作成
  - mkdir -p downloads/{client,cni-plugins,controller,worker}
  
  # 4. バイナリの展開と整理
  - tar -xvf downloads/crictl-v1.32.0-linux-${ARCH}.tar.gz -C downloads/worker/
  - tar -xvf downloads/containerd-2.1.0-beta.0-linux-${ARCH}.tar.gz --strip-components 1 -C downloads/worker/
  - tar -xvf downloads/cni-plugins-linux-${ARCH}-v1.6.2.tgz -C downloads/cni-plugins/
  - tar -xvf downloads/etcd-v3.6.0-rc.3-linux-${ARCH}.tar.gz -C downloads/ --strip-components 1 etcd-v3.6.0-rc.3-linux-${ARCH}/etcdctl etcd-v3.6.0-rc.3-linux-${ARCH}/etcd
  
  # 5. バイナリの適切な配置
  - mv downloads/etcdctl downloads/kubectl downloads/client/
  - mv downloads/etcd downloads/kube-apiserver downloads/kube-controller-manager downloads/kube-scheduler downloads/controller/
  - mv downloads/kubelet downloads/kube-proxy downloads/worker/
  - mv downloads/runc.${ARCH} downloads/worker/runc
  
  # 6. アーカイブファイルの削除
  - rm -rf downloads/*gz downloads/*tar.gz downloads/*tgz
  
  # 7. 実行権限付与
  - chmod +x downloads/client/* downloads/controller/* downloads/worker/* downloads/cni-plugins/*
  
  # 8. kubectlのシステムインストール
  - cp downloads/client/kubectl /usr/local/bin/
  - chmod +x /usr/local/bin/kubectl
  
  # 9. セットアップ完了記録
  - echo "Kubernetes The Hard Way jumpbox setup completed at $(date)" > /root/setup-complete.txt
  - echo "Working directory: /root/kubernetes-the-hard-way" >> /root/setup-complete.txt
  - echo "Binaries organized in downloads/ subdirectories:" >> /root/setup-complete.txt
  - echo "  - client/: kubectl, etcdctl" >> /root/setup-complete.txt
  - echo "  - controller/: etcd, kube-apiserver, kube-controller-manager, kube-scheduler" >> /root/setup-complete.txt
  - echo "  - worker/: kubelet, kube-proxy, crictl, containerd, runc" >> /root/setup-complete.txt
  - echo "  - cni-plugins/: CNI network plugins" >> /root/setup-complete.txt
  - kubectl version --client >> /root/setup-complete.txt 2>&1 || echo "kubectl installation verification failed" >> /root/setup-complete.txt
```

### 2. Terraform設定の更新

#### 方法1: インスタンス別cloud-init設定（推奨）

**variables.tf** に新しい変数を追加:
```hcl
variable "cloud_init_files" {
  description = "Map of instance-specific cloud-init files"
  type        = map(string)
  default = {
    jumpbox = "./cloud-init-jumpbox.yaml"
    server  = "./cloud-init.yaml"
    node-0  = "./cloud-init.yaml"
    node-1  = "./cloud-init.yaml"
  }
}
```

**instance.tf** を更新:
```hcl
resource "multipass_instance" "instances" {
  for_each = var.instances

  name           = each.key
  image          = var.image
  cpu            = each.value.cpu
  memory         = each.value.memory
  disk           = each.value.disk
  cloud_init     = var.cloud_init_files[each.key]
  launch_timeout = var.launch_timeout
}
```

#### 方法2: 条件分岐を使用した単一設定ファイル（代替案）

**instance.tf** で条件分岐:
```hcl
resource "multipass_instance" "instances" {
  for_each = var.instances

  name           = each.key
  image          = var.image
  cpu            = each.value.cpu
  memory         = each.value.memory
  disk           = each.value.disk
  cloud_init     = each.key == "jumpbox" ? "./cloud-init-jumpbox.yaml" : var.cloud_init_file
  launch_timeout = var.launch_timeout
}
```

## バイナリ配置詳細

### ダウンロードされるバイナリ（アーキテクチャ依存）
- crictl-v1.32.0-linux-${ARCH}.tar.gz
- containerd-2.1.0-beta.0-linux-${ARCH}.tar.gz
- cni-plugins-linux-${ARCH}-v1.6.2.tgz
- etcd-v3.6.0-rc.3-linux-${ARCH}.tar.gz
- その他kubectl等の単体バイナリ

### 最終的なディレクトリ構造
```
/root/kubernetes-the-hard-way/
├── downloads/
│   ├── client/
│   │   ├── kubectl
│   │   └── etcdctl
│   ├── controller/
│   │   ├── etcd
│   │   ├── kube-apiserver
│   │   ├── kube-controller-manager
│   │   └── kube-scheduler
│   ├── worker/
│   │   ├── kubelet
│   │   ├── kube-proxy
│   │   ├── crictl
│   │   ├── containerd
│   │   └── runc
│   └── cni-plugins/
│       └── [CNI plugin binaries]
└── [その他の設定ファイル]
```

### システムレベルインストール
- `/usr/local/bin/kubectl`: kubectlをPATHで利用可能

## 検証項目

### セットアップ完了の確認
1. jumpboxインスタンスに接続: `multipass shell jumpbox`
2. 作業ディレクトリ確認: `ls -la /root/kubernetes-the-hard-way/`
3. バイナリ配置確認: `ls -la /root/kubernetes-the-hard-way/downloads/*/`
4. kubectl動作確認: `kubectl version --client`
5. セットアップログ確認: `cat /root/setup-complete.txt`

### 他インスタンスへの影響なし確認
- server, node-0, node-1は既存のcloud-init.yamlを継続使用
- 基本的なSSH接続とパッケージインストールのみ

## 実装手順

1. `cloud-init-jumpbox.yaml` の作成
2. `variables.tf` の更新（cloud_init_filesマップ追加）
3. `instance.tf` の更新（インスタンス別cloud-init設定）
4. `tofu plan` で設定確認
5. `tofu apply` で適用
6. jumpboxインスタンスでのセットアップ検証

## 注意事項

- jumpboxのメモリを512MBから1GB以上に増設推奨（バイナリダウンロード・展開のため）
- ネットワーク接続が必要（GitHubからのクローン、バイナリダウンロード）
- セットアップ時間: 初回起動時に5-10分程度
- 既存インスタンスが稼働中の場合、jumpboxのみ再作成が必要