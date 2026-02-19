#!/usr/bin/env bash

set -euo pipefail

ENDPOINT="${1:-http://localhost:9000}"
ACCESS_KEY="${2:-minioadmin}"
SECRET_KEY="${3:-minioadmin}"
ALIAS="tfminio"
BUCKET="terraform-state"

echo "============================================="
echo "MinIO Terraform State — Initialization"
echo "============================================="
echo "Endpoint:  ${ENDPOINT}"
echo "Bucket:    ${BUCKET}"
echo "============================================="

if ! command -v mc &> /dev/null; then
    echo "MinIO Client (mc) не найден. Устанавливаю..."
    curl -fsSL https://dl.min.io/client/mc/release/linux-amd64/mc -o /usr/local/bin/mc
    chmod +x /usr/local/bin/mc
    echo "mc установлен"
fi

echo "Ожидание доступности MinIO на ${ENDPOINT}..."
for i in $(seq 1 30); do
    if mc alias set "${ALIAS}" "${ENDPOINT}" "${ACCESS_KEY}" "${SECRET_KEY}" --api S3v4 &> /dev/null; then
        echo "MinIO доступен"
        break
    fi
    if [ "$i" -eq 30 ]; then
        echo "MinIO недоступен после 30 попыток. Проверьте docker-compose."
        exit 1
    fi
    sleep 2
done

if mc ls "${ALIAS}/${BUCKET}" &> /dev/null; then
    echo "Бакет '${BUCKET}' уже существует"
else
    mc mb "${ALIAS}/${BUCKET}"
    echo "Бакет '${BUCKET}' создан"
fi

mc version enable "${ALIAS}/${BUCKET}"
echo "Версионирование включено для '${BUCKET}'"

echo ""
echo "============================================="
echo "Проверка конфигурации:"
echo "============================================="
mc ls "${ALIAS}/${BUCKET}" && echo "Бакет доступен" || echo "Ошибка доступа"
mc version info "${ALIAS}/${BUCKET}"
echo ""
echo "Готово! Terraform backend настроен."
echo ""
echo "Для инициализации Terraform выполните:"
echo "  cd ../terraform/"
echo "  terraform init \\"
echo "    -backend-config=\"endpoint=${ENDPOINT}\" \\"
echo "    -backend-config=\"access_key=${ACCESS_KEY}\" \\"
echo "    -backend-config=\"secret_key=${SECRET_KEY}\""