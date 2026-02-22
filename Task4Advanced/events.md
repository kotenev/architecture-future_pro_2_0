# Каталог доменных событий - "Будущее 2.0"

## Соглашения

- Формат имени: <Noun><PastParticiple> (англ.), например PatientRegistered.
- Транспорт: Apache Kafka (целевая платформа), топик = <domain>.<aggregate>.<event>.
- Формат payload: JSON + Avro Schema Registry для контрактов.
- Версионирование: семантическое (v1, v2), обратная совместимость через optional-поля.
- Идемпотентность: гарантируется через eventId (UUID v7) + дедупликация на стороне потребителя.
- Ordering: события одного агрегата упорядочены по sequenceNumber; между агрегатами - eventual consistency.

### Общая структура envelope

```json
{
  "eventId": "UUID v7",
  "eventType": "PatientRegistered",
  "eventVersion": "v1",
  "aggregateType": "Patient",
  "aggregateId": "UUID",
  "sequenceNumber": 1,
  "timestamp": "ISO-8601",
  "correlationId": "UUID",
  "causationId": "UUID",
  "source": "patient-registry",
  "data": {  }
}
```

## 1. Домен "Пациенты" (Patient Domain)

### PatientRegistered (v1)

| Поле              | Описание                                     |
|-------------------|----------------------------------------------|
| Контекст-источник | Patient Registry                             |
| Агрегат           | Patient                                      |
| Семантика         | Новый пациент зарегистрирован в системе      |
| Топик             | patient.patient.registered                   |
| Подписчики        | Clinical, Billing, FinTech, Analytics        |
| Триггер           | Команда RegisterPatient от оператора клиники |

Минимальный контракт (data):
```json
{
  "patientId": "string (UUID)",
  "fullName": {
    "firstName": "string",
    "lastName": "string",
    "middleName": "string | null"
  },
  "dateOfBirth": "date (ISO-8601)",
  "gender": "enum: MALE | FEMALE | OTHER",
  "registeredAt": "datetime (ISO-8601)",
  "clinicId": "string (UUID)"
}
```

### PatientUpdated (v1)

| Поле              | Описание                                                 |
|-------------------|----------------------------------------------------------|
| Контекст-источник | Patient Registry                                         |
| Агрегат           | Patient                                                  |
| Семантика         | Данные пациента обновлены (контактные, страховые и т.д.) |
| Топик             | patient.patient.updated                                  |
| Подписчики        | Clinical, Billing, FinTech, Analytics                    |

Минимальный контракт:
```json
{
  "patientId": "string (UUID)",
  "changedFields": ["string"],
  "updatedAt": "datetime"
}
```
> Примечание: событие не содержит значений изменённых полей. Подписчики запрашивают актуальные данные через API Patient Registry (CQRS-подход) или получают полный снимок через отдельный канал.

### PatientDeactivated (v1)

| Поле              | Описание                              |
|-------------------|---------------------------------------|
| Контекст-источник | Patient Registry                      |
| Агрегат           | Patient                               |
| Семантика         | Пациент деактивирован (soft delete)   |
| Топик             | patient.patient.deactivated           |
| Подписчики        | Clinical, Billing, FinTech, Analytics |

Минимальный контракт:
```json
{
  "patientId": "string (UUID)",
  "reason": "enum: REQUEST | DECEASED | DUPLICATE_MERGE | REGULATORY",
  "deactivatedAt": "datetime"
}
```

### ConsentGranted (v1)

| Поле              | Описание                                                  |
|-------------------|-----------------------------------------------------------|
| Контекст-источник | Patient Registry                                          |
| Агрегат           | Patient                                                   |
| Семантика         | Пациент дал согласие на определённый тип обработки данных |
| Топик             | patient.patient.consent-granted                           |
| Подписчики        | Clinical, AI Services, Analytics                          |

Минимальный контракт:
```json
{
  "patientId": "string (UUID)",
  "consentType": "enum: PERSONAL_DATA | MEDICAL_DATA | AI_PROCESSING | MARKETING",
  "grantedAt": "datetime",
  "expiresAt": "datetime | null"
}
```

### ConsentRevoked (v1)

| Поле              | Описание                         |
|-------------------|----------------------------------|
| Контекст-источник | Patient Registry                 |
| Агрегат           | Patient                          |
| Семантика         | Пациент отозвал согласие         |
| Топик             | patient.patient.consent-revoked  |
| Подписчики        | Clinical, AI Services, Analytics |

Минимальный контракт:
```json
{
  "patientId": "string (UUID)",
  "consentType": "enum: PERSONAL_DATA | MEDICAL_DATA | AI_PROCESSING | MARKETING",
  "revokedAt": "datetime"
}
```

## 2. Домен "Клинические операции" (Clinical Domain)

### TreatmentEpisodeCreated (v1)

| Поле              | Описание                                |
|-------------------|-----------------------------------------|
| Контекст-источник | Medical Records                         |
| Агрегат           | MedicalRecord                           |
| Семантика         | Открыт новый эпизод лечения пациента    |
| Топик             | clinical.medical-record.episode-created |
| Подписчики        | AI Services, Billing, Analytics         |

Минимальный контракт:
```json
{
  "episodeId": "string (UUID)",
  "recordId": "string (UUID)",
  "patientId": "string (UUID)",
  "doctorId": "string (UUID)",
  "clinicId": "string (UUID)",
  "primaryComplaint": "string",
  "createdAt": "datetime"
}
```

### DiagnosticStudyCompleted (v1)

| Поле              | Описание                                                   |
|-------------------|------------------------------------------------------------|
| Контекст-источник | Diagnostics                                                |
| Агрегат           | DiagnosticStudy                                            |
| Семантика         | Диагностическое исследование завершено, результат доступен |
| Топик             | clinical.diagnostic-study.completed                        |
| Подписчики        | AI Services, Analytics                                     |

Минимальный контракт:
```json
{
  "studyId": "string (UUID)",
  "patientId": "string (UUID)",
  "episodeId": "string (UUID)",
  "studyType": "string",
  "resultSummary": "string",
  "completedAt": "datetime"
}
```
> Примечание: полные результаты (снимки, данные) доступны через внутренний API Clinical Domain. Кроме того, в событие не включаются для защиты PHI.

### TreatmentPrescribed (v1)

| Поле              | Описание                                     |
|-------------------|----------------------------------------------|
| Контекст-источник | Medical Records                              |
| Агрегат           | MedicalRecord                                |
| Семантика         | Врач назначил лечение в рамках эпизода       |
| Топик             | clinical.medical-record.treatment-prescribed |
| Подписчики        | Billing, Analytics                           |

Минимальный контракт:
```json
{
  "prescriptionId": "string (UUID)",
  "episodeId": "string (UUID)",
  "patientId": "string (UUID)",
  "icd10Code": "string",
  "serviceCode": "string",
  "prescribedAt": "datetime"
}
```

### TreatmentCompleted (v1)

| Поле              | Описание                                    |
|-------------------|---------------------------------------------|
| Контекст-источник | Medical Records                             |
| Агрегат           | MedicalRecord                               |
| Семантика         | Эпизод лечения завершён                     |
| Топик             | clinical.medical-record.treatment-completed |
| Подписчики        | Billing, FinTech, Analytics                 |

Минимальный контракт:
```json
{
  "episodeId": "string (UUID)",
  "patientId": "string (UUID)",
  "outcome": "enum: RECOVERED | ONGOING | REFERRED | DECEASED",
  "totalServices": "integer",
  "completedAt": "datetime"
}
```

## 3. Домен "ИИ-сервисы" (AI Services Domain)

### AIStudyStarted (v1)

| Поле              | Описание                                         |
|-------------------|--------------------------------------------------|
| Контекст-источник | AI Diagnostics                                   |
| Агрегат           | AIStudy                                          |
| Семантика         | Запущена обработка медицинских данных моделью ИИ |
| Топик             | ai.ai-study.started                              |
| Подписчики        | Clinical, Analytics                              |

Минимальный контракт:
```json
{
  "aiStudyId": "string (UUID)",
  "studyId": "string (UUID)",
  "modelId": "string (UUID)",
  "modelVersion": "string (semver)",
  "startedAt": "datetime"
}
```

### AIStudyCompleted (v1)

| Поле              | Описание                                             |
|-------------------|------------------------------------------------------|
| Контекст-источник | AI Diagnostics                                       |
| Агрегат           | AIStudy                                              |
| Семантика         | ИИ-исследование завершено, рекомендации сформированы |
| Топик             | ai.ai-study.completed                                |
| Подписчики        | Clinical (Medical Records), Analytics                |

Минимальный контракт:
```json
{
  "aiStudyId": "string (UUID)",
  "studyId": "string (UUID)",
  "predictions": [
    {
      "label": "string",
      "confidence": "number (0.0–1.0)",
      "icd10Suggestion": "string | null"
    }
  ],
  "overallConfidence": "number (0.0–1.0)",
  "completedAt": "datetime"
}
```

### AIStudyFailed (v1)

| Поле              | Описание                         |
|-------------------|----------------------------------|
| Контекст-источник | AI Diagnostics                   |
| Агрегат           | AIStudy                          |
| Семантика         | ИИ-обработка завершилась ошибкой |
| Топик             | ai.ai-study.failed               |
| Подписчики        | Clinical, Analytics (мониторинг) |

Минимальный контракт:
```json
{
  "aiStudyId": "string (UUID)",
  "studyId": "string (UUID)",
  "errorCode": "string",
  "errorMessage": "string",
  "failedAt": "datetime"
}
```

### AIModelUpdated (v1)

| Поле              | Описание                      |
|-------------------|-------------------------------|
| Контекст-источник | AI Diagnostics                |
| Агрегат           | AIStudy (управляющее событие) |
| Семантика         | Обновлена версия ИИ-модели    |
| Топик             | ai.model.updated              |
| Подписчики**      | Clinical, Analytics           |

Минимальный контракт:
```json
{
  "modelId": "string (UUID)",
  "previousVersion": "string (semver)",
  "newVersion": "string (semver)",
  "changelog": "string",
  "updatedAt": "datetime"
}
```

## 4. Домен "Финтех" (FinTech Domain)

### CreditApplicationSubmitted (v1)

| Поле              | Описание                             |
|-------------------|--------------------------------------|
| Контекст-источник | Credit Management                    |
| Агрегат           | CreditContract                       |
| Семантика         | Подана заявка на кредит              |
| Топик             | fintech.credit.application-submitted |
| Подписчики        | Analytics                            |

Минимальный контракт:
```json
{
  "applicationId": "string (UUID)",
  "clientId": "string (UUID)",
  "requestedAmount": { "value": "number", "currency": "string" },
  "requestedTermMonths": "integer",
  "purpose": "enum: MEDICAL | PERSONAL | OTHER",
  "submittedAt": "datetime"
}
```

### CreditScoringCompleted (v1)

| Поле              | Описание                            |
|-------------------|-------------------------------------|
| Контекст-источник | Credit Management                   |
| Агрегат           | CreditContract                      |
| Семантика         | Завершена оценка кредитоспособности |
| Топи              | fintech.credit.scoring-completed    |
| Подписчики        | Analytics                           |

Минимальный контракт:
```json
{
  "applicationId": "string (UUID)",
  "clientId": "string (UUID)",
  "score": "integer",
  "decision": "enum: APPROVED | REJECTED | MANUAL_REVIEW",
  "completedAt": "datetime"
}
```

### CreditContractCreated (v1)

| Поле              | Описание                               |
|-------------------|----------------------------------------|
| Контекст-источник | Credit Management                      |
| Агрегат           | CreditContract                         |
| Семантика         | Создан и подписан кредитный договор    |
| Топик             | fintech.credit.contract-created        |
| Подписчики        | Billing, Payment Processing, Analytics |

Минимальный контракт:
```json
{
  "contractId": "string (UUID)",
  "clientId": "string (UUID)",
  "amount": { "value": "number", "currency": "string" },
  "interestRate": "number",
  "termMonths": "integer",
  "monthlyPayment": { "value": "number", "currency": "string" },
  "createdAt": "datetime"
}
```

### CreditContractClosed (v1)

| Поле              | Описание                                                     |
|-------------------|--------------------------------------------------------------|
| Контекст-источник | Credit Management                                            |
| Агрегат           | CreditContract                                               |
| Семантика         | Кредитный договор закрыт (погашен, дефолт, реструктуризация) |
| Топик             | fintech.credit.contract-closed                               |
| Подписчики        | Billing, Analytics                                           |

Минимальный контракт:
```json
{
  "contractId": "string (UUID)",
  "reason": "enum: PAID_OFF | DEFAULTED | RESTRUCTURED",
  "closedAt": "datetime"
}
```

### PaymentProcessed (v1)

| Поле              | Описание                              |
|-------------------|---------------------------------------|
| Контекст-источник | Payment Processing                    |
| Агрегат           | Payment                               |
| Семантика         | Платёж успешно проведён               |
| Топик**           | fintech.payment.processed             |
| Подписчики        | Billing, Credit Management, Analytics |

Минимальный контракт:
```json
{
  "paymentId": "string (UUID)",
  "contractId": "string (UUID) | null",
  "invoiceId": "string (UUID) | null",
  "amount": { "value": "number", "currency": "string" },
  "method": "enum: CARD | BANK_TRANSFER | CASH",
  "processedAt": "datetime"
}
```

### PaymentFailed (v1)

| Поле              | Описание                     |
|-------------------|------------------------------|
| Контекст-источник | Payment Processing           |
| Агрегат           | Payment                      |
| Семантика         | Платёж не прошёл             |
| Топик             | fintech.payment.failed       |
| Подписчики        | Credit Management, Analytics |

Минимальный контракт:
```json
{
  "paymentId": "string (UUID)",
  "reason": "string",
  "failedAt": "datetime"
}
```

### PaymentOverdue (v1)

| Поле              | Описание                                |
|-------------------|-----------------------------------------|
| Контекст-источник | Payment Processing                      |
| Агрегат           | Payment (генерируется scheduler-ом)     |
| Семантика         | Обнаружена просрочка платежа по кредиту |
| Топик             | fintech.payment.overdue                 |
| Подписчики        | Credit Management, Billing, Analytics   |

Минимальный контракт:
```json
{
  "contractId": "string (UUID)",
  "scheduleItemId": "string (UUID)",
  "dueDate": "date",
  "daysOverdue": "integer",
  "outstandingAmount": { "value": "number", "currency": "string" },
  "detectedAt": "datetime"
}
```

### AccountOpened (v1)

| Поле              | Описание                             |
|-------------------|--------------------------------------|
| Контекст-источник | Account Management                   |
| Агрегат           | Account                              |
| Семантика         | Открыт новый клиентский счёт         |
| Топик             | fintech.account.opened               |
| Подписчики        | Billing, Patient Registry, Analytics |

Минимальный контракт:
```json
{
  "accountId": "string (UUID)",
  "clientId": "string (UUID)",
  "accountType": "enum: SETTLEMENT | CREDIT | DEPOSIT",
  "currency": "string",
  "openedAt": "datetime"
}
```

## 5. Домен "Биллинг" (Billing Domain)

### InvoiceIssued (v1)

| Поле              | Описание                     |
|-------------------|------------------------------|
| Контекст-источник | Billing & Invoicing          |
| Агрегат           | Invoice                      |
| Семантика         | Счёт выставлен клиенту       |
| Топик             | billing.invoice.issued       |
| Подписчики        | FinTech (Payment), Analytics |

Минимальный контракт:
```json
{
  "invoiceId": "string (UUID)",
  "clientId": "string (UUID)",
  "serviceRef": {
    "type": "enum: MEDICAL | CREDIT | OTHER",
    "refId": "string (UUID)"
  },
  "lines": [
    {
      "description": "string",
      "amount": { "value": "number", "currency": "string" },
      "tariffCode": "string"
    }
  ],
  "totalAmount": { "value": "number", "currency": "string" },
  "dueDate": "date",
  "issuedAt": "datetime"
}
```

### InvoicePaid (v1)

| Поле              | Описание                 |
|-------------------|--------------------------|
| Контекст-источник | Billing & Invoicing      |
| Агрегат           | Invoice                  |
| Семантика         | Счёт оплачен (полностью) |
| Топик             | billing.invoice.paid     |
| Подписчики        | FinTech, Analytics       |

Минимальный контракт:
```json
{
  "invoiceId": "string (UUID)",
  "paymentId": "string (UUID)",
  "paidAmount": { "value": "number", "currency": "string" },
  "paidAt": "datetime"
}
```

### InvoiceCancelled (v1)

| Поле              | Описание                  |
|-------------------|---------------------------|
| Контекст-источник | Billing & Invoicing       |
| Агрегат           | Invoice                   |
| Семантика         | Счёт аннулирован          |
| Топик             | billing.invoice.cancelled |
| Подписчики        | FinTech, Analytics        |

Минимальный контракт:
```json
{
  "invoiceId": "string (UUID)",
  "reason": "string",
  "cancelledAt": "datetime"
}
```

## 6. Домен "Персонал и ресурсы" (Staff & Resources Domain)

### EmployeeHired (v1)

| Поле              | Описание                      |
|-------------------|-------------------------------|
| Контекст-источник | Staff Management              |
| Агрегат           | Employee                      |
| Семантика         | Новый сотрудник принят в штат |
| Топик             | staff.employee.hired          |
| Подписчики        | Clinical, Analytics           |

Минимальный контракт:
```json
{
  "employeeId": "string (UUID)",
  "fullName": "string",
  "position": "string",
  "department": "string",
  "clinicId": "string (UUID) | null",
  "hiredAt": "datetime"
}
```

### EmployeeDismissed (v1)

| Поле              | Описание                 |
|-------------------|--------------------------|
| Контекст-источник | Staff Management         |
| Агрегат           | Employee                 |
| Семантика         | Сотрудник уволен         |
| Топик             | staff.employee.dismissed |
| Подписчики        | Clinical, Analytics      |

Минимальный контракт:
```json
{
  "employeeId": "string (UUID)",
  "reason": "enum: VOLUNTARY | INVOLUNTARY | RETIREMENT",
  "dismissedAt": "datetime"
}
```

### ShiftAssigned (v1)

| Поле              | Описание                      |
|-------------------|-------------------------------|
| Контекст-источник | Staff Management              |
| Агрегат           | Employee                      |
| Семантика         | Сотруднику назначена смена    |
| Топик             | staff.employee.shift-assigned |
| Подписчики        | Clinical                      |

Минимальный контракт:
```json
{
  "employeeId": "string (UUID)",
  "clinicId": "string (UUID)",
  "shiftDate": "date",
  "shiftType": "enum: MORNING | DAY | NIGHT | ON_CALL",
  "assignedAt": "datetime"
}
```

### SupplyOrderCreated (v1)

| Поле              | Описание                                                      |
|-------------------|---------------------------------------------------------------|
| Контекст-источник | Inventory Management                                          |
| Агрегат           | SupplyOrder                                                   |
| Семантика         | Создана заявка на закупку расходных материалов / оборудования |
| Топик             | resources.supply-order.created                                |
| Подписчики        | Billing, Analytics                                            |

Минимальный контракт:
```json
{
  "orderId": "string (UUID)",
  "items": [
    {
      "productCode": "string",
      "name": "string",
      "quantity": "integer"
    }
  ],
  "requestedBy": "string (UUID)",
  "createdAt": "datetime"
}
```

### InventoryReplenished (v1)

| Поле              | Описание                        |
|-------------------|---------------------------------|
| Контекст-источник | Inventory Management            |
| Агрегат           | SupplyOrder                     |
| Семантика         | Запас товара на складе пополнен |
| Топик             | resources.inventory.replenished |
| Подписчики        | Clinical, Analytics             |

Минимальный контракт:
```json
{
  "productCode": "string",
  "quantity": "integer",
  "warehouseId": "string (UUID)",
  "orderId": "string (UUID)",
  "replenishedAt": "datetime"
}
```

### InventoryLow (v1)

| Поле              | Описание                                |
|-------------------|-----------------------------------------|
| Контекст-источник | Inventory Management                    |
| Агрегат           | SupplyOrder (генерируется мониторингом) |
| Семантика         | Остаток товара ниже порогового значения |
| Топик             | resources.inventory.low                 |
| Подписчики        | Staff (для автозаказа), Analytics       |

Минимальный контракт:
```json
{
  "productCode": "string",
  "currentQuantity": "integer",
  "threshold": "integer",
  "warehouseId": "string (UUID)",
  "detectedAt": "datetime"
}
```

## Сводная матрица событий

| #  | Событие                    | Топик                                        | Источник  | Подписчики                            |
|----|----------------------------|----------------------------------------------|-----------|---------------------------------------|
| 1  | PatientRegistered          | patient.patient.registered                   | Patient   | Clinical, Billing, FinTech, Analytics |
| 2  | PatientUpdated             | patient.patient.updated                      | Patient   | Clinical, Billing, FinTech, Analytics |
| 3  | PatientDeactivated         | patient.patient.deactivated                  | Patient   | Clinical, Billing, FinTech, Analytics |
| 4  | ConsentGranted             | patient.patient.consent-granted              | Patient   | Clinical, AI, Analytics               |
| 5  | ConsentRevoked             | patient.patient.consent-revoked              | Patient   | Clinical, AI, Analytics               |
| 6  | TreatmentEpisodeCreated    | clinical.medical-record.episode-created      | Clinical  | AI, Billing, Analytics                |
| 7  | DiagnosticStudyCompleted   | clinical.diagnostic-study.completed          | Clinical  | AI, Analytics                         |
| 8  | TreatmentPrescribed        | clinical.medical-record.treatment-prescribed | Clinical  | Billing, Analytics                    |
| 9  | TreatmentCompleted         | clinical.medical-record.treatment-completed  | Clinical  | Billing, FinTech, Analytics           |
| 10 | AIStudyStarted             | ai.ai-study.started                          | AI        | Clinical, Analytics                   |
| 11 | AIStudyCompleted           | ai.ai-study.completed                        | AI        | Clinical, Analytics                   |
| 12 | AIStudyFailed              | ai.ai-study.failed                           | AI        | Clinical, Analytics                   |
| 13 | AIModelUpdated             | ai.model.updated                             | AI        | Clinical, Analytics                   |
| 14 | CreditApplicationSubmitted | fintech.credit.application-submitted         | FinTech   | Analytics                             |
| 15 | CreditScoringCompleted     | fintech.credit.scoring-completed             | FinTech   | Analytics                             |
| 16 | CreditContractCreated      | fintech.credit.contract-created              | FinTech   | Billing, Payment, Analytics           |
| 17 | CreditContractClosed       | fintech.credit.contract-closed               | FinTech   | Billing, Analytics                    |
| 18 | PaymentProcessed           | fintech.payment.processed                    | FinTech   | Billing, Credit, Analytics            |
| 19 | PaymentFailed              | fintech.payment.failed                       | FinTech   | Credit, Analytics                     |
| 20 | PaymentOverdue             | fintech.payment.overdue                      | FinTech   | Credit, Billing, Analytics            |
| 21 | AccountOpened              | fintech.account.opened                       | FinTech   | Billing, Patient, Analytics           |
| 22 | InvoiceIssued              | billing.invoice.issued                       | Billing   | FinTech, Analytics                    |
| 23 | InvoicePaid                | billing.invoice.paid                         | Billing   | FinTech, Analytics                    |
| 24 | InvoiceCancelled           | billing.invoice.cancelled                    | Billing   | FinTech, Analytics                    |
| 25 | EmployeeHired              | staff.employee.hired                         | Staff     | Clinical, Analytics                   |
| 26 | EmployeeDismissed          | staff.employee.dismissed                     | Staff     | Clinical, Analytics                   |
| 27 | ShiftAssigned              | staff.employee.shift-assigned                | Staff     | Clinical                              |
| 28 | SupplyOrderCreated         | resources.supply-order.created               | Resources | Billing, Analytics                    |
| 29 | InventoryReplenished       | resources.inventory.replenished              | Resources | Clinical, Analytics                   |
| 30 | InventoryLow               | resources.inventory.low                      | Resources | Staff, Analytics                      |


## DLQ (Dead Letter Queue) и обработка ошибок

Для каждого топика предусмотрен DLQ-топик с суффиксом .dlq:
- patient.patient.registered.dlq
- fintech.payment.processed.dlq
- и т.д.

Политика DLQ:
1. Сообщение попадает в DLQ после 3 неуспешных попыток обработки.
2. Экспоненциальный backoff: 1с -> 5с -> 30с.
3. Алерт в систему мониторинга при попадании в DLQ.
4. Ручная/автоматическая переобработка через replay-механизм.

Schema Registry:
- Все контракты событий регистрируются в Confluent Schema Registry (Avro).
- Эволюция схем: только backward-compatible изменения (добавление optional-полей).
- Breaking changes → новая версия события (v2) + период параллельной публикации.