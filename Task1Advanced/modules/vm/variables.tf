variable "vm_name" {
  description = "Базовое имя для виртуальной машины (будет начинаться с префикса environment)"
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{0,61}[a-z0-9]$", var.vm_name))
    error_message = "Имя виртуальной машины должно быть написано строчными буквами, начинаться с буквы и содержать только буквы, цифры и дефисы."
  }
}

variable "environment" {
  description = "Название среды (dev, stage, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "stage", "prod"], var.environment)
    error_message = "Рабочая среда должна быть одной из следующих: dev, stage, prod."
  }
}

variable "subnet_id" {
  description = "ID подсети Yandex для сетевого интерфейса VM"
  type        = string
}

variable "ssh_public_key" {
  description = "Публичный ключ SSH для доступа к VM"
  type        = string
  sensitive   = true
}

variable "cores" {
  description = "Количество ядер CPU"
  type        = number
  default     = 2

  validation {
    condition     = var.cores >= 2 && var.cores <= 96
    error_message = "Количество ядер CPU должно быть от 2 до 96."
  }
}

variable "memory" {
  description = "Размер RAM в GB"
  type        = number
  default     = 4

  validation {
    condition     = var.memory >= 1 && var.memory <= 640
    error_message = "Объем оперативной памяти должен составлять от 1 до 640 ГБ."
  }
}

variable "core_fraction" {
  description = "Доля ядер ЦП (5, 20, 50, 100)"
  type        = number
  default     = 100

  validation {
    condition     = contains([5, 20, 50, 100], var.core_fraction)
    error_message = "Доля ядра должна быть одной из следующих: 5, 20, 50, 100."
  }
}

variable "platform_id" {
  description = "ID платформы Yandex Cloud (standard-v1, standard-v2, standard-v3)"
  type        = string
  default     = "standard-v3"

  validation {
    condition     = contains(["standard-v1", "standard-v2", "standard-v3", "highfreq-v3"], var.platform_id)
    error_message = "Platform ID должен быть действительным для платвормы Yandex Cloud."
  }
}

variable "image_id" {
  description = "ID образа Yandex Cloud для загрузочного диска"
  type        = string
  default     = "fd8vmcue7aajpmeo39kk" # Ubuntu 22.04 LTS
}

variable "boot_disk_size" {
  description = "Размер загрузочного диска в GB"
  type        = number
  default     = 20

  validation {
    condition     = var.boot_disk_size >= 10 && var.boot_disk_size <= 8192
    error_message = "Размер загрузочного диска должен быть между 10 и 8192 GB."
  }
}

variable "boot_disk_type" {
  description = "Тип загрузочного диска (network-ssd, network-hdd, network-ssd-nonreplicated)"
  type        = string
  default     = "network-ssd"

  validation {
    condition     = contains(["network-ssd", "network-hdd", "network-ssd-nonreplicated"], var.boot_disk_type)
    error_message = "Тип загрузочного диска должен быть: network-ssd, network-hdd, or network-ssd-nonreplicated."
  }
}

variable "boot_disk_auto_delete" {
  description = "Автоматическое удаление загрузочного диска при уничтожении виртуальной машины"
  type        = bool
  default     = true
}

variable "enable_data_disk" {
  description = "Включение дополнительного диска данных"
  type        = bool
  default     = true
}

variable "data_disk_size" {
  description = "Размер диска данных в GB"
  type        = number
  default     = 50

  validation {
    condition     = var.data_disk_size >= 4 && var.data_disk_size <= 8192
    error_message = "Размер диска данных должен быть между 4 и 8192 GB."
  }
}

variable "data_disk_type" {
  description = "Тип диска данных (network-ssd, network-hdd, network-ssd-nonreplicated)"
  type        = string
  default     = "network-ssd"

  validation {
    condition     = contains(["network-ssd", "network-hdd", "network-ssd-nonreplicated"], var.data_disk_type)
    error_message = "Тип диска данных должен быть: network-ssd, network-hdd, or network-ssd-nonreplicated."
  }
}

variable "data_disk_auto_delete" {
  description = "Автоматическое удаление диска данных после уничтожения VM"
  type        = bool
  default     = false
}

# -----------------------------------------------------------------------------
# Network Configuration
# -----------------------------------------------------------------------------

variable "zone" {
  description = "Зона доступности Yandex Cloud"
  type        = string
  default     = "ru-central1-a"

  validation {
    condition     = can(regex("^ru-central1-[a-d]$", var.zone))
    error_message = "Зона долна быть действительной зоной Yandex Cloud (ru-central1-a/b/c/d)."
  }
}

variable "nat_enabled" {
  description = "Включение NAT для публичного IP адреса"
  type        = bool
  default     = false
}

variable "internal_ip_address" {
  description = "Внутренний IP адрес (опциональный, автоматически назначенный если пустой)"
  type        = string
  default     = null
}

variable "nat_ip_address" {
  description = "Статический NAT IP адрес (опциональный)"
  type        = string
  default     = null
}

variable "security_group_ids" {
  description = "Список идентификаторов групп безопасности"
  type        = list(string)
  default     = []
}

variable "ssh_user" {
  description = "SSH user name"
  type        = string
  default     = "ubuntu"
}

# -----------------------------------------------------------------------------
# Instance Metadata
# -----------------------------------------------------------------------------

variable "description" {
  description = "Описани экземпляра VM"
  type        = string
  default     = "VM создана модулем Future 2.0 Terraform"
}

variable "labels" {
  description = "Дополнительные метки для ресурсов"
  type        = map(string)
  default     = {}
}

variable "cloud_init_config" {
  description = "Конфигурация Cloud-init (пользовательские данные)"
  type        = string
  default     = ""
}

variable "serial_port_enabled" {
  description = "Включение последовательного порта для отладки"
  type        = bool
  default     = false
}

variable "preemptible" {
  description = "Использовать вытесняемый (точечный) экземпляр"
  type        = bool
  default     = false
}

variable "placement_group_id" {
  description = "Идентификатор группы размещения для антиаффинности"
  type        = string
  default     = ""
}

variable "timeout_create" {
  description = "Таймаут для создания VM"
  type        = string
  default     = "10m"
}

variable "timeout_update" {
  description = "Таймаут для обновления VM"
  type        = string
  default     = "10m"
}

variable "timeout_delete" {
  description = "Таймаут для удаления VM"
  type        = string
  default     = "10m"
}