# Обновление бэкенда - Исправление статусов завершённых сборов

## 1. База данных

Всё готово, изменений не требуется.

## 2. Изменённые файлы

### backend/src/controllers/fundraiserController.js

**BUG FIX:** После верификации админ ставит статус `verified_completed`, но запрос искал `status = 'completed' AND completion_verified = true`.

Исправлено:

```js
// Было:
query += ` WHERE f.status = 'completed' AND f.completion_verified = true`;

// Стало:
query += ` WHERE f.status = 'verified_completed'`;
```

Также добавлено логирование для отладки:
- `getAllFundraisers called` - параметры запроса
- `getAllFundraisers result` - количество и данные

### backend/src/controllers/adminController.js

Добавлено логирование при верификации сбора:
- Логирует все данные сбора после подтверждения

## 3. Перезапустить сервер

```bash
cd backend
npm run dev
```

## 4. Проверить

Открыть "Завершённые" → должен показать верифицированные сборы → в деталке должна быть информация о подтверждении

## 2. Изменённые файлы

### backend/src/controllers/donationController.js

При одобрении доната добавлена проверка:

- Если `current_amount >= target_amount` → сбор автоматически закрывается (`status = 'completed'`)
- Автору отправляется уведомление
- Логирование события

### backend/src/middleware/upload.js

Добавлено расширенное логирование для отладки:

- Логируется размер файла, имя поля, оригинальное имя

### backend/src/routes/fundraisers.js

Добавлен middleware для логирования endpoint'а `/completion-proof`:

- Логирует `req.params`, `req.file`, `req.body` перед передачей в multer

## 3. Перезапустить сервер

```bash
cd backend
npm run dev
```

## 4. Тестирование

### Автозакрытие сбора:

1. Создать сбор с целью 1000₽
2. Подтвердить донат на 1000₽ (или сумму >= цель)
3. Сбор должен автоматически стать `status = 'completed'`
4. Автор получит уведомление "Сбор завершён! Теперь отправьте подтверждающие документы"

### Отправка подтверждения:

1. Открыть завершённый сбор в приложении
2. Нажать кнопку "Отправить подтверждение"
3. Прикрепить документ
4. Отправить на проверку
5. Смотреть логи сервера - там будет видно:
   - `Completion-proof endpoint hit: { files: {...}, body: {...} }`
   - `Multer: saving file to ./uploads { fieldname: 'proof', ... }`

### Возможные ошибки:

- `Необходимо прикрепить подтверждающий документ` → файл не дошёл до сервера
- Смотреть логи в консоли:
  - Есть ли `Completion-proof endpoint hit`?
  - Есть ли `Multer: saving file`?
  - Есть ли `Multer: filename`?

## 5. Отладка проблемы с загрузкой файла

Если в логах нет `Multer: saving file`, проблема на стороне клиента:

### Клиент (Flutter):

Проверить в `fundraiser_provider.dart`:

```dart
await ApiService.uploadFile(
  '${ApiConfig.fundraisers}/$fundraiserId/completion-proof',
  proofImagePath,  // Должен быть реальный путь к файлу
  'proof',      // Имя поля должно совпадать с сервером (proof)
  fields: fields,
  needsAuth: true,
);
```

**Важно:** Проверить что `proofImagePath` содержит реальный путь к файлу, а не null или пустую строку.

## 6. Исправление списка завершённых сборов

### backend/src/controllers/fundraiserController.js

Показывать завершённые сборы всех пользователей где есть подтверждение:

```js
// Для статуса completed (не verified_completed):
query += ` WHERE f.status = 'completed' AND (f.completion_proof_url IS NOT NULL OR f.completion_verified = true)`;
```

Это покажет сборы где:
- Автор отправил подтверждающие документы, ИЛИ
- Админ уже подтвердил завершение

### mobile/lib/providers/fundraiser_provider.dart

Запрос изменён на `?status=completed` (ранее был `verified_completed`).

### backend/src/controllers/fundraiserController.js - getMyFundraisers

Сортировка: завершённые сборы показываются первыми:

```js
ORDER BY f.status = 'completed' DESC, f.created_at DESC
```