variable "instances" {
  description = "Map of instance configurations"
  type = map(object({
    cpu        = string
    memory     = string
    disk       = string
    cloud_init = string
  }))
  default = {
    jumpbox = {
      cpu        = "1"
      memory     = "512MB"
      disk       = "10G"
      cloud_init = "./cloud-init-jumpbox.yaml"
    }
    server = {
      cpu        = "1"
      memory     = "2GB"
      disk       = "20G"
      cloud_init = "./cloud-init-common.yaml"
    }
    node-0 = {
      cpu        = "1"
      memory     = "2GB"
      disk       = "20G"
      cloud_init = "./cloud-init-common.yaml"
    }
    node-1 = {
      cpu        = "1"
      memory     = "2GB"
      disk       = "20G"
      cloud_init = "./cloud-init-common.yaml"
    }
  }
}

variable "image" {
  description = "Ubuntu image version to use"
  type        = string
  default     = "22.04"
}

variable "launch_timeout" {
  description = "Launch timeout for instances"
  type        = string
  default     = "30m"
}
