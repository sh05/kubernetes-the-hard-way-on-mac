data "multipass_instance" "openstack_vm_data" {
  name       = "openstack-vm"
  depends_on = [multipass_instance.openstack_vm]
}

output "instance_ip" {
  description = "The primary IPv4 address of the instance."
  value       = data.multipass_instance.openstack_vm_data.instance.ipv4
}

output "shell_command" {
  description = "Command to SSH into the instance."
  value       = "multipass shell ${multipass_instance.openstack_vm.name}"
}
