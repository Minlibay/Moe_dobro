class ErrorHandler {
  static String getErrorMessage(dynamic error) {
    final errorString = error.toString();

    // Убираем префикс "Exception: "
    if (errorString.startsWith('Exception: ')) {
      return errorString.substring(11);
    }

    // Обработка специфичных ошибок
    if (errorString.contains('SocketException') ||
        errorString.contains('Failed host lookup')) {
      return 'Нет подключения к интернету';
    }

    if (errorString.contains('TimeoutException')) {
      return 'Превышено время ожидания. Проверьте подключение';
    }

    if (errorString.contains('FormatException')) {
      return 'Ошибка формата данных';
    }

    // Возвращаем оригинальное сообщение
    return errorString;
  }

  static String getAuthErrorMessage(String? error) {
    if (error == null) return 'Неизвестная ошибка';

    final cleanError = getErrorMessage(error);

    // Специфичные ошибки авторизации
    if (cleanError.contains('Пользователь с таким номером уже существует')) {
      return 'Этот номер уже зарегистрирован. Попробуйте войти';
    }

    if (cleanError.contains('Пользователь не найден')) {
      return 'Пользователь не найден. Проверьте номер телефона';
    }

    if (cleanError.contains('Неверный пароль')) {
      return 'Неверный пароль. Попробуйте ещё раз';
    }

    if (cleanError.contains('Пароль должен содержать')) {
      return cleanError;
    }

    if (cleanError.contains('Слишком много')) {
      return cleanError;
    }

    if (cleanError.contains('Формат') || cleanError.contains('формат')) {
      return 'Неверный формат номера телефона';
    }

    return cleanError;
  }
}
