output "api_gateway_url" {
  description = "URL API Gateway"
  value       = "http://localhost:${docker_container.api_gateway.ports[0].external}"
}

output "grafana_url" {
  description = "URL Grafana Dashboard"
  value       = "http://localhost:${docker_container.grafana.ports[0].external}"
}

output "prometheus_url" {
  description = "URL Prometheus"
  value       = "http://localhost:${docker_container.prometheus.ports[0].external}"
}

output "postgres_primary_name" {
  description = "Имя контейнера PostgreSQL Primary"
  value       = docker_container.postgres_primary.name
}

output "kafka_broker" {
  description = "Адрес Kafka-брокера (внутренний)"
  value       = "${docker_container.kafka.name}:9092"
}

output "redis_host" {
  description = "Адрес Redis (внутренний)"
  value       = docker_container.redis.name
}

output "environment" {
  description = "Текущее окружение"
  value       = var.environment
}

output "state_backend" {
  description = "Информация о backend хранения состояния"
  value       = "s3://terraform-state/future-2-0/terraform.tfstate"
}