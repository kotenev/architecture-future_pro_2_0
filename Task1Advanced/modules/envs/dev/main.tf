terraform {
  required_version = ">= 1.0.0"

  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = ">= 0.140.1"
    }
  }

provider "yandex" {
  cloud_id  = var.cloud_id
  folder_id = var.folder_id
  zone      = var.zone
}

resource "yandex_vpc_network" "main" {
  name        = "${var.environment}-future-2-0-network"
  description = "Main network for Future 2.0 ${var.environment} environment"

  labels = {
    environment = var.environment
    project     = "future-2-0"
    managed_by  = "terraform"
  }
}

resource "yandex_vpc_subnet" "main" {
  name           = "${var.environment}-future-2-0-subnet"
  description    = "Main subnet for Future 2.0 ${var.environment} environment"
  zone           = var.zone
  network_id     = yandex_vpc_network.main.id
  v4_cidr_blocks = var.subnet_cidr

  labels = {
    environment = var.environment
    project     = "future-2-0"
    managed_by  = "terraform"
  }
}

resource "yandex_vpc_security_group" "default" {
  name        = "${var.environment}-future-2-0-sg"
  description = "Default security group for Future 2.0 ${var.environment}"
  network_id  = yandex_vpc_network.main.id

  labels = {
    environment = var.environment
    project     = "future-2-0"
  }

  ingress {
    protocol       = "TCP"
    port           = 22
    v4_cidr_blocks = var.allowed_ssh_cidrs
    description    = "SSH доступ"
  }

  ingress {
    protocol       = "ANY"
    from_port      = 0
    to_port        = 65535
    v4_cidr_blocks = var.subnet_cidr
    description    = "Internal network communication"
  }

  # Outbound traffic
  egress {
    protocol       = "ANY"
    from_port      = 0
    to_port        = 65535
    v4_cidr_blocks = ["0.0.0.0/0"]
    description    = "Allow all outbound traffic"
  }
}

module "dwh_server" {
  source = "../../vm"

  vm_name     = "dwh-server"
  environment = var.environment
  description = "Сервер хранилища данных для медицинских и финансовых данных Future 2.0"

  cores         = var.dwh_cores
  memory        = var.dwh_memory
  core_fraction = var.dwh_core_fraction
  platform_id   = var.platform_id

  image_id       = var.image_id
  boot_disk_size = var.dwh_boot_disk_size
  boot_disk_type = var.disk_type

  enable_data_disk = true
  data_disk_size   = var.dwh_data_disk_size
  data_disk_type   = var.disk_type

  zone               = var.zone
  subnet_id          = yandex_vpc_subnet.main.id
  nat_enabled        = var.nat_enabled
  security_group_ids = [yandex_vpc_security_group.default.id]

  ssh_user       = var.ssh_user
  ssh_public_key = var.ssh_public_key

  preemptible         = var.use_preemptible
  serial_port_enabled = true

  labels = {
    component = "dwh"
    tier      = "data"
  }
}

module "integration_server" {
  source = "../../vm"

  vm_name     = "integration-bus"
  environment = var.environment
  description = "Сервер интеграционной шины для событийно-ориентированной архитектуры Future 2.0"

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

  preemptible         = var.use_preemptible
  serial_port_enabled = true

  labels = {
    component = "integration"
    tier      = "middleware"
  }
}

module "bi_server" {
  source = "../../vm"

  vm_name     = "bi-server"
  environment = var.environment
  description = "Сервер бизнес-аналитики для аналитики Future 2.0"

  cores         = var.bi_cores
  memory        = var.bi_memory
  core_fraction = var.bi_core_fraction
  platform_id   = var.platform_id

  image_id       = var.image_id
  boot_disk_size = var.bi_boot_disk_size
  boot_disk_type = var.disk_type

  enable_data_disk = false

  zone               = var.zone
  subnet_id          = yandex_vpc_subnet.main.id
  nat_enabled        = var.nat_enabled
  security_group_ids = [yandex_vpc_security_group.default.id]

  ssh_user       = var.ssh_user
  ssh_public_key = var.ssh_public_key

  preemptible         = var.use_preemptible
  serial_port_enabled = true

  labels = {
    component = "bi"
    tier      = "analytics"
  }
}