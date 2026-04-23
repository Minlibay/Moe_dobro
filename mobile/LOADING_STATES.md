# Loading States - Документация

## Новые компоненты для улучшенного UX

### 1. LoadingSkeleton (`lib/widgets/loading_skeleton.dart`)

**Skeleton loaders** - анимированные заглушки, которые показываются во время загрузки данных.

#### Компоненты:
- `FundraiserCardSkeleton` - skeleton для карточки сбора
- `LoadingSkeletonList` - список skeleton карточек

#### Использование:
```dart
// В списке сборов
if (provider.isLoading) {
  return const LoadingSkeletonList(itemCount: 5);
}
```

**Преимущества:**
- ✅ Пользователь видит структуру контента
- ✅ Shimmer эффект показывает, что идет загрузка
- ✅ Лучше, чем просто CircularProgressIndicator

---

### 2. LoadingOverlay (`lib/widgets/loading_overlay.dart`)

**Loading overlays** - модальные окна загрузки для длительных операций.

#### Компоненты:
- `LoadingOverlay` - полноэкранный overlay
- `LoadingDialog` - диалоговое окно загрузки

#### Использование:
```dart
// Показать loading dialog
LoadingDialog.show(context, message: 'Отправка пожертвования...');

// Выполнить операцию
await someAsyncOperation();

// Скрыть loading dialog
LoadingDialog.hide(context);
```

**Где используется:**
- ✅ Создание сбора
- ✅ Отправка пожертвования
- ✅ Загрузка файлов

**Преимущества:**
- ✅ Блокирует UI во время операции
- ✅ Показывает прогресс с сообщением
- ✅ Красивая анимация
- ✅ Предотвращает двойные клики

---

## Где применено:

### HomeScreen
- ✅ Skeleton loaders для списка сборов
- ✅ Skeleton loaders для "Мои сборы"
- ✅ Skeleton loaders для "Завершенные"

### FundraiserDetailScreen
- ✅ LoadingDialog при отправке доната

### CreateFundraiserScreen
- ✅ LoadingDialog при создании сбора

---

## Дизайн

### Цвета:
- Base color: `Colors.grey[300]`
- Highlight color: `Colors.grey[100]`
- Primary color: Theme primary

### Анимации:
- Shimmer эффект (1.5s)
- Scale animation для loading indicator
- Smooth transitions

---

## Будущие улучшения:

1. **Прогресс загрузки файлов** - показывать процент загрузки
2. **Skeleton для других экранов** - профиль, достижения
3. **Кастомные skeleton** - для разных типов контента
4. **Retry механизм** - кнопка повтора при ошибке
