variable "key_name" {
  description = "SSH key name in your AWS account for AWS instances."
}

variable "region" {
  default     = "us-east-1"
  description = "The region of AWS, for AMI lookups."
}

variable "servers" {
  default     = "3"
  description = "The number of Consul servers to launch."
}

variable "instance_type" {
  default     = "t2.micro"
  description = "AWS Instance type, if you change, make sure it is compatible with AMI, not all AMIs allow all instance types "
}

variable "subnet" {
  type        = "string"
  description = "Subnet to deploy to"
}

variable "vpc_id" {
  type        = "string"
  description = "ID of the VPC to use - in case your account doesn't have default VPC"
}

variable "consul_access" {
  type        = "string"
  default     = "0.0.0.0/0"
  description = "Whitelisted IP Addresses for Consul Cluster Access KV"
}

variable "resource_tags" {
  description = "Optional map of tags to set on resources, defaults to empty map."
  type        = "map"
  default     = {}
}

variable "consul_datacenter" {
  description = "Consul Datacenter"
  type        = "string"
  default     = "dc1"
}

variable "env" {
  description = "Name of environment that Consul is running in"
  type        = "string"
}

variable "service_name" {
  description = "Name of Service. Should most likely by consul"
  type        = "string"
  default     = "consul"
}

variable "service_version" {
  description = "Version of AMI to user"
  type        = "string"
  default     = "1.0.0"
}

variable "availability_zone" {
  description = "AWS to place Consul Cluster"
  type        = "string"
}
