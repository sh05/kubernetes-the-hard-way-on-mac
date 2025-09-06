data "multipass_instance" "instances_data" {
  for_each = var.instances

  name       = each.key
  depends_on = [multipass_instance.instances]
}

output "instance_ips" {
  description = "IP addresses of all instances"
  value = {
    for k, v in data.multipass_instance.instances_data : k => v.instance.ipv4
  }
}

output "instance_shell_commands" {
  description = "Commands to SSH into instances"
  value = {
    for k, v in multipass_instance.instances : k => "multipass shell ${v.name}"
  }
}
