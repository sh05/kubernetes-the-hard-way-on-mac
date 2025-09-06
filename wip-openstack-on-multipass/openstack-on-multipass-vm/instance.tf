resource "multipass_instance" "openstack_vm" {
  name           = "openstack-vm"
  image          = "22.04"
  cpu            = "1"
  memory         = "2G"
  disk           = "20G"
  cloud_init     = "./cloud-init.yaml"
  launch_timeout = "30m"
}
