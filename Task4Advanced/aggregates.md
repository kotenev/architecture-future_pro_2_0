# Агрегаты - "Будущее 2.0"

## Принципы проектирования агрегатов

- Каждый агрегат определяет транзакционную границу. Все изменения внутри агрегата атомарны.
- Между агрегатами используется eventual consistency через доменные события.
- Агрегаты идентифицируются глобально уникальными ключами (UUID v7 для сортируемости по времени).
- Инварианты защищаются внутри агрегата; между агрегатами - через saga/policy.

## 1. Домен "Пациенты" (Patient Domain)

### Агрегат: Patient (Пациент)

| Характеристика      | Описание                                                                 |
|---------------------|--------------------------------------------------------------------------|
| Bounded Context     | Patient Registry                                                         |
| Корневая сущность   | Patient                                                                  |
| Ключ                | patientId: UUID                                                          |
| Внутренние сущности | ContactInfo, Consent, InsurancePolicy                                    |
| Value Objects       | FullName, DateOfBirth, Gender, PhoneNumber, Email, Address, PassportData |

Инварианты:
1. Пациент должен иметь хотя бы одно активное согласие на обработку персональных данных.
2. ФИО и дата рождения обязательны при регистрации.
3. Пациент не может быть удалён, только деактивирован (soft delete): требование регулятора.
4. Один пациент = один patientId (Golden Record); дубликаты разрешаются через процесс мёрджа.

Публикуемые события:
- PatientRegistered { patientId, fullName, registeredAt }
- PatientUpdated { patientId, changedFields[], updatedAt }
- PatientDeactivated { patientId, reason, deactivatedAt }
- ConsentGranted { patientId, consentType, grantedAt }
- ConsentRevoked { patientId, consentType, revokedAt }


## 2. Домен "Клинические операции" (Clinical Domain)

### Агрегат: MedicalRecord (Медицинская карта)

| Характеристика      | Описание                                       |
|---------------------|------------------------------------------------|
| Bounded Context     | Medical Records                                |
| Корневая сущность   | MedicalRecord                                  |
| Ключ                | recordId: UUID, внешний ключ 'patientId: UUID' |
| Внутренние сущности | TreatmentEpisode, Diagnosis, Prescription      |
| Value Objects       | ICD10Code, DiagnosisDescription, DosageInfo    |
Инварианты:
1. Медкарта привязана ровно к одному пациенту.
2. Эпизод лечения не может быть закрыт, если есть незавершённые назначения.
3. Диагноз должен содержать валидный код ICD-10.
4. Медкарта не удаляется, а архивируется (требование Минздрава, хранение 25 лет).

Публикуемые события:
- TreatmentEpisodeCreated { recordId, patientId, episodeId, doctorId, createdAt }
- TreatmentPrescribed { recordId, episodeId, prescriptionId, icd10Code }
- TreatmentCompleted { recordId, episodeId, completedAt, outcome }


### Агрегат: DiagnosticStudy (Диагностическое исследование)

| Характеристика      | Описание                                          |
|---------------------|---------------------------------------------------|
| Bounded Context     | Diagnostics                                       |
| Корневая сущность   | DiagnosticStudy                                   |
| Ключ                | studyId: UUID, внешние ключи patientId, episodeId |
| Внутренние сущности | StudyResult, Attachment                           |
| Value Objects       | StudyType, BodyRegion, Modality                   |

Инварианты:
1. Исследование привязано к эпизоду лечения.
2. Результат не может быть изменён после подтверждения врачом (immutable после финализации).
3. Вложения (снимки) хранятся в object storage, в агрегате только ссылки.

Публикуемые события:
- DiagnosticStudyOrdered { studyId, patientId, episodeId, studyType, orderedAt }
- DiagnosticStudyCompleted { studyId, resultSummary, completedAt }
- DiagnosticStudyFinalized { studyId, doctorId, finalizedAt }

## 3. Домен "ИИ-сервисы" (AI Services Domain)

### Агрегат: AIStudy (ИИ-исследование)

| Характеристика      | Описание                                        |
|---------------------|-------------------------------------------------|
| Bounded Context     | AI Diagnostics                                  |
| Корневая сущность   | AIStudy                                         |
| Ключ                | aiStudyId: UUID, внешние ключи studyId, modelId |
| Внутренние сущности | Prediction, Confidence                          |
| Value Objects       | ModelVersion, PredictionLabel, ConfidenceScore  |

Инварианты:
1. ИИ-исследование ссылается на конкретную версию модели.
2. Результат ИИ-исследования является рекомендательным и не заменяет решение врача.
3. ConfidenceScore в диапазоне [0.0, 1.0].
4. После завершения результат неизменяем (для аудита).

Публикуемые события:
- AIStudyStarted { aiStudyId, studyId, modelId, modelVersion, startedAt }
- AIStudyCompleted { aiStudyId, studyId, predictions[], confidence, completedAt }
- AIStudyFailed { aiStudyId, studyId, errorCode, failedAt }
- AIModelUpdated { modelId, newVersion, updatedAt }

## 4. Домен "Финтех" (FinTech Domain)

### Агрегат: CreditContract (Кредитный договор)

| Характеристика        | Описание                                                            |
|-----------------------|---------------------------------------------------------------------|
| Bounded Context       | Credit Management                                                   |
| Корневая сущность     | CreditContract                                                      |
| Ключ                  | contractId: UUID, внешний ключ clientId (= patientId или отдельный) |
| Внутренние сущности** | PaymentSchedule, ScheduleItem                                       |
| Value Objects         | Money, InterestRate, Term, CreditStatus                             |

Инварианты:
1. Кредит может быть создан только после успешного скоринга.
2. Сумма кредита больше 0, срок больше 0 месяцев.
3. График платежей формируется при создании договора и не может содержать пропущенных периодов.
4. Статус кредита: Active -> PaidOff | Defaulted | Restructured. Обратные переходы запрещены (кроме Restructured -> Active).

Публикуемые события:
- CreditApplicationSubmitted { applicationId, clientId, amount, term, submittedAt }
- CreditScoringCompleted { applicationId, score, decision, completedAt }
- CreditContractCreated { contractId, clientId, amount, rate, term, createdAt }
- CreditContractClosed { contractId, reason, closedAt }

### Агрегат: Payment (Платёж)

| Характеристика      | Описание                                            |
|---------------------|-----------------------------------------------------|
| Bounded Context     | Payment Processing                                  |
| Корневая сущность   | Payment                                             |
| Ключ                | paymentId: UUID                                     |
| Внутренние сущности | -                                                   |
| Value Objects       | Money, PaymentMethod, PaymentStatus, TransactionRef |

Инварианты:
1. Платёж неизменяем после подтверждения (immutable).
2. Сумма платежа больше 0.
3. Идемпотентность: повторная отправка с тем же idempotencyKey не создаёт дубликат.

Публикуемые события:
- PaymentProcessed { paymentId, contractId, amount, method, processedAt }
- PaymentFailed { paymentId, reason, failedAt }
- PaymentOverdue { contractId, scheduleItemId, dueDate, overdueAt }

### Агрегат: Account (Счёт)

| Характеристика      | Описание                                    |
|---------------------|---------------------------------------------|
| Bounded Context     | Account Management                          |
| Корневая сущность   | Account                                     |
| Ключ                | accountId: UUID, внешний ключ clientId      |
| Внутренние сущности | Transaction (append-only log)               |
| Value Objects       | Money, Currency, AccountType, AccountStatus |

Инварианты:
1. Баланс счёта не может быть отрицательным (для расчётного счёта).
2. Каждая транзакция append-only, удаление невозможно.
3. Закрытый счёт не принимает новых транзакций.

Публикуемые события:
- AccountOpened { accountId, clientId, accountType, openedAt }
- AccountCredited { accountId, amount, transactionRef, creditedAt }
- AccountDebited { accountId, amount, transactionRef, debitedAt }
- AccountClosed { accountId, reason, closedAt }

## 5. Домен "Биллинг" (Billing Domain)

### Агрегат: Invoice (Счёт на оплату)

| Характеристика      | Описание                                            |
|---------------------|-----------------------------------------------------|
| Bounded Context     | Billing & Invoicing                                 |
| Корневая сущность   | Invoice                                             |
| Ключ                | invoiceId: UUID, внешние ключи clientId, serviceRef |
| Внутренние сущности | InvoiceLine                                         |
| Value Objects       | Money, TariffCode, InvoiceStatus, ServicePeriod     |

Инварианты:
1. Счёт содержит хотя бы одну строку.
2. Статус: Draft -> Issued -> Paid | Cancelled. Paid и Cancelled терминальные.
3. Итоговая сумма = сумма всех строк + налоги.
4. Счёт за медицинские услуги привязан к episodeId, за финтех - к contractId.

Публикуемые события:
- InvoiceIssued { invoiceId, clientId, totalAmount, issuedAt }
- InvoicePaid { invoiceId, paidAmount, paidAt }
- InvoiceCancelled { invoiceId, reason, cancelledAt }

## 6. Домен "Персонал и ресурсы" (Staff & Resources Domain)

### Агрегат: Employee (Сотрудник)

| Характеристика      | Описание                                  |
|---------------------|-------------------------------------------|
| Bounded Context     | Staff Management                          |
| Корневая сущность   | Employee                                  |
| Ключ                | employeeId: UUID                          |
| Внутренние сущности | Qualification, Certification, Schedule    |
| Value Objects       | FullName, Position, Department, ShiftSlot |

Инварианты:
1. Врач должен иметь хотя бы одну действующую сертификацию.
2. Одна смена не может пересекаться с другой для того же сотрудника.
3. Уволенный сотрудник не может быть назначен на смену.

Публикуемые события:
- EmployeeHired { employeeId, position, department, hiredAt }
- EmployeeDismissed { employeeId, reason, dismissedAt }
- ShiftAssigned { employeeId, shiftDate, shiftType, clinicId }
- CertificationExpiring { employeeId, certificationId, expiresAt }

### Агрегат: SupplyOrder (Заявка на снабжение)

| Характеристика      | Описание                          |
|---------------------|-----------------------------------|
| Bounded Context     | Inventory Management              |
| Корневая сущность   | SupplyOrder                       |
| Ключ                | orderId: UUID                     |
| Внутренние сущности | OrderItem                         |
| Value Objects       | ProductCode, Quantit, OrderStatus |

Инварианты:
1. Заказ содержит хотя бы одну позицию.
2. Количество больше 0 для каждой позиции.
3. Статус: Created -> Approved -> Delivered | Cancelled.

Публикуемые события:
- SupplyOrderCreated { orderId, items[], createdAt }
- SupplyOrderDelivered { orderId, deliveredAt }
- InventoryReplenished { productCode, quantity, warehouseId, replenishedAt }
- InventoryLow { productCode, currentQuantity, threshold, detectedAt }

## Сводная таблица агрегатов

| Домен       | Агрегат         | Ключ       | Основные инварианты                            | Кол-во событий |
|-------------|-----------------|------------|------------------------------------------------|----------------|
| Patient     | Patient         | patientId  | Согласие, обязательные поля, soft delete       | 5              |
| Clinical    | MedicalRecord   | recordId   | Привязка к пациенту, архивирование, ICD-10     | 3              |
| Clinical    | DiagnosticStudy | studyId    | Привязка к эпизоду, иммутабельность результата | 3              |
| AI Services | AIStudy         | aiStudyId  | Версия модели, confidence [0,1], аудит         | 4              |
| FinTech     | CreditContract  | contractId | Скоринг, статус-машина, график платежей        | 4              |
| FinTech     | Payment         | paymentId  | Иммутабельность, идемпотентность               | 3              |
| FinTech     | Account         | accountId  | Неотрицательный баланс, append-only            | 4              |
| Billing     | Invoice         | invoiceId  | Минимум 1 строка, статус-машина                | 3              |
| Staff       | Employee        | employeeId | Сертификации, непересечение смен               | 4              |
| Resources   | SupplyOrder     | orderId    | Минимум 1 позиция, quantity > 0                | 4              |
| Итого       | 10 агрегатов    |            |                                                | 37 событий     |