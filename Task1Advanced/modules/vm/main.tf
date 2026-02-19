terraform {
  required_version = ">= 1.0.0"
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = ">= 0.140.1"
    }
  }
}

locals {
  vm_name   = "${var.environment}-${var.vm_name}"
  disk_name = "${var.environment}-${var.vm_name}-data"

  labels = merge(var.labels, {
    environment = var.environment
    managed_by  = "terraform"
    project     = "future-2-0"
  })
}

resource "yandex_compute_disk" "boot_disk" {
  name        = "${local.vm_name}-boot"
  description = "Загрузочный диск для ${local.vm_name}"
  zone        = var.zone
  size        = var.boot_disk_size
  type        = var.boot_disk_type
  image_id    = var.image_id
  labels      = local.labels

  lifecycle {
    prevent_destroy = false
  }
}

resource "yandex_compute_disk" "data_disk" {
  count = var.enable_data_disk ? 1 : 0

  name        = local.disk_name
  description = "Диск данных для ${local.vm_name}"
  zone        = var.zone
  size        = var.data_disk_size
  type        = var.data_disk_type
  labels      = local.labels

  lifecycle {
    prevent_destroy = false
  }
}

resource "yandex_compute_instance" "vm" {
  name                      = local.vm_name
  hostname                  = local.vm_name
  description               = var.description
  zone                      = var.zone
  platform_id               = var.platform_id
  allow_stopping_for_update = true
  labels                    = local.labels

  resources {
    cores         = var.cores
    memory        = var.memory
    core_fraction = var.core_fraction
  }

  boot_disk {
    disk_id     = yandex_compute_disk.boot_disk.id
    auto_delete = var.boot_disk_auto_delete
  }

  dynamic "secondary_disk" {
    for_each = var.enable_data_disk ? [1] : []
    content {
      disk_id     = yandex_compute_disk.data_disk[0].id
      auto_delete = var.data_disk_auto_delete
      mode        = "READ_WRITE"
    }
  }

  network_interface {
    subnet_id          = var.subnet_id
    nat                = var.nat_enabled
    ip_address         = var.internal_ip_address
    nat_ip_address     = var.nat_ip_address
    security_group_ids = var.security_group_ids
  }

  metadata = {
    ssh-keys           = "${var.ssh_user}:${var.ssh_public_key}"
    user-data          = var.cloud_init_config
    serial-port-enable = var.serial_port_enabled ? "1" : "0"
  }

  scheduling_policy {
    preemptible = var.preemptible
  }

  dynamic "placement_policy" {
    for_each = var.placement_group_id != "" ? [1] : []
    content {
      placement_group_id = var.placement_group_id
    }
  }

  timeouts {
    create = var.timeout_create
    update = var.timeout_update
    delete = var.timeout_delete
  }

  lifecycle {
    ignore_changes = [
      metadata["user-data"]
    ]
  }
}