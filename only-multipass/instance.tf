resource "multipass_instance" "instances" {
  for_each = var.instances

  name           = each.key
  image          = var.image
  cpu            = each.value.cpu
  memory         = each.value.memory
  disk           = each.value.disk
  cloud_init     = var.cloud_init_file
  launch_timeout = var.launch_timeout
}
