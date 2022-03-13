variable "instance_type" {
  description = "Type of instance for DDoS"
  default     = "t3a.micro"
}
variable "instance_count" {
  description = "Number of instances for DDoS"
  default     = "5"
}
variable "instance_lifetime" {
  description = "Time to rotate the instance"
  default     = "30 minutes"
}
