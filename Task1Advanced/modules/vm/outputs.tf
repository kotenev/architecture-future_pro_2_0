output "vm_id" {
  description = "ID созданных экземпляров VM"
  value       = yandex_compute_instance.vm.id
}

output "vm_name" {
  description = "Имя созданных экземпляров VM"
  value       = yandex_compute_instance.vm.name
}

output "vm_fqdn" {
  description = "FQDN созданных экземпляров VM"
  value       = yandex_compute_instance.vm.fqdn
}

output "vm_status" {
  description = "Статус экземпляра VM"
  value       = yandex_compute_instance.vm.status
}

output "internal_ip" {
  description = "Внутренний IP-адрес VM"
  value       = yandex_compute_instance.vm.network_interface[0].ip_address
}

output "external_ip" {
  description = "Внешний (NAT) IP-адрес VM (если включено)"
  value       = var.nat_enabled ? yandex_compute_instance.vm.network_interface[0].nat_ip_address : null
}

output "mac_address" {
  description = "MAC-адрес сетевого интерфейса VM"
  value       = yandex_compute_instance.vm.network_interface[0].mac_address
}

output "subnet_id" {
  description = "ID подсети в которой развёрнута VM"
  value       = yandex_compute_instance.vm.network_interface[0].subnet_id
}

output "boot_disk_id" {
  description = "ID загрузочного диска"
  value       = yandex_compute_disk.boot_disk.id
}

output "boot_disk_name" {
  description = "Имя загрузочного диска"
  value       = yandex_compute_disk.boot_disk.name
}

output "data_disk_id" {
  description = "ID диска данных (если включено)"
  value       = var.enable_data_disk ? yandex_compute_disk.data_disk[0].id : null
}

output "data_disk_name" {
  description = "Имя диска данных (если включено)"
  value       = var.enable_data_disk ? yandex_compute_disk.data_disk[0].name : null
}

output "resources" {
  description = "Конфигурация ресурса VM"
  value = {
    cores         = yandex_compute_instance.vm.resources[0].cores
    memory        = yandex_compute_instance.vm.resources[0].memory
    core_fraction = yandex_compute_instance.vm.resources[0].core_fraction
  }
}

output "zone" {
  description = "Зона доступности VM"
  value       = yandex_compute_instance.vm.zone
}

output "labels" {
  description = "Метки назначенные VM"
  value       = yandex_compute_instance.vm.labels
}

output "ssh_connection" {
  description = "Строка SSH-подключения"
  value       = var.nat_enabled ? "${var.ssh_user}@${yandex_compute_instance.vm.network_interface[0].nat_ip_address}" : "${var.ssh_user}@${yandex_compute_instance.vm.network_interface[0].ip_address}"
}

output "instance_info" {
  description = "Полная информация об экземпляре для интеграции"
  value = {
    id           = yandex_compute_instance.vm.id
    name         = yandex_compute_instance.vm.name
    fqdn         = yandex_compute_instance.vm.fqdn
    internal_ip  = yandex_compute_instance.vm.network_interface[0].ip_address
    external_ip  = var.nat_enabled ? yandex_compute_instance.vm.network_interface[0].nat_ip_address : null
    zone         = yandex_compute_instance.vm.zone
    environment  = var.environment
    boot_disk_id = yandex_compute_disk.boot_disk.id
    data_disk_id = var.enable_data_disk ? yandex_compute_disk.data_disk[0].id : null
  }
}