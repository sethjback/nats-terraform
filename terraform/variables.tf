variable "vpc_id" {
  type        = string
  default     = null
  description = "VPC to install nats into. If empty, a new VPC will be created"
}

variable "public_access" {
  type        = bool
  default     = true
  description = "Allow public (non-vpc) access to the nats server"
}

variable "server_count" {
  type        = number
  default     = 3
  description = "Number of nats servers to provision."
}

variable "cluster_name" {
  type        = string
  default     = "nats-cluster"
  description = "Name of the cluster to create"
}

variable "availability_zones" {
  type        = list(string)
  default     = null
  description = "Availability zones to install nats servers into. If empty, they will be spread across available zones."
}

variable "instance_type" {
  type        = string
  default     = "t2.micro"
  description = "Instance type to use for nats servers."
}

variable "operator_jwt" {
  type        = string
  description = "Operator JWT. Most easily generated via NSC. See https://docs.nats.io/using-nats/nats-tools/nsc"
}

variable "system_account_id" {
  type        = string
  description = "System Account ID. Most easily generated via NSC. See https://docs.nats.io/using-nats/nats-tools/nsc"
}

variable "system_account_jwt" {
  type        = string
  description = "System Account JWT, signed by provided operator. Most easily generated via NSC. See https://docs.nats.io/using-nats/nats-tools/nsc"
}

variable "enable_js" {
  type        = bool
  default     = true
  description = "Enable Jestream"
}
