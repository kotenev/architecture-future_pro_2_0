resource "docker_image" "postgres" {
  name         = "postgres:${var.postgres_version}"
  keep_locally = true
}

resource "docker_volume" "pg_primary_data" {
  name = "${local.name_prefix}-pg-primary-data"
  labels {
    label = "managed_by"
    value = var.common_labels["managed_by"]
  }
}

resource "docker_container" "postgres_primary" {
  name    = "${local.name_prefix}-pg-primary"
  image   = docker_image.postgres.image_id
  restart = "unless-stopped"

  env = [
    "POSTGRES_DB=${var.postgres_db}",
    "POSTGRES_USER=${var.postgres_user}",
    "POSTGRES_PASSWORD=${var.postgres_password}",
    "PGDATA=/var/lib/postgresql/data/pgdata",
  ]

  volumes {
    volume_name    = docker_volume.pg_primary_data.name
    container_path = "/var/lib/postgresql/data"
  }

  networks_advanced {
    name = docker_network.data.id
  }
  networks_advanced {
    name = docker_network.monitoring.id
  }

  labels {
    label = "managed_by"
    value = var.common_labels["managed_by"]
  }
  labels {
    label = "component"
    value = "postgres-primary"
  }

  healthcheck {
    test         = ["CMD-SHELL", "pg_isready -U ${var.postgres_user} -d ${var.postgres_db}"]
    interval     = "15s"
    timeout      = "5s"
    retries      = 5
    start_period = "30s"
  }
}

resource "docker_volume" "pg_replica_data" {
  name = "${local.name_prefix}-pg-replica-data"
  labels {
    label = "managed_by"
    value = var.common_labels["managed_by"]
  }
}

resource "docker_container" "postgres_replica" {
  name    = "${local.name_prefix}-pg-replica"
  image   = docker_image.postgres.image_id
  restart = "unless-stopped"

  env = [
    "POSTGRES_DB=${var.postgres_db}",
    "POSTGRES_USER=${var.postgres_user}",
    "POSTGRES_PASSWORD=${var.postgres_password}",
    "PGDATA=/var/lib/postgresql/data/pgdata",
  ]

  volumes {
    volume_name    = docker_volume.pg_replica_data.name
    container_path = "/var/lib/postgresql/data"
  }

  networks_advanced {
    name = docker_network.data.id
  }

  labels {
    label = "managed_by"
    value = var.common_labels["managed_by"]
  }
  labels {
    label = "component"
    value = "postgres-replica"
  }

  depends_on = [docker_container.postgres_primary]
}

resource "docker_image" "redis" {
  name         = "redis:${var.redis_version}"
  keep_locally = true
}

resource "docker_volume" "redis_data" {
  name = "${local.name_prefix}-redis-data"
  labels {
    label = "managed_by"
    value = var.common_labels["managed_by"]
  }
}

resource "docker_container" "redis" {
  name    = "${local.name_prefix}-redis"
  image   = docker_image.redis.image_id
  restart = "unless-stopped"
  command = ["redis-server", "--requirepass", var.redis_password, "--appendonly", "yes"]

  volumes {
    volume_name    = docker_volume.redis_data.name
    container_path = "/data"
  }

  networks_advanced {
    name = docker_network.data.id
  }
  networks_advanced {
    name = docker_network.monitoring.id
  }

  labels {
    label = "managed_by"
    value = var.common_labels["managed_by"]
  }
  labels {
    label = "component"
    value = "redis"
  }

  healthcheck {
    test         = ["CMD", "redis-cli", "-a", var.redis_password, "ping"]
    interval     = "15s"
    timeout      = "5s"
    retries      = 3
    start_period = "10s"
  }
}

# --- Kafka (Bitnami) ---

resource "docker_image" "kafka" {
  name         = "bitnami/kafka:${var.kafka_version}"
  keep_locally = true
}

resource "docker_volume" "kafka_data" {
  name = "${local.name_prefix}-kafka-data"
  labels {
    label = "managed_by"
    value = var.common_labels["managed_by"]
  }
}

resource "docker_container" "kafka" {
  name    = "${local.name_prefix}-kafka"
  image   = docker_image.kafka.image_id
  restart = "unless-stopped"

  env = [
    "KAFKA_CFG_NODE_ID=1",
    "KAFKA_CFG_PROCESS_ROLES=broker,controller",
    "KAFKA_CFG_CONTROLLER_QUORUM_VOTERS=1@localhost:9093",
    "KAFKA_CFG_LISTENERS=PLAINTEXT://:9092,CONTROLLER://:9093",
    "KAFKA_CFG_ADVERTISED_LISTENERS=PLAINTEXT://${local.name_prefix}-kafka:9092",
    "KAFKA_CFG_LISTENER_SECURITY_PROTOCOL_MAP=CONTROLLER:PLAINTEXT,PLAINTEXT:PLAINTEXT",
    "KAFKA_CFG_CONTROLLER_LISTENER_NAMES=CONTROLLER",
    "KAFKA_CFG_LOG_RETENTION_HOURS=168",
    "ALLOW_PLAINTEXT_LISTENER=yes",
  ]

  volumes {
    volume_name    = docker_volume.kafka_data.name
    container_path = "/bitnami/kafka"
  }

  networks_advanced {
    name = docker_network.data.id
  }
  networks_advanced {
    name = docker_network.monitoring.id
  }

  labels {
    label = "managed_by"
    value = var.common_labels["managed_by"]
  }
  labels {
    label = "component"
    value = "kafka"
  }

  healthcheck {
    test         = ["CMD-SHELL", "kafka-broker-api-versions.sh --bootstrap-server localhost:9092"]
    interval     = "30s"
    timeout      = "10s"
    retries      = 5
    start_period = "60s"
  }
}