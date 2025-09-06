resource "openstack_images_image_v2" "ubuntu_2204" {
  # OpenStack上で表示されるイメージ名
  name = "ubuntu-22.04-lts"

  # イメージのソースURLを直接指定
  image_source_url = "https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"

  # イメージのフォーマット情報
  container_format = "bare"
  disk_format      = "qcow2"

  # (オプション) イメージに関するメタデータを付与すると管理しやすくなる
  properties = {
    os_distro  = "ubuntu"
    os_version = "22.04"
  }
}
