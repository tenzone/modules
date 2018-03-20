variable "serverport" {
  default = "8080"
  description = "Server port to listen on"
}

variable "cidr-blocks" {
  description = "cidr blocks to allow access to"
  type = "map"
  default = {
    everyone = "0.0.0.0/0"
  }
}

variable "cluster_name" {}
variable "db_remote_state_bucket" {}
variable "db_remote_state_key" {}


variable "instance_type" {}
variable "min_size" {}
variable "max_size" {}

variable "enable_autoscaling" {
  description = "If set to true, enable auto scaling"
}
