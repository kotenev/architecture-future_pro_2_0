resource "docker_network" "frontend" {
  name   = "${local.name_prefix}-frontend"
  driver = "bridge"

  labels {
    label = "managed_by"
    value = var.common_labels["managed_by"]
  }

  labels {
    label = "zone"
    value = "frontend"
  }
}

resource "docker_network" "backend" {
  name     = "${local.name_prefix}-backend"
  driver   = "bridge"
  internal = true # Нет прямого доступа извне

  labels {
    label = "managed_by"
    value = var.common_labels["managed_by"]
  }

  labels {
    label = "zone"
    value = "backend"
  }
}

resource "docker_network" "data" {
  name     = "${local.name_prefix}-data"
  driver   = "bridge"
  internal = true # Изолирована от внешнего доступа

  labels {
    label = "managed_by"
    value = var.common_labels["managed_by"]
  }

  labels {
    label = "zone"
    value = "data"
  }
}

resource "docker_network" "monitoring" {
  name   = "${local.name_prefix}-monitoring"
  driver = "bridge"

  labels {
    label = "managed_by"
    value = var.common_labels["managed_by"]
  }

  labels {
    label = "zone"
    value = "monitoring"
  }
}