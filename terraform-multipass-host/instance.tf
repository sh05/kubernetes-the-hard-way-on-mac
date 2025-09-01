resource "multipass_instance" "openstack_vm" {
  name       = "openstack-vm"
  image      = "22.04"
  cpu        = "4"
  memory     = "8G"
  disk       = "50G"
  cloud_init = "./cloud-init.yaml"
}
