locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

resource "docker_image" "api_gateway" {
  name         = "nginx:1.25-alpine"
  keep_locally = true
}

resource "docker_container" "api_gateway" {
  name  = "${local.name_prefix}-api-gateway"
  image = docker_image.api_gateway.image_id

  restart = "unless-stopped"

  ports {
    internal = 80
    external = 8080
  }

  networks_advanced {
    name = docker_network.frontend.id
  }

  networks_advanced {
    name = docker_network.backend.id
  }

  labels {
    label = "managed_by"
    value = var.common_labels["managed_by"]
  }

  labels {
    label = "project"
    value = var.common_labels["project"]
  }

  labels {
    label = "component"
    value = "api-gateway"
  }

  labels {
    label = "environment"
    value = var.environment
  }

  healthcheck {
    test         = ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost/"]
    interval     = "30s"
    timeout      = "5s"
    retries      = 3
    start_period = "10s"
  }
}

resource "docker_image" "app_backend" {
  name         = "python:3.12-slim"
  keep_locally = true
}

resource "docker_container" "app_backend" {
  name  = "${local.name_prefix}-app-backend"
  image = docker_image.app_backend.image_id

  restart = "unless-stopped"
  command = ["python", "-m", "http.server", "8000"]

  env = [
    "APP_ENV=${var.environment}",
    "DATABASE_HOST=${docker_container.postgres_primary.name}",
    "DATABASE_PORT=5432",
    "DATABASE_NAME=${var.postgres_db}",
    "DATABASE_USER=${var.postgres_user}",
    "REDIS_HOST=${docker_container.redis.name}",
    "REDIS_PORT=6379",
    "KAFKA_BROKERS=${docker_container.kafka.name}:9092",
  ]

  networks_advanced {
    name = docker_network.backend.id
  }

  networks_advanced {
    name = docker_network.data.id
  }

  labels {
    label = "managed_by"
    value = var.common_labels["managed_by"]
  }

  labels {
    label = "project"
    value = var.common_labels["project"]
  }

  labels {
    label = "component"
    value = "app-backend"
  }

  depends_on = [
    docker_container.postgres_primary,
    docker_container.redis,
    docker_container.kafka,
  ]
}