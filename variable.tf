variable "namespace" {
    description = "The project namespace for resource naming"
    default = "threetier"
}
variable "region" {
  description = "AWS region"
  default = "us-east-1"
}
variable "ssh_keypair" {
    description = "SSH keypair to use for autoscaling"
    default = null
    type = string
}
