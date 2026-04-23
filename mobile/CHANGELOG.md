# Changelog - Моё добро

## [1.0.0] - 2026-04-22

### ✅ Исправлено
- Исправлена загрузка файлов на мобильных устройствах (Android/iOS)
- Исправлена ошибка "Type 'string' is not a subtype of type 'file'"
- Заменены все `print` на Logger для правильного логирования
- Исправлены deprecated методы `withOpacity` → `withValues`
- Исправлен deprecated `value` → `initialValue` в TextFormField
- Удалены неиспользуемые импорты
- Исправлен null comparison warning

### 🎨 Улучшено
- Название приложения изменено на "Моё добро"
- Установлена новая иконка приложения
- Adaptive icon для Android с фиолетовым фоном (#6C63FF)
- Создан Logger utility (`lib/utils/logger.dart`)

### 📊 Статистика
- Warnings: 47 → 22 (сокращено на 53%)
- Поддержка платформ: Android, iOS, Web, Windows, macOS, Linux

### 🔧 Технические детали
- Добавлена проверка платформы для загрузки файлов (kIsWeb)
- Для мобильных: используется `MultipartFile.fromPath()`
- Для веб: используется `MultipartFile.fromBytes()`
- Поддержка форматов: JPG, JPEG, PNG, WEBP
