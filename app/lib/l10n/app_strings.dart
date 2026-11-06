class AppStrings {
  final String locale;
  const AppStrings(this.locale);

  bool get isHe => locale == 'he';
  bool get isEs => locale == 'es';
  bool get isRu => locale == 'ru';

  String tr({
    required String en,
    required String he,
    String? es,
    String? ru,
  }) {
    switch (locale) {
      case 'he':
        return he;
      case 'es':
        return es ?? en;
      case 'ru':
        return ru ?? en;
      default:
        return en;
    }
  }

  // App & General
  String get appName => tr(en: 'BabyDaily', he: 'בייבי דיילי', es: 'BabyDaily', ru: 'BabyDaily');
  String get welcomeBack => tr(en: 'Welcome Back!', he: 'ברוכים השבים!', es: '¡Bienvenido de nuevo!', ru: 'С возвращением!');
  String get loginSubtitle => tr(
        en: "Sign in to follow your baby's daily routine",
        he: 'התחבר/י כדי לעקוב אחרי התינוק שלך ביחד',
        es: 'Inicia sesión para seguir la rutina diaria de tu bebé',
        ru: 'Войдите, чтобы следить за режимом малыша вместе',
      );
  String get createAccount => tr(en: 'Create Account', he: 'יצירת חשבון', es: 'Crear cuenta', ru: 'Создать аккаунт');
  String get registerSubtitle => tr(
        en: 'Start following and sharing with loved ones',
        he: 'התחל/י לשתף ולעקוב באהבה',
        es: 'Comienza a seguir y compartir con tus seres queridos',
        ru: 'Начните вести дневник и делиться с близкими',
      );
  String get login => tr(en: 'Sign In', he: 'התחברות', es: 'Iniciar sesión', ru: 'Войти');
  String get register => tr(en: 'Sign Up', he: 'הרשמה', es: 'Registrarse', ru: 'Регистрация');
  String get logout => tr(en: 'Sign Out', he: 'התנתקות', es: 'Cerrar sesión', ru: 'Выйти');
  String get emailOrPhone => tr(en: 'Email or Phone number', he: 'אימייל או מספר טלפון', es: 'Correo o teléfono', ru: 'Email или телефон');
  String get email => tr(en: 'Email', he: 'אימייל', es: 'Correo electrónico', ru: 'Email');
  String get phone => tr(en: 'Phone Number', he: 'מספר טלפון', es: 'Número de teléfono', ru: 'Номер телефона');
  String get phoneOptional => tr(en: 'Phone Number (Optional)', he: 'מספר טלפון (אופציונלי)', es: 'Teléfono (Opcional)', ru: 'Телефон (необязательно)');
  String get password => tr(en: 'Password', he: 'סיסמה', es: 'Contraseña', ru: 'Пароль');
  String get fullName => tr(en: 'Full Name', he: 'שם מלא', es: 'Nombre completo', ru: 'Полное имя');
  String get noAccount => tr(en: "Don't have an account? Sign up", he: 'אין לך חשבון? הירשמ/י עכשיו', es: '¿No tienes cuenta? Regístrate', ru: 'Нет аккаунта? Зарегистрироваться');
  String get hasAccount => tr(en: 'Already have an account? Sign in', he: 'כבר יש לך חשבון? התחבר/י', es: '¿Ya tienes cuenta? Inicia sesión', ru: 'Уже есть аккаунт? Войти');
  String get cancel => tr(en: 'Cancel', he: 'ביטול', es: 'Cancelar', ru: 'Отмена');
  String get save => tr(en: 'Save', he: 'שמירה', es: 'Guardar', ru: 'Сохранить');
  String get delete => tr(en: 'Delete', he: 'מחיקה', es: 'Eliminar', ru: 'Удалить');
  String get edit => tr(en: 'Edit', he: 'עריכה', es: 'Editar', ru: 'Изменить');
  String get accept => tr(en: 'Accept', he: 'אישור', es: 'Aceptar', ru: 'Принять');
  String get decline => tr(en: 'Decline', he: 'דחייה', es: 'Rechazar', ru: 'Отклонить');
  String get confirm => tr(en: 'Confirm', he: 'אישור', es: 'Confirmar', ru: 'Подтвердить');
  String get errorOccurred => tr(en: 'An error occurred. Please try again.', he: 'אירעה שגיאה. אנא נסה שנית.', es: 'Ocurrió un error. Inténtalo de nuevo.', ru: 'Произошла ошибка. Попробуйте снова.');
  String get optional => tr(en: 'Optional', he: 'אופציונלי', es: 'Opcional', ru: 'Необязательно');
  String get showAll => tr(en: 'Show All', he: 'הצג הכל', es: 'Ver todo', ru: 'Показать все');
  String get selectDate => tr(en: 'Select date', he: 'בחר/י תאריך', es: 'Seleccionar fecha', ru: 'Выберите дату');
  String get noneYet => tr(en: 'None yet', he: 'אין עדיין', es: 'Nada aún', ru: 'Пока нет');

  // Navigation
  String get navHome => tr(en: 'Today', he: 'ראשי', es: 'Hoy', ru: 'Сегодня');
  String get navTimeline => tr(en: 'Timeline', he: 'ציר זמן', es: 'Historial', ru: 'Лента');
  String get navShare => tr(en: 'Share', he: 'שיתוף', es: 'Compartir', ru: 'Семья');
  String get navReminders => tr(en: 'Reminders', he: 'תזכורות', es: 'Alertas', ru: 'Будильник');
  String get navNotifications => tr(en: 'Alerts', he: 'התראות', es: 'Avisos', ru: 'Уведомления');
  String get navSettings => tr(en: 'Settings', he: 'הגדרות', es: 'Ajustes', ru: 'Настройки');

  // Baby
  String get selectBaby => tr(en: 'Select Baby', he: 'בחר/י תינוק', es: 'Seleccionar bebé', ru: 'Выберите малыша');
  String get addBaby => tr(en: 'Add Baby', he: 'הוספת תינוק', es: 'Añadir bebé', ru: 'Добавить малыша');
  String get babyName => tr(en: "Baby's Name", he: 'שם התינוק/ת', es: 'Nombre del bebé', ru: 'Имя малыша');
  String get birthDate => tr(en: 'Birth Date', he: 'תאריך לידה', es: 'Fecha de nacimiento', ru: 'Дата рождения');
  String get gender => tr(en: 'Gender', he: 'מין', es: 'Género', ru: 'Пол');
  String get girl => tr(en: 'Girl', he: 'בת', es: 'Niña', ru: 'Девочка');
  String get boy => tr(en: 'Boy', he: 'בן', es: 'Niño', ru: 'Мальчик');
  String get avatarColor => tr(en: 'App Theme Color', he: 'צבע נושא לאפליקציה', es: 'Color del tema', ru: 'Цвет темы');
  String get noBabiesYet => tr(en: 'No babies added yet', he: 'עדיין לא הוספת תינוק למעקב', es: 'Aún no has añadido un bebé', ru: 'Малыш еще не добавлен');

  // Entry types
  String get feed => tr(en: 'Feeding', he: 'האכלה', es: 'Comida', ru: 'Кормление');
  String get sleep => tr(en: 'Sleep', he: 'שינה', es: 'Sueño', ru: 'Сон');
  String get diaper => tr(en: 'Diaper', he: 'חיתול', es: 'Pañal', ru: 'Подгузник');
  String get growth => tr(en: 'Growth', he: 'גדילה', es: 'Crecimiento', ru: 'Рост');
  String get medicine => tr(en: 'Medicine', he: 'תרופה', es: 'Medicina', ru: 'Лекарство');
  String get note => tr(en: 'Note', he: 'הערה', es: 'Nota', ru: 'Заметка');

  // Summary labels
  String get todaySummary => tr(en: "Today's Overview", he: 'סיכום היום', es: 'Resumen de hoy', ru: 'Сводка за сегодня');
  String get feedsCount => tr(en: 'Feedings', he: 'האכלות', es: 'Comidas', ru: 'Кормления');
  String get totalSleep => tr(en: 'Sleep Total', he: 'שעות שינה', es: 'Sueño total', ru: 'Всего сна');
  String get diaperChanges => tr(en: 'Diapers', he: 'חיתולים', es: 'Pañales', ru: 'Подгузники');
  String get currentlySleeping => tr(en: 'Sleeping Now', he: 'ישנ/ה כעת', es: 'Durmiendo ahora', ru: 'Сейчас спит');
  String get isAwake => tr(en: 'is awake', he: 'ער/ה כעת', es: 'está despierto', ru: 'бодрствует');
  String get wakeUp => tr(en: 'Wake Up', he: 'התעורר/ה', es: 'Despertar', ru: 'Проснулся');
  String get startSleep => tr(en: 'Start Sleep', he: 'התחלת שינה', es: 'Iniciar sueño', ru: 'Начать сон');
  String get quickActions => tr(en: 'Quick Actions', he: 'פעולות מהירות', es: 'Acciones rápidas', ru: 'Быстрые действия');
  String get recentActivity => tr(en: 'Recent Activity', he: 'פעילות אחרונה', es: 'Actividad reciente', ru: 'Недавние записи');
  String get noEntriesToday => tr(
        en: 'No entries yet today. Tap a quick action above to start!',
        he: 'עדיין אין רישומים להיום. לחץ/י על אחת הפעולות למעלה כדי להתחיל!',
        es: 'Aún no hay registros hoy. ¡Toca una acción rápida arriba!',
        ru: 'Сегодня записей еще нет. Нажмите на действие выше, чтобы начать!',
      );
  String get sleepAlertNotice => tr(
        en: 'Will start active sleep tracking now. Followers will receive an alert when the baby wakes up!',
        he: 'המעקב מתחיל כעת. העוקבים יקבלו התראה מיידית כאשר התינוק יתעורר!',
        es: 'Iniciará el seguimiento del sueño. ¡Los seguidores recibirán una alerta cuando despierte!',
        ru: 'Отслеживание сна начнется сейчас. Семья получит уведомление, когда малыш проснется!',
      );

  // Feeding details
  String get breast => tr(en: 'Breastfeeding', he: 'הנקה', es: 'Pecho', ru: 'Грудь');
  String get bottle => tr(en: 'Bottle', he: 'בקבוק', es: 'Biberón', ru: 'Бутылочка');
  String get solids => tr(en: 'Solids', he: 'מוצקים', es: 'Sólidos', ru: 'Прикорм');
  String get side => tr(en: 'Side', he: 'צד', es: 'Lado', ru: 'Сторона');
  String get sideLeft => tr(en: 'Left', he: 'שמאל', es: 'Izquierdo', ru: 'Левая');
  String get sideRight => tr(en: 'Right', he: 'ימין', es: 'Derecho', ru: 'Правая');
  String get sideBoth => tr(en: 'Both Sides', he: 'שני הצדדים', es: 'Ambos lados', ru: 'Обе');
  String get amountMl => tr(en: 'Amount (ml)', he: 'כמות (מ״ל)', es: 'Cantidad (ml)', ru: 'Объем (мл)');
  String get foodType => tr(en: 'Food (e.g. sweet potato puree)', he: 'סוג המזון (למשל: מחית בטטה)', es: 'Alimento (ej. puré)', ru: 'Еда (например, пюре)');

  // Diaper details
  String get diaperWet => tr(en: 'Wet', he: 'רטוב', es: 'Mojado', ru: 'Мокрый');
  String get diaperDirty => tr(en: 'Dirty', he: 'מלוכלך', es: 'Sucio', ru: 'Грязный');
  String get diaperMixed => tr(en: 'Wet & Dirty', he: 'רטוב + מלוכלך', es: 'Ambos', ru: 'Смешанный');
  String get diaperDry => tr(en: 'Dry', he: 'יבש', es: 'Seco', ru: 'Сухой');

  // Growth & Meds
  String get weightKg => tr(en: 'Weight (kg)', he: 'משקל (ק״ג)', es: 'Peso (kg)', ru: 'Вес (кг)');
  String get heightCm => tr(en: 'Height (cm)', he: 'גובה (ס״מ)', es: 'Altura (cm)', ru: 'Рост (см)');
  String get headCm => tr(en: 'Head (cm)', he: 'היקף ראש (ס״מ)', es: 'Cabeza (cm)', ru: 'Голова (см)');
  String get medicineName => tr(en: 'Medicine Name', he: 'שם התרופה', es: 'Nombre de medicina', ru: 'Название лекарства');
  String get medicineDose => tr(en: 'Dose (e.g. 2.5 ml)', he: 'מינון (למשל: 2.5 מ״ל)', es: 'Dosis (ej. 2.5 ml)', ru: 'Доза (напр. 2.5 мл)');
  String get isVaccine => tr(en: 'Vaccination', he: 'חיסון', es: 'Vacuna', ru: 'Прививка');
  String get notesPlaceholder => tr(en: 'Add a note or observation...', he: 'הערות נוספות או תיאור...', es: 'Añadir una nota...', ru: 'Добавьте заметку...');

  // Sharing
  String get sharingTitle => tr(en: 'Share & Caregivers', he: 'שיתוף ומעקב משותף', es: 'Compartir y Cuidadores', ru: 'Семья и доступ');
  String get shareSubtitle => tr(
        en: 'Invite your partner, nanny, or grandparents by email — they will receive an invitation email',
        he: 'הזמן/י בן/בת זוג, מטפלת או סבא וסבתא באימייל — הם יקבלו אימייל הצטרפות',
        es: 'Invita a tu pareja, niñera o abuelos por correo — recibirán un email de invitación',
        ru: 'Пригласите партнера, няню или бабушку по email — они получат письмо с приглашением',
      );
  String get inviteNew => tr(en: 'Invite New Member by Email', he: 'הוספת שותף/ה חדש/ה באימייל', es: 'Invitar miembro por correo', ru: 'Пригласить участника по Email');
  String get shareRole => tr(en: 'Permission Role', he: 'הרשאה', es: 'Rol de permiso', ru: 'Роль доступа');
  String get roleOwner => tr(en: 'Owner', he: 'בעלים', es: 'Propietario', ru: 'Владелец');
  String get roleCaregiver => tr(en: 'Caregiver (Can log entries)', he: 'מטפל/ת (רישום ועדכון)', es: 'Cuidador (puede registrar)', ru: 'Помощник (может добавлять)');
  String get roleViewer => tr(en: 'Viewer (Read-only + Alerts)', he: 'צופה בלבד (מעקב והתראות)', es: 'Lector (solo ver + alertas)', ru: 'Наблюдатель (только чтение)');
  String get sendInvite => tr(en: 'Send Email Invitation', he: 'שלח הזמנה באימייל', es: 'Enviar invitación por correo', ru: 'Отправить приглашение по Email');
  String get currentMembers => tr(en: 'Current Followers', he: 'חברים במעקב', es: 'Miembros actuales', ru: 'Текущие участники');
  String get pendingInvites => tr(en: 'Pending Invitations', he: 'הזמנות ממתינות', es: 'Invitaciones pendientes', ru: 'Ожидающие приглашения');
  String get receivedInvites => tr(en: 'Invitations For You', he: 'הזמנות שנשלחו אליך', es: 'Invitaciones para ti', ru: 'Приглашения для вас');
  String get invitedBy => tr(en: 'Invited by', he: 'הוזמנת על ידי', es: 'Invitado por', ru: 'Пригласил(а)');
  String get inviteSentSuccess => tr(en: 'Invitation email sent successfully!', he: 'אימייל ההזמנה נשלח בהצלחה!', es: '¡Correo de invitación enviado!', ru: 'Письмо с приглашением отправлено!');
  String get revoke => tr(en: 'Revoke', he: 'ביטול הזמנה', es: 'Revocar', ru: 'Отозвать');
  String get caregiverLabel => tr(en: 'Caregiver', he: 'מטפל/ת', es: 'Cuidador', ru: 'Помощник');
  String get viewerLabel => tr(en: 'Viewer', he: 'צופה', es: 'Lector', ru: 'Наблюдатель');
  String get roleLabel => tr(en: 'Role', he: 'תפקיד', es: 'Rol', ru: 'Роль');

  // Reminders & Phone Clock Alarms
  String get remindersTitle => tr(en: 'Smart Reminders & Phone Alarms', he: 'תזכורות ושעון מעורר בנייד', es: 'Recordatorios y Alarmas', ru: 'Напоминания и будильник');
  String get addReminder => tr(en: 'Add Reminder / Alarm', he: 'הוספת תזכורת / שעון מעורר', es: 'Añadir recordatorio / alarma', ru: 'Добавить будильник');
  String get reminderTitle => tr(en: 'Reminder Title', he: 'כותרת התזכורת', es: 'Título del recordatorio', ru: 'Название напоминания');
  String get reminderType => tr(en: 'Reminder Type', he: 'סוג התזכורת', es: 'Tipo de recordatorio', ru: 'Тип напоминания');
  String get afterLastEntry => tr(en: 'After Last Event', he: 'לאחר הרישום האחרון', es: 'Después del último', ru: 'После последней записи');
  String get dailyAtTime => tr(en: 'Daily at Specific Time', he: 'קבוע בכל יום בשעה', es: 'Diario a una hora', ru: 'Ежедневно в указанное время');
  String get hoursInterval => tr(en: 'Hours Interval', he: 'מרווח שעות', es: 'Intervalo de horas', ru: 'Интервал (часы)');
  String get timeOfDay => tr(en: 'Time', he: 'שעה', es: 'Hora', ru: 'Время');
  String get noRemindersSet => tr(en: 'No reminders set yet', he: 'עדיין לא הוגדרו תזכורות', es: 'No hay recordatorios aún', ru: 'Напоминаний пока нет');
  String get remindersHelp => tr(
        en: 'Set a phone clock alarm or smart reminder for the next meal, sleep, or medicine',
        he: 'כוון/י שעון מעורר בנייד או תזכורת חכמה להאכלה הבאה, שינה או תרופה',
        es: 'Configura una alarma en el reloj del teléfono para la próxima comida o medicina',
        ru: 'Установите будильник на телефоне или напоминание о следующем кормлении или лекарстве',
      );
  String get everyHoursAfter => tr(en: 'Every {hours}h after last {type}', he: 'כל {hours} שעות לאחר {type}', es: 'Cada {hours}h tras {type}', ru: 'Каждые {hours}ч после {type}');
  String get dailyAt => tr(en: 'Daily at {time}', he: 'בכל יום בשעה {time}', es: 'Diario a las {time}', ru: 'Ежедневно в {time}');
  String get setPhoneClockAlarm => tr(
        en: 'Set Phone Clock Alarm for Next Meal',
        he: 'כוון שעון מעורר בנייד לארוחה הבאה',
        es: 'Poner alarma en el teléfono para la próxima comida',
        ru: 'Поставить будильник на следующее кормление',
      );
  String get alarmSetSuccess => tr(
        en: 'Phone clock alarm & notification scheduled!',
        he: 'שעון מעורר והתראה בנייד הופעלו בהצלחה!',
        es: '¡Alarma y notificación programadas en el teléfono!',
        ru: 'Будильник и уведомление на телефоне установлены!',
      );

  // Notifications
  String get notificationsCenter => tr(en: 'Alerts Inbox', he: 'מרכז התראות', es: 'Centro de alertas', ru: 'Центр уведомлений');
  String get markAllRead => tr(en: 'Mark all read', he: 'סמן הכל כנקרא', es: 'Marcar todo leído', ru: 'Прочитать все');
  String get noNotifications => tr(en: 'No notifications yet', he: 'אין התראות חדשות', es: 'No hay notificaciones', ru: 'Уведомлений пока нет');
  String get notificationsSubtitle => tr(
        en: 'Updates, sleep alerts, and reminders will appear here',
        he: 'עדכונים מהמטפלים, סיום שינה ותזכורות יופיעו כאן',
        es: 'Actualizaciones, alertas de sueño y recordatorios aparecerán aquí',
        ru: 'Обновления, уведомления о сне и напоминания появятся здесь',
      );
  String get notifySettings => tr(en: 'Notification Preferences', he: 'הגדרות התראה אישיות', es: 'Preferencias de notificación', ru: 'Настройки уведомлений');
  String get enablePush => tr(
        en: 'Enable Notifications on This Phone',
        he: 'הפעל התראות במכשיר הנוכחי',
        es: 'Activar notificaciones en este teléfono',
        ru: 'Включить уведомления на этом телефоне',
      );
  String get enablePushSubtitle => tr(
        en: 'Receive instant phone notifications for meals, sleep, and caregiver updates',
        he: 'קבלת התראות מיידיות בנייד הנוכחי עבור ארוחות, שינה ועדכוני שותפים',
        es: 'Recibe notificaciones instantáneas en este teléfono sobre comidas y sueño',
        ru: 'Получайте мгновенные уведомления на этот телефон о кормлении и сне',
      );
  String get quietHours => tr(en: 'Quiet Hours (Do not disturb)', he: 'שעות שקט (ללא התראות בלילה)', es: 'Horas de silencio', ru: 'Тихие часы');

  // Testing Notifications
  String get testNotificationTitle => tr(en: 'Current Phone Notifications', he: 'התראות במכשיר הנוכחי', es: 'Notificaciones en este teléfono', ru: 'Уведомления на этом телефоне');
  String get testNotificationSubtitle => tr(
        en: 'Send an instant test alert to this phone to verify sound and notifications',
        he: 'שלח/י התראת בדיקה מיידית למכשיר הנוכחי שלך',
        es: 'Envía una alerta de prueba instantánea a este teléfono',
        ru: 'Отправьте тестовое уведомление на этот телефон',
      );
  String get sendTestAlert => tr(en: 'Test Notification on This Phone', he: 'בדיקת התראה במכשיר זה', es: 'Probar notificación en este teléfono', ru: 'Проверить уведомление на телефоне');
  String get testAlertSentSuccess => tr(en: 'Notification triggered on your phone!', he: 'ההתראה הופעלה במכשיר שלך בהצלחה!', es: '¡Notificación enviada a tu teléfono!', ru: 'Уведомление отправлено на ваш телефон!');
  String get enterTestPhone => tr(en: 'Email address', he: 'כתובת אימייל', es: 'Correo electrónico', ru: 'Электронная почта');

  // Settings & Theme
  String get language => tr(en: 'Language', he: 'שפה', es: 'Idioma', ru: 'Язык');
  String get serverUrl => tr(en: 'API Server URL', he: 'כתובת שרת API', es: 'URL del servidor', ru: 'URL сервера');
  String get appThemeColor => tr(en: 'Application Theme Color', he: 'עיצוב צבעוני לאפליקציה', es: 'Color del tema', ru: 'Цвет оформления');
  String get appThemeSubtitle => tr(
        en: 'Pick a color applied across all screens, buttons, and cards',
        he: 'בחר/י צבע שיוחל על כל המסכים, הכפתורים והכרטיסים',
        es: 'Elige un color para todas las pantallas y botones',
        ru: 'Выберите основной цвет приложения',
      );
  String get serverUrlUpdated => tr(en: 'Server URL updated', he: 'כתובת השרת עודכנה', es: 'Servidor actualizado', ru: 'URL сервера обновлен');

  // Actions & Confirmations
  String get confirmDeleteEntryTitle => tr(en: 'Delete Entry', he: 'מחיקת רשומה', es: 'Eliminar registro', ru: 'Удалить запись');
  String get confirmDeleteEntryContent => tr(en: 'Are you sure you want to delete this routine entry?', he: 'האם למחוק רשומה זו משגרת היום?', es: '¿Seguro que deseas eliminar este registro?', ru: 'Вы уверены, что хотите удалить эту запись?');
  String get confirmRemoveMemberTitle => tr(en: 'Remove Follower', he: 'הסרת חבר/ה מהמעקב', es: 'Eliminar miembro', ru: 'Удалить участника');
  String get confirmRemoveMemberContent => tr(
        en: 'Are you sure you want to remove this person? They will no longer receive routine alerts.',
        he: 'האם להסיר משתמש/ת זה מהמעקב? הם לא יקבלו יותר התראות ולא יוכלו לצפות בשגרה.',
        es: '¿Seguro que deseas eliminar a esta persona?',
        ru: 'Вы уверены, что хотите удалить этого участника?',
      );
  String get confirmDeleteReminderTitle => tr(en: 'Delete Reminder', he: 'מחיקת תזכורת', es: 'Eliminar recordatorio', ru: 'Удалить напоминание');
  String get confirmDeleteReminderContent => tr(en: 'Are you sure you want to delete this reminder?', he: 'האם למחוק תזכורת זו?', es: '¿Seguro que deseas eliminar este recordatorio?', ru: 'Удалить это напоминание?');
  String get memberRemovedSuccess => tr(en: 'Member removed successfully', he: 'החבר/ה הוסר/ה בהצלחה', es: 'Miembro eliminado', ru: 'Участник удален');
  String get entryDeletedSuccess => tr(en: 'Entry deleted', he: 'הרשומה נמחקה', es: 'Registro eliminado', ru: 'Запись удалена');
  String get reminderDeletedSuccess => tr(en: 'Reminder deleted successfully', he: 'התזכורת נמחקה בהצלחה', es: 'Recordatorio eliminado', ru: 'Напоминание удалено');
  String get addMemberAndNotify => tr(en: 'Add Member by Email', he: 'הוספת שותף/ה באימייל', es: 'Añadir miembro por correo', ru: 'Добавить участника по Email');
  String get memberAddedAndNotified => tr(en: 'Member invited and notified by email!', he: 'השותף/ה הוזמן/ה וקיבל/ה אימייל!', es: '¡Miembro invitado por correo!', ru: 'Участник приглашен по электронной почте!');
  String get registeredEmailSent => tr(en: 'Registered successfully! An email with all details was sent.', he: 'הרשמתך הושלמה בהצלחה! נשלח אימייל עם כל הפרטים.', es: '¡Registrado con éxito!', ru: 'Регистрация успешна!');
  String get swipeRightToDeleteHint => tr(
        en: 'Tip: Slide any item to the right to delete it',
        he: 'טיפ: החלק/י פריט ימינה כדי למחוק אותו',
        es: 'Consejo: Desliza un elemento a la derecha para eliminarlo',
        ru: 'Совет: проведите по записи вправо, чтобы удалить её',
      );

  // Export & Social Share
  String get exportData => tr(en: 'Export Reports', he: 'ייצוא דוחות', es: 'Exportar informes', ru: 'Экспорт отчетов');
  String get exportSubtitle => tr(en: 'Download activity logs as Excel, PDF, or Word', he: 'הורדת יומן הפעילות כקובץ אקסל, PDF או וורד', es: 'Descargar historial en Excel o PDF', ru: 'Скачать журнал в Excel или PDF');
  String get exportCsv => tr(en: 'Excel Spreadsheet (CSV)', he: 'גיליון אקסל (CSV)', es: 'Hoja de cálculo Excel (CSV)', ru: 'Таблица Excel (CSV)');
  String get exportPdf => tr(en: 'Pediatric PDF Report', he: 'דוח PDF להדפסה ולרופא ילדים', es: 'Informe PDF pediátrico', ru: 'PDF-отчет для педиатра');
  String get exportWord => tr(en: 'Word Document (DOC)', he: 'מסמך וורד (Word DOC)', es: 'Documento Word (DOC)', ru: 'Документ Word (DOC)');
  String get shareDailySummary => tr(en: 'Share Routine', he: 'שיתוף שגרת יום', es: 'Compartir rutina', ru: 'Поделиться режимом');
  String get shareWhatsApp => tr(en: 'Share on WhatsApp', he: 'שיתוף ב-WhatsApp', es: 'Compartir en WhatsApp', ru: 'Поделиться в WhatsApp');
  String get shareTelegram => tr(en: 'Share on Telegram', he: 'שיתוף ב-Telegram', es: 'Compartir en Telegram', ru: 'Поделиться в Telegram');
  String get shareAll => tr(en: 'Send to All Channels', he: 'שליחה לכל הערוצים', es: 'Enviar a todos', ru: 'Отправить всем');
  String get shareSuccess => tr(en: 'Share message sent successfully!', he: 'הודעת השיתוף הוכנה ונשלחה בהצלחה!', es: '¡Mensaje compartido!', ru: 'Сообщение отправлено!');

  // Appearance & Channels
  String get appearance => tr(en: 'Appearance', he: 'מראה ותצוגה', es: 'Apariencia', ru: 'Внешний вид');
  String get themeModeAuto => tr(en: 'System Default', he: 'לפי הגדרות המכשיר', es: 'Automático', ru: 'Системная');
  String get themeModeLight => tr(en: 'Light Mode ☀️', he: 'מצב בהיר ☀️', es: 'Modo claro ☀️', ru: 'Светлая ☀️');
  String get themeModeDark => tr(en: 'Dark Mode 🌙', he: 'מצב כהה 🌙', es: 'Modo oscuro 🌙', ru: 'Темная 🌙');
  String get messagingChannels => tr(en: 'Phone Notifications & Email Invites', he: 'התראות בנייד והזמנת שותפים באימייל', es: 'Notificaciones e invitaciones por correo', ru: 'Уведомления и приглашения по Email');
  String get channelsSubtitle => tr(en: 'Manage notifications on this phone and invite family members via email', he: 'הפעל/י התראות במכשיר זה והזמן/י בני משפחה באימייל', es: 'Activa notificaciones e invita familiares por correo', ru: 'Настройте уведомления на телефоне и пригласите близких по Email');
  String get enableWhatsApp => tr(en: 'WhatsApp', he: 'WhatsApp');
  String get enableWhatsAppSubtitle => tr(en: 'Enable sharing via WhatsApp', he: 'אפשר שיתוף בוואטסאפ');
  String get enableTelegram => tr(en: 'Telegram', he: 'Telegram');
  String get enableTelegramSubtitle => tr(en: 'Enable sharing via Telegram', he: 'אפשר שיתוף בטלגרם');
  String get emailSentNice => tr(en: 'An invitation email with a join link was sent!', he: 'נשלח אימייל הזמנה מעוצב עם קישור הצטרפות!', es: '¡Se envió un correo de invitación con enlace!', ru: 'Письмо с приглашением отправлено!');
  String get emailNotSentWarn => tr(en: 'Invitation created! Opening email app to send the invite link directly.', he: 'ההזמנה נוצרה! נשלח אימייל הצטרפות לחבר החדש.', es: '¡Invitación creada y enviada por correo!', ru: 'Приглашение создано и отправлено по Email!');
  String get memberAddedDirectly => tr(en: 'Member added to the baby tracker and notified by email!', he: 'השותף/ה צורף/ה למעקב וקיבל/ה הודעה באימייל!', es: '¡Miembro añadido y notificado por correo!', ru: 'Участник добавлен и уведомлен по Email!');

  // Tagging & Caregiver with Baby
  String get whoIsWithBaby => tr(en: 'Who is with the baby?', he: 'מי נמצא/ת עם התינוק/ת?', es: '¿Quién está con el bebé?', ru: 'Кто сейчас с малышом?');
  String get tagCaregiver => tr(en: 'Tag Caregiver', he: 'תיוג שותף/ה', es: 'Etiquetar cuidador', ru: 'Отметить помощника');
  String get withPerson => tr(en: 'With', he: 'ביחד עם', es: 'Con', ru: 'Вместе с');
  String get assignReminderTo => tr(en: 'Assign reminder to', he: 'שיוך תזכורת אל', es: 'Asignar a', ru: 'Назначить');
  String get nobodyTagged => tr(en: 'None', he: 'ללא שיוך', es: 'Nadie', ru: 'Никто');
  String get notifyViaWhatsApp => tr(en: 'Send update via WhatsApp', he: 'שליחת עדכון ב-WhatsApp');
  String get whatsappShareAction => tr(en: 'Share on WhatsApp', he: 'שיתוף פעולה ב-WhatsApp');

  // Password Recovery
  String get forgotPassword => tr(en: 'Forgot password?', he: 'שכחת סיסמה?', es: '¿Olvidaste tu contraseña?', ru: 'Забыли пароль?');
  String get forgotPasswordTitle => tr(en: 'Reset Password', he: 'איפוס סיסמה', es: 'Restablecer contraseña', ru: 'Сброс пароля');
  String get forgotPasswordSubtitle => tr(
        en: 'Enter your email or phone and we will send a secure password reset link.',
        he: 'הזן/י את כתובת האימייל או הטלפון שלך ונשלח אליך קישור מאובטח לאיפוס הסיסמה.',
        es: 'Ingresa tu correo y te enviaremos un enlace para restablecer tu contraseña.',
        ru: 'Введите ваш email, и мы отправим ссылку для сброса пароля.',
      );
  String get sendResetLink => tr(en: 'Send Reset Link', he: 'שליחת קישור איפוס', es: 'Enviar enlace', ru: 'Отправить ссылку');
  String get resetLinkSentTitle => tr(en: 'Link Sent!', he: 'הקישור נשלח!', es: '¡Enlace enviado!', ru: 'Ссылка отправлена!');
  String get resetLinkSentMessage => tr(
        en: 'If your account is registered, a password reset email has been dispatched.',
        he: 'אם החשבון קיים במערכת, נשלח אימייל מעוצב עם קישור לאיפוס הסיסמה.',
        es: 'Si tu cuenta está registrada, hemos enviado un correo de recuperación.',
        ru: 'Если аккаунт существует, письмо для сброса пароля отправлено.',
      );
  String get backToLogin => tr(en: 'Back to Login', he: 'חזרה להתחברות', es: 'Volver al inicio', ru: 'Назад ко входу');
}
