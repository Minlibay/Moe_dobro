# Множественные фото для сбора

**Дата:** 22.04.2026

## Задача

Allow up to 5 photos per fundraiser.

## Backend изменения

### 1. База данных - добавить новое поле

```sql
-- Добавить массив изображений (или новое поле image_urls)
ALTER TABLE fundraisers ADD COLUMN IF NOT EXISTS image_urls TEXT[];

-- Или создать отдельную таблицу
CREATE TABLE fundraiser_images (
  id SERIAL PRIMARY KEY,
  fundraiser_id INTEGER REFERENCES fundraisers(id),
  image_url TEXT NOT NULL,
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_fundraiser_images_fundraiser_id ON fundraiser_images(fundraiser_id);
```

### 2. FundraiserController.js -修改 создания

```javascript
// При создании - обрабатывать массив файлов
// req.files теперь массив, а не один файл

// Вставить все изображения
for (const file of req.files) {
  await client.query(
    `INSERT INTO fundraiser_images (fundraiser_id, image_url, sort_order)
     VALUES ($1, $2, $3)`,
    [result.rows[0].id, `/uploads/${file.filename}`, index]
  );
}
```

### 3. API - получить изображения

```javascript
// GET /api/fundraisers/:id 返回:
{
  ...,
  images: [
    { id: 1, url: '/uploads/img1.jpg', sort_order: 0 },
    { id: 2, url: '/uploads/img2.jpg', sort_order: 1 },
    ...
  ]
}
```

### 4. Admin - редактировать

```javascript
// POST /api/admin/fundraisers/:id/images
// PUT /api/admin/fundraisers/:id/images/:imageId
// DELETE /api/admin/fundraisers/:id/images/:imageId
```

## Flutter изменения

### 1. Модель Fundraiser

```dart
// Добавить поле для массива изображений
final List<String>? imageUrls;
```

### 2. CreateFundraiserScreen

- Изменить ImagePicker на множественный выбор
- Показывать до 5 превью
- Кнопка "Добавить ещё фото" (до 5)

### 3. FundraiserDetailScreen

- Показывать первую фото как главную
- Прокрутка (carousel) для остальных
- Tap по фото = открыть на весь экран (Hero animation)

### 4. FundraiserCard widget

- Показывать только первое фото (квадратное превью)