variable "cloud_id" {
  description = "Yandex Cloud ID"
  type        = string
}

variable "folder_id" {
  description = "Yandex Cloud Folder ID"
  type        = string
}

variable "zone" {
  description = "Primary availability zone"
  type        = string
  default     = "ru-central1-a"
}

variable "secondary_zone" {
  description = "Secondary availability zone for HA"
  type        = string
  default     = "ru-central1-b"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
}

variable "subnet_cidr" {
  description = "Primary subnet CIDR"
  type        = list(string)
  default     = ["10.30.0.0/24"]
}

variable "secondary_subnet_cidr" {
  description = "Secondary subnet CIDR for HA"
  type        = list(string)
  default     = ["10.30.1.0/24"]
}

variable "allowed_ssh_cidrs" {
  description = "CIDR blocks for SSH (bastion/VPN only)"
  type        = list(string)
  default     = ["10.0.0.100/32"]
}

variable "allowed_https_cidrs" {
  description = "CIDR blocks for HTTPS access"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "nat_enabled" {
  description = "Enable NAT"
  type        = bool
  default     = false
}

variable "platform_id" {
  description = "Yandex Cloud platform ID"
  type        = string
  default     = "standard-v3"
}

variable "image_id" {
  description = "OS image ID"
  type        = string
  default     = "fd8vmcue7aajpmeo39kk"
}

variable "disk_type" {
  description = "Default disk type"
  type        = string
  default     = "network-ssd"
}

variable "ssh_user" {
  description = "SSH username"
  type        = string
  default     = "ubuntu"
}

variable "ssh_public_key" {
  description = "SSH public key"
  type        = string
  sensitive   = true
}

variable "dwh_cores" {
  description = "CPU cores for DWH"
  type        = number
  default     = 8
}

variable "dwh_memory" {
  description = "RAM in GB for DWH"
  type        = number
  default     = 32
}

variable "dwh_core_fraction" {
  description = "CPU core fraction"
  type        = number
  default     = 100
}

variable "dwh_boot_disk_size" {
  description = "Boot disk size in GB"
  type        = number
  default     = 50
}

variable "dwh_data_disk_size" {
  description = "Data disk size in GB"
  type        = number
  default     = 500
}

variable "integration_cores" {
  description = "CPU cores"
  type        = number
  default     = 4
}

variable "integration_memory" {
  description = "RAM in GB"
  type        = number
  default     = 16
}

variable "integration_core_fraction" {
  description = "CPU core fraction"
  type        = number
  default     = 100
}

variable "integration_boot_disk_size" {
  description = "Boot disk size in GB"
  type        = number
  default     = 50
}

variable "integration_data_disk_size" {
  description = "Data disk size in GB"
  type        = number
  default     = 100
}

variable "bi_cores" {
  description = "CPU cores"
  type        = number
  default     = 8
}

variable "bi_memory" {
  description = "RAM in GB"
  type        = number
  default     = 32
}

variable "bi_core_fraction" {
  description = "CPU core fraction"
  type        = number
  default     = 100
}

variable "bi_boot_disk_size" {
  description = "Boot disk size in GB"
  type        = number
  default     = 50
}

variable "bi_data_disk_size" {
  description = "Data disk size in GB"
  type        = number
  default     = 200
}

variable "ai_cores" {
  description = "CPU cores"
  type        = number
  default     = 8
}

variable "ai_memory" {
  description = "RAM in GB"
  type        = number
  default     = 32
}

variable "ai_core_fraction" {
  description = "CPU core fraction"
  type        = number
  default     = 100
}

variable "ai_boot_disk_size" {
  description = "Boot disk size in GB"
  type        = number
  default     = 50
}

variable "ai_data_disk_size" {
  description = "Data disk size in GB for models"
  type        = number
  default     = 200
}

variable "fintech_cores" {
  description = "CPU cores"
  type        = number
  default     = 4
}

variable "fintech_memory" {
  description = "RAM in GB"
  type        = number
  default     = 16
}

variable "fintech_core_fraction" {
  description = "CPU core fraction"
  type        = number
  default     = 100
}

variable "fintech_boot_disk_size" {
  description = "Boot disk size in GB"
  type        = number
  default     = 50
}

variable "fintech_data_disk_size" {
  description = "Data disk size in GB"
  type        = number
  default     = 100
}