variable "project_name" {
  description = "Название проекта (используется как префикс ресурсов)"
  type        = string
  default     = "future-2-0"
}

variable "environment" {
  description = "Окружение: dev, staging, production"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "Environment должен быть: dev, staging или production."
  }
}

variable "docker_host" {
  description = "Docker daemon endpoint"
  type        = string
  default     = "unix:///var/run/docker.sock"
}

variable "postgres_version" {
  description = "Версия Docker-образа PostgreSQL"
  type        = string
  default     = "16-alpine"
}

variable "postgres_db" {
  description = "Имя основной базы данных"
  type        = string
  default     = "future_db"
}

variable "postgres_user" {
  description = "Пользователь PostgreSQL"
  type        = string
  default     = "future_app"
}

variable "postgres_password" {
  description = "Пароль PostgreSQL (задайте через TF_VAR_postgres_password)"
  type        = string
  sensitive   = true
}

variable "redis_version" {
  description = "Версия Docker-образа Redis"
  type        = string
  default     = "7-alpine"
}

variable "redis_password" {
  description = "Пароль Redis (задайте через TF_VAR_redis_password)"
  type        = string
  sensitive   = true
}

variable "kafka_version" {
  description = "Версия Docker-образа Kafka (Bitnami)"
  type        = string
  default     = "3.7"
}

variable "grafana_admin_password" {
  description = "Пароль администратора Grafana"
  type        = string
  sensitive   = true
  default     = "admin"
}

variable "common_labels" {
  description = "Общие метки для всех ресурсов"
  type        = map(string)
  default = {
    managed_by = "terraform"
    project    = "future-2-0"
    sprint     = "11"
  }
}