variable "cloud_id" {
  description = "Yandex Cloud ID"
  type        = string
}

variable "folder_id" {
  description = "Yandex Cloud Folder ID"
  type        = string
}

variable "zone" {
  description = "Yandex Cloud availability zone"
  type        = string
  default     = "ru-central1-b"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "stage"
}

variable "subnet_cidr" {
  description = "CIDR block for subnet"
  type        = list(string)
  default     = ["10.20.0.0/24"]
}

variable "allowed_ssh_cidrs" {
  description = "CIDR blocks allowed for SSH access"
  type        = list(string)
  default     = ["10.0.0.0/8"]
}

variable "nat_enabled" {
  description = "Enable NAT for public IP access"
  type        = bool
  default     = true
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

variable "use_preemptible" {
  description = "Use preemptible instances"
  type        = bool
  default     = false
}

variable "ssh_user" {
  description = "SSH username"
  type        = string
  default     = "ubuntu"
}

variable "ssh_public_key" {
  description = "SSH public key for VM access"
  type        = string
  sensitive   = true
}

variable "dwh_cores" {
  description = "Number of CPU cores for DWH server"
  type        = number
  default     = 4
}

variable "dwh_memory" {
  description = "RAM size in GB for DWH server"
  type        = number
  default     = 8
}

variable "dwh_core_fraction" {
  description = "CPU core fraction for DWH server"
  type        = number
  default     = 50
}

variable "dwh_boot_disk_size" {
  description = "Boot disk size in GB"
  type        = number
  default     = 30
}

variable "dwh_data_disk_size" {
  description = "Data disk size in GB"
  type        = number
  default     = 100
}

variable "integration_cores" {
  description = "Number of CPU cores for Integration server"
  type        = number
  default     = 4
}

variable "integration_memory" {
  description = "RAM size in GB for Integration server"
  type        = number
  default     = 8
}

variable "integration_core_fraction" {
  description = "CPU core fraction for Integration server"
  type        = number
  default     = 50
}

variable "integration_boot_disk_size" {
  description = "Boot disk size in GB"
  type        = number
  default     = 30
}

variable "integration_data_disk_size" {
  description = "Data disk size in GB"
  type        = number
  default     = 50
}

variable "bi_cores" {
  description = "Number of CPU cores for BI server"
  type        = number
  default     = 4
}

variable "bi_memory" {
  description = "RAM size in GB for BI server"
  type        = number
  default     = 8
}

variable "bi_core_fraction" {
  description = "CPU core fraction for BI server"
  type        = number
  default     = 50
}

variable "bi_boot_disk_size" {
  description = "Boot disk size in GB"
  type        = number
  default     = 30
}

variable "bi_data_disk_size" {
  description = "Data disk size in GB for BI cache"
  type        = number
  default     = 50
}

variable "ai_cores" {
  description = "Number of CPU cores for AI server"
  type        = number
  default     = 4
}

variable "ai_memory" {
  description = "RAM size in GB for AI server"
  type        = number
  default     = 16
}

variable "ai_core_fraction" {
  description = "CPU core fraction for AI server"
  type        = number
  default     = 50
}

variable "ai_boot_disk_size" {
  description = "Boot disk size in GB"
  type        = number
  default     = 30
}

variable "ai_data_disk_size" {
  description = "Data disk size in GB for AI models"
  type        = number
  default     = 100
}