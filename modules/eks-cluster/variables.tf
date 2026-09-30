variable "cluster_name" {
  type = string
}

variable "cluster_version" {
  type    = string
  default = "1.31"
}

variable "region" {
  type    = string
  default = "ap-south-1"
}

variable "node_group_name" {
  type = string
}

variable "instance_type" {
  type    = string
  default = "t4g.small"
}

variable "desired_capacity" {
  type    = number
  default = 1
}

variable "min_size" {
  type    = number
  default = 1
}

variable "max_size" {
  type    = number
  default = 1
}

variable "admin_iam_role_arn" {
  type = string
}

variable "view_only_iam_role_arn" {
  type = string
}
