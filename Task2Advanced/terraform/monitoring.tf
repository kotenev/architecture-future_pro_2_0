resource "docker_image" "prometheus" {
  name         = "prom/prometheus:v3.5.1"
  keep_locally = true
}

resource "docker_volume" "prometheus_data" {
  name = "${local.name_prefix}-prometheus-data"
  labels {
    label = "managed_by"
    value = var.common_labels["managed_by"]
  }
}

resource "docker_container" "prometheus" {
  name    = "${local.name_prefix}-prometheus"
  image   = docker_image.prometheus.image_id
  restart = "unless-stopped"

  ports {
    internal = 9090
    external = 9090
  }

  volumes {
    volume_name    = docker_volume.prometheus_data.name
    container_path = "/prometheus"
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
    value = "prometheus"
  }
}

resource "docker_image" "grafana" {
  name         = "grafana/grafana:12.3.2"
  keep_locally = true
}

resource "docker_volume" "grafana_data" {
  name = "${local.name_prefix}-grafana-data"
  labels {
    label = "managed_by"
    value = var.common_labels["managed_by"]
  }
}

resource "docker_container" "grafana" {
  name    = "${local.name_prefix}-grafana"
  image   = docker_image.grafana.image_id
  restart = "unless-stopped"

  ports {
    internal = 3000
    external = 3000
  }

  env = [
    "GF_SECURITY_ADMIN_PASSWORD=${var.grafana_admin_password}",
    "GF_USERS_ALLOW_SIGN_UP=false",
  ]

  volumes {
    volume_name    = docker_volume.grafana_data.name
    container_path = "/var/lib/grafana"
  }

  networks_advanced {
    name = docker_network.monitoring.id
  }
  networks_advanced {
    name = docker_network.frontend.id
  }

  labels {
    label = "managed_by"
    value = var.common_labels["managed_by"]
  }
  labels {
    label = "component"
    value = "grafana"
  }

  depends_on = [docker_container.prometheus]
}