output "network_id" {
  description = "VPC Network ID"
  value       = yandex_vpc_network.main.id
}

output "subnet_id" {
  description = "Subnet ID"
  value       = yandex_vpc_subnet.main.id
}

output "security_group_id" {
  description = "Security Group ID"
  value       = yandex_vpc_security_group.default.id
}

# -----------------------------------------------------------------------------
# DWH Server Outputs
# -----------------------------------------------------------------------------

output "dwh_server" {
  description = "DWH Server information"
  value       = module.dwh_server.instance_info
}

output "dwh_ssh_connection" {
  description = "SSH connection string for DWH server"
  value       = module.dwh_server.ssh_connection
}

output "integration_server" {
  description = "Integration Server information"
  value       = module.integration_server.instance_info
}

output "integration_ssh_connection" {
  description = "SSH connection string for Integration server"
  value       = module.integration_server.ssh_connection
}

output "bi_server" {
  description = "BI Server information"
  value       = module.bi_server.instance_info
}

output "bi_ssh_connection" {
  description = "SSH connection string for BI server"
  value       = module.bi_server.ssh_connection
}

output "environment_summary" {
  description = "Summary of deployed infrastructure"
  value = {
    environment = var.environment
    zone        = var.zone
    servers = {
      dwh         = module.dwh_server.vm_name
      integration = module.integration_server.vm_name
      bi          = module.bi_server.vm_name
    }
  }
}