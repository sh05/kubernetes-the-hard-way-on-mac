variable "instances" {
  description = "Map of instance configurations"
  type = map(object({
    cpu    = string
    memory = string
    disk   = string
  }))
  default = {
    server = {
      cpu    = "1"
      memory = "2GB"
      disk   = "20G"
    }
    node-0 = {
      cpu    = "1"
      memory = "2GB"
      disk   = "20G"
    }
    node-1 = {
      cpu    = "1"
      memory = "2GB"
      disk   = "20G"
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

variable "cloud_init_file" {
  description = "Path to cloud-init configuration file"
  type        = string
  default     = "./cloud-init.yaml"
}

