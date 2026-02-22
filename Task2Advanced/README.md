# Task 2 — Интеграция с CI/CD и удалённым хранением состояния Terraform

## Обзор

Данное решение реализует автоматизированное развёртывание инфраструктуры платформы **Future 2.0** через CI/CD-пайплайн с использованием **удалённого хранения состояния Terraform** в S3-совместимом хранилище (MinIO).

### Архитектурные решения

| Компонент     | Технология                                                      | Обоснование                                            |
|---------------|-----------------------------------------------------------------|--------------------------------------------------------|
| IaC           | Terraform ≥ 1.6                                                 | Декларативный подход, зрелая экосистема                |
| Remote State  | MinIO (S3-совместимый)                                          | Self-hosted, бесплатный, полная совместимость с S3 API |
| State Locking | DynamoDB-совместимая таблица (через MinIO + локальный DynamoDB) | Защита от параллельных записей                         |
| CI/CD         | GitHub Actions                                                  | Нативная интеграция с GitHub-репозиторием              |
| Секреты       | GitHub Secrets + переменные окружения                           | Изоляция чувствительных данных от кода                 |

## Структура директории

```
Task2Advanced/
├── README.md                          # Этот файл
├── terraform/
│   ├── backend.tf                     # Конфигурация S3 backend
│   ├── provider.tf                    # Провайдеры (Docker/Kubernetes)
│   ├── variables.tf                   # Входные переменные
│   ├── outputs.tf                     # Выходные значения
│   ├── main.tf                        # Основная инфраструктура Future 2.0
│   ├── network.tf                     # Сетевая инфраструктура
│   ├── data.tf                        # Слой данных (PostgreSQL, Redis, Kafka)
│   ├── monitoring.tf                  # Observability-стек
│   └── terraform.tfvars.example       # Пример переменных (без секретов)
├── minio/
│   └── docker-compose.yml             # Локальный MinIO для разработки
├── scripts/
│   ├── init-minio.sh                  # Инициализация бакета в MinIO
│   └── tf-wrapper.sh                  # Обёртка для безопасного запуска Terraform
└── .github/
    └── workflows/
        └── terraform.yml              # GitHub Actions pipeline
```

## Потоки данных Future 2.0

Инфраструктура обеспечивает следующие потоки данных платформы:

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│   API GW     │────▶│  App Services│────▶│  PostgreSQL  │
│  (Ingress)   │     │ (K8s Pods)   │     │  (Primary)   │
└──────────────┘     └──────┬───────┘     └──────┬───────┘
                            │                     │
                            ▼                     ▼
                     ┌──────────────┐     ┌──────────────┐
                     │    Kafka     │     │  PostgreSQL  │
                     │  (Events)    │     │  (Replica)   │
                     └──────┬───────┘     └──────────────┘
                            │
                     ┌──────▼───────┐
                     │    Redis     │
                     │  (Cache)     │
                     └──────────────┘
```

---

## Быстрый старт (локальная разработка)

### 1. Запуск MinIO

```bash
cd minio/
docker-compose up -d
```

MinIO Console будет доступен на `http://localhost:9001` (login: `minioadmin` / `minioadmin`).

### 2. Инициализация бакета для Terraform State

```bash
cd scripts/
chmod +x init-minio.sh
./init-minio.sh
```

Скрипт создаёт бакет `terraform-state` и включает версионирование.

### 3. Инициализация и запуск Terraform

```bash
cd terraform/
cp terraform.tfvars.example terraform.tfvars
# Отредактируйте terraform.tfvars при необходимости

terraform init \
  -backend-config="endpoint=http://localhost:9000" \
  -backend-config="access_key=minioadmin" \
  -backend-config="secret_key=minioadmin"

terraform plan -out=plan.tfplan
terraform apply plan.tfplan
```

## CI/CD Pipeline

### Обзор пайплайна

Pipeline реализован в `.github/workflows/terraform.yml` и состоит из трёх этапов:

```
┌─────────────┐     ┌─────────────┐     ┌─────────────────────┐
│  terraform  │────▶│  terraform  │────▶│    terraform        │
│    init     │     │    plan     │     │    apply            │
│             │     │             │     │ (manual approval)   │
└─────────────┘     └─────────────┘     └─────────────────────┘
       │                    │                      │
  Загрузка            Генерация              Применение
  провайдеров         плана +                изменений после
  + backend           артефакт               ручного подтверждения
```

### Этапы пайплайна

| Этап            | Триггер                 | Действие                                                                     |
|-----------------|-------------------------|------------------------------------------------------------------------------|
| Init + Validate | Push в future_pro, PR   | Инициализация backend, валидация синтаксиса, проверка форматирования         |
| Plan            | Push в future_pro, PR   | Генерация плана изменений, сохранение как артефакт, комментарий в PR         |
| Apply           | Только future_pro ветка | Применение после ручного одобрения через GitHub Environment Protection Rules |

### Безопасность пайплайна

1. Секреты. Все credentials хранятся в GitHub Secrets:
    - MINIO_ACCESS_KEY: ключ доступа к MinIO/S3
    - MINIO_SECRET_KEY: секретный ключ MinIO/S3
    - MINIO_ENDPOINT: URL эндпоинта S3

2. Изоляция окружений. Используются GitHub Environments (`production`) с protection rules:
    - Обязательное ревью перед apply
    - Ограничение на ветку future_pro

3. Минимальные привилегии. GITHUB_TOKEN с permissions только contents: read

4. Артефакты. План сохраняется как артефакт между этапами, не передаётся через переменные окружения

5. Нет локального состояния. terraform.tfstate отсутствует в репозитории, добавлен в .gitignore

### Настройка GitHub Secrets

Перейдите в Settings -> Secrets and variables -> Actions и добавьте:

| Secret           | Описание                           | Пример                        |
|------------------|------------------------------------|-------------------------------|
| MINIO_ACCESS_KEY | Access Key для S3 backend          | minioadmin                    |
| MINIO_SECRET_KEY | Secret Key для S3 backend          | minioadmin                    |
| MINIO_ENDPOINT   | Endpoint S3-совместимого хранилища | http://minio.example.com:9000 |

### Настройка Environment Protection

1. Settings -> Environments -> New environment -> production
2. Включите Required reviewers и укажите ответственных за approve
3. В Deployment branches выберите future_pro

## Скрипты

### scripts/init-minio.sh

Инициализирует MinIO для использования как Terraform backend:
- Устанавливает MinIO Client (mc) если отсутствует
- Создаёт бакет terraform-state
- Включает версионирование для защиты состояния
- Проверяет доступность бакета

### scripts/tf-wrapper.sh

Обёртка для безопасного запуска Terraform:
- Проверяет наличие необходимых переменных окружения
- Запрещает apply без предварительного plan
- Логирует все операции с временными метками
- Используется в CI/CD и может использоваться локально

## Конфигурация Terraform

### Backend (backend.tf)

Состояние хранится в S3-совместимом хранилище (MinIO):
- Бакет: terraform-state
- Ключ: future-2-0/terraform.tfstate
- Шифрование: включено (SSE)
- Версионирование: включено на уровне бакета
- Блокировка: через DynamoDB-совместимую таблицу terraform-locks

### Инфраструктура

Terraform-код описывает компоненты платформы Future 2.0:

| Модуль        | Описание                                                  |
|---------------|-----------------------------------------------------------|
| network.tf    | Docker network для изоляции сервисов                      |
| main.tf       | Основные application-сервисы (API Gateway, Backend)       |
| data.tf       | Слой данных: PostgreSQL (primary + replica), Redis, Kafka |
| monitoring.tf | Prometheus + Grafana для observability                    |

## Проверка корректности

### Убедитесь, что состояние не хранится локально:

```bash
# В корне terraform/ не должно быть файлов состояния
ls -la terraform/*.tfstate*    # Должно быть пусто

# Состояние должно быть в MinIO
mc ls myminio/terraform-state/future-2-0/
```

### Валидация Terraform-кода:

```bash
cd terraform/
terraform validate
terraform fmt -check
```

## Требования

- Docker >= 20.10 и Docker Compose ≥ 2.0
- Terraform >= 1.6.0
- MinIO Client (mc) для инициализации бакета
- GitHub-репозиторий с настроенными Secrets и Environments