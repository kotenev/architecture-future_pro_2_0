#!/usr/bin/env bash

set -euo pipefail

COMMAND="${1:-help}"
TF_DIR="${TF_DIR:-$(cd "$(dirname "$0")/../terraform" && pwd)}"
LOG_FILE="${TF_LOG_FILE:-/tmp/terraform-$(date +%Y%m%d-%H%M%S).log}"
PLAN_FILE="${TF_DIR}/tfplan"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "${LOG_FILE}"; }

check_required_vars() {
    local missing=0
    for var in AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY; do
        if [ -z "${!var:-}" ]; then
            log "${RED}Переменная ${var} не установлена${NC}"
            missing=1
        fi
    done
    if [ "$missing" -eq 1 ]; then
        log "${RED}Установите переменные окружения или используйте -backend-config${NC}"
        exit 1
    fi
}

check_terraform() {
    if ! command -v terraform &> /dev/null; then
        log "${RED}Terraform не найден. Установите: https://developer.hashicorp.com/terraform/install${NC}"
        exit 1
    fi
    log "${GREEN}Terraform version: $(terraform version -json | head -1)${NC}"
}

cd "${TF_DIR}"
log "============================================="
log "Terraform Wrapper — Команда: ${COMMAND}"
log "Директория: ${TF_DIR}"
log "============================================="

case "${COMMAND}" in
    init)
        check_terraform
        log "${YELLOW}▶ terraform init${NC}"
        terraform init \
            -backend-config="access_key=${AWS_ACCESS_KEY_ID:-}" \
            -backend-config="secret_key=${AWS_SECRET_ACCESS_KEY:-}" \
            -backend-config="endpoint=${MINIO_ENDPOINT:-http://localhost:9000}" \
            2>&1 | tee -a "${LOG_FILE}"
        log "${GREEN}Init завершён${NC}"
        ;;

    plan)
        check_terraform
        check_required_vars
        log "${YELLOW}terraform plan${NC}"
        terraform plan -out="${PLAN_FILE}" -detailed-exitcode 2>&1 | tee -a "${LOG_FILE}"
        log "${GREEN}Plan сохранён: ${PLAN_FILE}${NC}"
        ;;

    apply)
        check_terraform
        check_required_vars
        if [ ! -f "${PLAN_FILE}" ]; then
            log "${RED}Файл плана не найден: ${PLAN_FILE}${NC}"
            log "${RED}Сначала выполните: ./tf-wrapper.sh plan${NC}"
            exit 1
        fi
        log "${YELLOW}terraform apply (из сохранённого плана)${NC}"
        read -rp "Применить план? (yes/no): " confirm
        if [ "${confirm}" != "yes" ]; then
            log "${YELLOW}Apply отменён пользователем${NC}"
            exit 0
        fi
        terraform apply "${PLAN_FILE}" 2>&1 | tee -a "${LOG_FILE}"
        rm -f "${PLAN_FILE}"
        log "${GREEN}Apply завершён${NC}"
        ;;

    destroy)
        check_terraform
        check_required_vars
        log "${RED}terraform destroy${NC}"
        read -rp "УДАЛИТЬ всю инфраструктуру? (yes/no): " confirm
        if [ "${confirm}" != "yes" ]; then
            log "${YELLOW}⏹ Destroy отменён${NC}"
            exit 0
        fi
        terraform destroy -auto-approve 2>&1 | tee -a "${LOG_FILE}"
        log "${GREEN}Destroy завершён${NC}"
        ;;

    output)
        terraform output -no-color 2>&1 | tee -a "${LOG_FILE}"
        ;;

    help|*)
        echo "Использование: $0 {init|plan|apply|destroy|output}"
        echo ""
        echo "Переменные окружения:"
        echo "  AWS_ACCESS_KEY_ID      Ключ доступа S3/MinIO"
        echo "  AWS_SECRET_ACCESS_KEY   Секретный ключ S3/MinIO"
        echo "  MINIO_ENDPOINT          Эндпоинт (по умолчанию http://localhost:9000)"
        echo "  TF_DIR                  Путь к Terraform-директории"
        echo "  TF_LOG_FILE             Путь к файлу лога"
        exit 0
        ;;
esac

log "Лог записан в: ${LOG_FILE}"