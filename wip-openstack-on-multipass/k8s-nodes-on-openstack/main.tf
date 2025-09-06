# 外部ネットワークの情報を名前("external")で検索して読み込む
data "openstack_networking_network_v2" "external_net" {
  name = "external"
}

# --- ネットワーク関連 ---
resource "openstack_networking_network_v2" "k8s_net" {
  name = "k8s-net"
}
resource "openstack_networking_subnet_v2" "k8s_subnet" {
  network_id = openstack_networking_network_v2.k8s_net.id
  name       = "k8s-subnet"
  cidr       = "10.0.1.0/24"
}
resource "openstack_networking_router_v2" "k8s_router" {
  name                = "k8s-router"
  external_network_id = data.openstack_networking_network_v2.external_net.id # ← こちらの行に置き換える
}
resource "openstack_networking_router_interface_v2" "k8s_router_interface" {
  router_id = openstack_networking_router_v2.k8s_router.id
  subnet_id = openstack_networking_subnet_v2.k8s_subnet.id
}

# --- セキュリティグループ (ファイアウォール) ---
resource "openstack_compute_secgroup_v2" "k8s_secgroup" {
  name        = "k8s-secgroup"
  description = "Allow all internal traffic and external SSH"
  rule { # 内部NWからの通信を許可
    from_port   = 1
    to_port     = 65535
    ip_protocol = "tcp"
    cidr        = "10.0.1.0/24"
  }
  rule { # 内部NWからの通信を許可
    from_port   = 1
    to_port     = 65535
    ip_protocol = "udp"
    cidr        = "10.0.1.0/24"
  }
  rule { # 内部NWからの通信を許可
    from_port   = -1
    to_port     = -1
    ip_protocol = "icmp"
    cidr        = "10.0.1.0/24"
  }
  rule { # 外部からのSSHを許可
    from_port   = 22
    to_port     = 22
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }
}

# --- SSHキーペア ---
resource "openstack_compute_keypair_v2" "k8s_key" {
  name       = "k8s-key"
  public_key = file("~/.ssh/id_rsa.pub") # Mac上の公開鍵
}

# --- Kubernetes VMインスタンス (3コントローラー, 3ワーカー) ---
locals {
  cp_instance_count     = 1
  worker_instance_count = 2
}

resource "openstack_compute_instance_v2" "controller" {
  count           = local.cp_instance_count
  name            = "controller-${count.index}"
  image_name      = openstack_images_image_v2.ubuntu_2204.name # Terraformリソースを参照する
  flavor_name     = "m1.small"
  key_pair        = openstack_compute_keypair_v2.k8s_key.name
  security_groups = [openstack_compute_secgroup_v2.k8s_secgroup.name]
  network {
    name = openstack_networking_network_v2.k8s_net.name
  }
}

resource "openstack_compute_instance_v2" "worker" {
  count           = local.worker_instance_count
  name            = "worker-${count.index}"
  image_name      = openstack_images_image_v2.ubuntu_2204.name # Terraformリソースを参照する
  flavor_name     = "m1.small"
  key_pair        = openstack_compute_keypair_v2.k8s_key.name
  security_groups = [openstack_compute_secgroup_v2.k8s_secgroup.name]
  network {
    name = openstack_networking_network_v2.k8s_net.name
  }
}
