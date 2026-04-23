# Инструкция для бэкенд-разработчика

## 1. Добавить колонку в БД

```sql
ALTER TABLE fundraisers ADD COLUMN IF NOT EXISTS image_urls TEXT[];
```

## 2. Изменённые файлы

### backend/src/middleware/upload.js
- Лимит файла: 5MB
- Добавлены логи

### backend/src/routes/fundraisers.js
- Изменено: `upload.single('image')` → `upload.array('images', 5)`

### backend/src/controllers/fundraiserController.js
- Обработка массива файлов: `req.files`
- Сохранение в поле `image_urls` (массив)
- Также сохраняется первый URL в `image_url` ( для совместимости)
- Добавлены логи для отладки

## 3. Перезапустить сервер

```bash
cd backend
npm start
```

## Тестирование

После запуска создать сбор с фотографиями - проверить в логах:
- Приходят ли файлы
- Какие URL генерируются
- Успешно ли сохраняются в БД