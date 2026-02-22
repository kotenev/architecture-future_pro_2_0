terraform {
  required_version = ">= 1.0.0"

  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = ">= 0.140.1"
    }
  }

  # Backend configuration for remote state storage (REQUIRED for production)
  # backend "s3" {
  #   endpoints = {
  #     s3 = "https://storage.yandexcloud.net"
  #   }
  #   bucket                      = "future-2-0-terraform-state"
  #   key                         = "prod/terraform.tfstate"
  #   region                      = "ru-central1"
  #   skip_region_validation      = true
  #   skip_credentials_validation = true
  #   skip_requesting_account_id  = true
  #   skip_s3_checksum            = true
  #   dynamodb_table              = "terraform-locks"
  # }
}

provider "yandex" {
  cloud_id  = var.cloud_id
  folder_id = var.folder_id
  zone      = var.zone
}

resource "yandex_vpc_network" "main" {
  name        = "${var.environment}-future-2-0-network"
  description = "Production network for Future 2.0"

  labels = {
    environment = var.environment
    project     = "future-2-0"
    managed_by  = "terraform"
    criticality = "high"
  }
}

resource "yandex_vpc_subnet" "main" {
  name           = "${var.environment}-future-2-0-subnet"
  description    = "Production subnet for Future 2.0"
  zone           = var.zone
  network_id     = yandex_vpc_network.main.id
  v4_cidr_blocks = var.subnet_cidr

  labels = {
    environment = var.environment
    project     = "future-2-0"
    managed_by  = "terraform"
  }
}

# Secondary subnet for HA
resource "yandex_vpc_subnet" "secondary" {
  name           = "${var.environment}-future-2-0-subnet-b"
  description    = "Secondary subnet for HA"
  zone           = var.secondary_zone
  network_id     = yandex_vpc_network.main.id
  v4_cidr_blocks = var.secondary_subnet_cidr

  labels = {
    environment = var.environment
    project     = "future-2-0"
    managed_by  = "terraform"
  }
}

resource "yandex_vpc_security_group" "default" {
  name        = "${var.environment}-future-2-0-sg"
  description = "Production security group for Future 2.0"
  network_id  = yandex_vpc_network.main.id

  labels = {
    environment = var.environment
    project     = "future-2-0"
  }

  ingress {
    protocol       = "TCP"
    port           = 22
    v4_cidr_blocks = var.allowed_ssh_cidrs
    description    = "SSH from bastion/VPN only"
  }

  ingress {
    protocol       = "TCP"
    port           = 443
    v4_cidr_blocks = var.allowed_https_cidrs
    description    = "HTTPS access"
  }

  ingress {
    protocol       = "ANY"
    from_port      = 0
    to_port        = 65535
    v4_cidr_blocks = concat(var.subnet_cidr, var.secondary_subnet_cidr)
    description    = "Internal network communication"
  }

  egress {
    protocol       = "ANY"
    from_port      = 0
    to_port        = 65535
    v4_cidr_blocks = ["0.0.0.0/0"]
    description    = "Allow all outbound"
  }
}

module "dwh_server_primary" {
  source = "../../vm"

  vm_name     = "dwh-server-01"
  environment = var.environment
  description = "Primary DWH server for Future 2.0 production"

  cores         = var.dwh_cores
  memory        = var.dwh_memory
  core_fraction = var.dwh_core_fraction
  platform_id   = var.platform_id

  image_id       = var.image_id
  boot_disk_size = var.dwh_boot_disk_size
  boot_disk_type = var.disk_type

  enable_data_disk      = true
  data_disk_size        = var.dwh_data_disk_size
  data_disk_type        = var.disk_type
  data_disk_auto_delete = false

  zone               = var.zone
  subnet_id          = yandex_vpc_subnet.main.id
  nat_enabled        = var.nat_enabled
  security_group_ids = [yandex_vpc_security_group.default.id]

  ssh_user       = var.ssh_user
  ssh_public_key = var.ssh_public_key

  preemptible         = false
  serial_port_enabled = false

  labels = {
    component = "dwh"
    tier      = "data"
    role      = "primary"
  }
}

module "dwh_server_secondary" {
  source = "../../vm"

  vm_name     = "dwh-server-02"
  environment = var.environment
  description = "Secondary DWH server for Future 2.0 production"

  cores         = var.dwh_cores
  memory        = var.dwh_memory
  core_fraction = var.dwh_core_fraction
  platform_id   = var.platform_id

  image_id       = var.image_id
  boot_disk_size = var.dwh_boot_disk_size
  boot_disk_type = var.disk_type

  enable_data_disk      = true
  data_disk_size        = var.dwh_data_disk_size
  data_disk_type        = var.disk_type
  data_disk_auto_delete = false

  zone               = var.secondary_zone
  subnet_id          = yandex_vpc_subnet.secondary.id
  nat_enabled        = var.nat_enabled
  security_group_ids = [yandex_vpc_security_group.default.id]

  ssh_user       = var.ssh_user
  ssh_public_key = var.ssh_public_key

  preemptible         = false
  serial_port_enabled = false

  labels = {
    component = "dwh"
    tier      = "data"
    role      = "secondary"
  }
}

module "integration_server_01" {
  source = "../../vm"

  vm_name     = "integration-bus-01"
  environment = var.environment
  description = "Integration bus server 01 for Future 2.0"

  cores         = var.integration_cores
  memory        = var.integration_memory
  core_fraction = var.integration_core_fraction
  platform_id   = var.platform_id

  image_id       = var.image_id
  boot_disk_size = var.integration_boot_disk_size
  boot_disk_type = var.disk_type

  enable_data_disk = true
  data_disk_size   = var.integration_data_disk_size
  data_disk_type   = var.disk_type

  zone               = var.zone
  subnet_id          = yandex_vpc_subnet.main.id
  nat_enabled        = var.nat_enabled
  security_group_ids = [yandex_vpc_security_group.default.id]

  ssh_user       = var.ssh_user
  ssh_public_key = var.ssh_public_key

  preemptible         = false
  serial_port_enabled = false

  labels = {
    component = "integration"
    tier      = "middleware"
    instance  = "01"
  }
}

module "integration_server_02" {
  source = "../../vm"

  vm_name     = "integration-bus-02"
  environment = var.environment
  description = "Integration bus server 02 for Future 2.0"

  cores         = var.integration_cores
  memory        = var.integration_memory
  core_fraction = var.integration_core_fraction
  platform_id   = var.platform_id

  image_id       = var.image_id
  boot_disk_size = var.integration_boot_disk_size
  boot_disk_type = var.disk_type

  enable_data_disk = true
  data_disk_size   = var.integration_data_disk_size
  data_disk_type   = var.disk_type

  zone               = var.secondary_zone
  subnet_id          = yandex_vpc_subnet.secondary.id
  nat_enabled        = var.nat_enabled
  security_group_ids = [yandex_vpc_security_group.default.id]

  ssh_user       = var.ssh_user
  ssh_public_key = var.ssh_public_key

  preemptible         = false
  serial_port_enabled = false

  labels = {
    component = "integration"
    tier      = "middleware"
    instance  = "02"
  }
}

module "bi_server" {
  source = "../../vm"

  vm_name     = "bi-server"
  environment = var.environment
  description = "Business Intelligence server for Future 2.0"

  cores         = var.bi_cores
  memory        = var.bi_memory
  core_fraction = var.bi_core_fraction
  platform_id   = var.platform_id

  image_id       = var.image_id
  boot_disk_size = var.bi_boot_disk_size
  boot_disk_type = var.disk_type

  enable_data_disk = true
  data_disk_size   = var.bi_data_disk_size
  data_disk_type   = var.disk_type

  zone               = var.zone
  subnet_id          = yandex_vpc_subnet.main.id
  nat_enabled        = var.nat_enabled
  security_group_ids = [yandex_vpc_security_group.default.id]

  ssh_user       = var.ssh_user
  ssh_public_key = var.ssh_public_key

  preemptible         = false
  serial_port_enabled = false

  labels = {
    component = "bi"
    tier      = "analytics"
  }
}

module "ai_server_01" {
  source = "../../vm"

  vm_name     = "ai-services-01"
  environment = var.environment
  description = "AI Services server 01 for medical data processing"

  cores         = var.ai_cores
  memory        = var.ai_memory
  core_fraction = var.ai_core_fraction
  platform_id   = var.platform_id

  image_id       = var.image_id
  boot_disk_size = var.ai_boot_disk_size
  boot_disk_type = var.disk_type

  enable_data_disk = true
  data_disk_size   = var.ai_data_disk_size
  data_disk_type   = var.disk_type

  zone               = var.zone
  subnet_id          = yandex_vpc_subnet.main.id
  nat_enabled        = var.nat_enabled
  security_group_ids = [yandex_vpc_security_group.default.id]

  ssh_user       = var.ssh_user
  ssh_public_key = var.ssh_public_key

  preemptible         = false
  serial_port_enabled = false

  labels = {
    component = "ai"
    tier      = "compute"
    instance  = "01"
  }
}

module "ai_server_02" {
  source = "../../vm"

  vm_name     = "ai-services-02"
  environment = var.environment
  description = "AI Services server 02 for medical data processing"

  cores         = var.ai_cores
  memory        = var.ai_memory
  core_fraction = var.ai_core_fraction
  platform_id   = var.platform_id

  image_id       = var.image_id
  boot_disk_size = var.ai_boot_disk_size
  boot_disk_type = var.disk_type

  enable_data_disk = true
  data_disk_size   = var.ai_data_disk_size
  data_disk_type   = var.disk_type

  zone               = var.secondary_zone
  subnet_id          = yandex_vpc_subnet.secondary.id
  nat_enabled        = var.nat_enabled
  security_group_ids = [yandex_vpc_security_group.default.id]

  ssh_user       = var.ssh_user
  ssh_public_key = var.ssh_public_key

  preemptible         = false
  serial_port_enabled = false

  labels = {
    component = "ai"
    tier      = "compute"
    instance  = "02"
  }
}

module "fintech_server" {
  source = "../../vm"

  vm_name     = "fintech-services"
  environment = var.environment
  description = "Fintech services server for banking operations"

  cores         = var.fintech_cores
  memory        = var.fintech_memory
  core_fraction = var.fintech_core_fraction
  platform_id   = var.platform_id

  image_id       = var.image_id
  boot_disk_size = var.fintech_boot_disk_size
  boot_disk_type = var.disk_type

  enable_data_disk = true
  data_disk_size   = var.fintech_data_disk_size
  data_disk_type   = var.disk_type

  zone               = var.zone
  subnet_id          = yandex_vpc_subnet.main.id
  nat_enabled        = var.nat_enabled
  security_group_ids = [yandex_vpc_security_group.default.id]

  ssh_user       = var.ssh_user
  ssh_public_key = var.ssh_public_key

  preemptible         = false
  serial_port_enabled = false

  labels = {
    component   = "fintech"
    tier        = "application"
    compliance  = "pci-dss"
  }
}