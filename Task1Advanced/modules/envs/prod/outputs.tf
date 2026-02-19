output "network_id" {
  description = "VPC Network ID"
  value       = yandex_vpc_network.main.id
}

output "primary_subnet_id" {
  description = "Primary Subnet ID"
  value       = yandex_vpc_subnet.main.id
}

output "secondary_subnet_id" {
  description = "Secondary Subnet ID (for HA)"
  value       = yandex_vpc_subnet.secondary.id
}

output "security_group_id" {
  description = "Security Group ID"
  value       = yandex_vpc_security_group.default.id
}

output "dwh_primary" {
  description = "Primary DWH Server"
  value       = module.dwh_server_primary.instance_info
}

output "dwh_secondary" {
  description = "Secondary DWH Server"
  value       = module.dwh_server_secondary.instance_info
}

output "dwh_cluster_ips" {
  description = "DWH Cluster internal IPs"
  value = [
    module.dwh_server_primary.internal_ip,
    module.dwh_server_secondary.internal_ip
  ]
}

output "integration_server_01" {
  description = "Integration Server 01"
  value       = module.integration_server_01.instance_info
}

output "integration_server_02" {
  description = "Integration Server 02"
  value       = module.integration_server_02.instance_info
}

output "integration_cluster_ips" {
  description = "Integration Cluster internal IPs"
  value = [
    module.integration_server_01.internal_ip,
    module.integration_server_02.internal_ip
  ]
}

output "bi_server" {
  description = "BI Server"
  value       = module.bi_server.instance_info
}

output "ai_server_01" {
  description = "AI Server 01"
  value       = module.ai_server_01.instance_info
}

output "ai_server_02" {
  description = "AI Server 02"
  value       = module.ai_server_02.instance_info
}

output "ai_cluster_ips" {
  description = "AI Cluster internal IPs"
  value = [
    module.ai_server_01.internal_ip,
    module.ai_server_02.internal_ip
  ]
}

output "fintech_server" {
  description = "Fintech Server"
  value       = module.fintech_server.instance_info
}

output "environment_summary" {
  description = "Production infrastructure summary"
  value = {
    environment = var.environment
    zones       = [var.zone, var.secondary_zone]
    total_vms   = 9
    servers = {
      dwh_cluster         = [module.dwh_server_primary.vm_name, module.dwh_server_secondary.vm_name]
      integration_cluster = [module.integration_server_01.vm_name, module.integration_server_02.vm_name]
      bi                  = module.bi_server.vm_name
      ai_cluster          = [module.ai_server_01.vm_name, module.ai_server_02.vm_name]
      fintech             = module.fintech_server.vm_name
    }
  }
}

output "all_internal_ips" {
  description = "All internal IP addresses"
  value = {
    dwh_primary         = module.dwh_server_primary.internal_ip
    dwh_secondary       = module.dwh_server_secondary.internal_ip
    integration_01      = module.integration_server_01.internal_ip
    integration_02      = module.integration_server_02.internal_ip
    bi                  = module.bi_server.internal_ip
    ai_01               = module.ai_server_01.internal_ip
    ai_02               = module.ai_server_02.internal_ip
    fintech             = module.fintech_server.internal_ip
  }
}