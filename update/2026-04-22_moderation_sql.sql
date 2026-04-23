# SQL: Модерация сборов

**Выполнить один раз в БД:**

```sql
-- 1. Добавить поле для причины отклонения
ALTER TABLE fundraisers ADD COLUMN IF NOT EXISTS rejection_reason TEXT;

-- 2. Индекс для быстрого поиска pending сборов
CREATE INDEX IF NOT EXISTS idx_fundraisers_status_pending ON fundraisers(status) WHERE status = 'pending';
```

**Готово!**

После этого перезапустить сервер. Модерация заработает:
- Новые сборы создаются со статусом `pending`
- Админ видит их в `/api/admin/fundraisers/pending`
- Админ может одобрить или отклонить