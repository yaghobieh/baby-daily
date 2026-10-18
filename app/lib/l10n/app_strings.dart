class AppStrings {
  final String locale;
  const AppStrings(this.locale);

  bool get isHe => locale == 'he';

  // App & General
  String get appName => isHe ? 'בייבי דיילי' : 'BabyDaily';
  String get welcomeBack => isHe ? 'ברוכים השבים!' : 'Welcome Back!';
  String get loginSubtitle => isHe ? 'התחבר/י כדי לעקוב אחרי התינוק שלך ביחד' : 'Sign in to follow your baby\'s daily routine';
  String get createAccount => isHe ? 'יצירת חשבון' : 'Create Account';
  String get registerSubtitle => isHe ? 'התחל/י לשתף ולעקוב באהבה' : 'Start following and sharing with loved ones';
  String get login => isHe ? 'התחברות' : 'Sign In';
  String get register => isHe ? 'הרשמה' : 'Sign Up';
  String get logout => isHe ? 'התנתקות' : 'Sign Out';
  String get emailOrPhone => isHe ? 'אימייל או מספר טלפון' : 'Email or Phone number';
  String get email => isHe ? 'אימייל' : 'Email';
  String get phone => isHe ? 'מספר טלפון' : 'Phone Number';
  String get phoneOptional => isHe ? 'מספר טלפון (אופציונלי)' : 'Phone Number (Optional)';
  String get password => isHe ? 'סיסמה' : 'Password';
  String get fullName => isHe ? 'שם מלא' : 'Full Name';
  String get noAccount => isHe ? 'אין לך חשבון? הירשמ/י עכשיו' : 'Don\'t have an account? Sign up';
  String get hasAccount => isHe ? 'כבר יש לך חשבון? התחבר/י' : 'Already have an account? Sign in';
  String get cancel => isHe ? 'ביטול' : 'Cancel';
  String get save => isHe ? 'שמירה' : 'Save';
  String get delete => isHe ? 'מחיקה' : 'Delete';
  String get edit => isHe ? 'עריכה' : 'Edit';
  String get accept => isHe ? 'אישור' : 'Accept';
  String get decline => isHe ? 'דחייה' : 'Decline';
  String get confirm => isHe ? 'אישור' : 'Confirm';
  String get errorOccurred => isHe ? 'אירעה שגיאה. אנא נסה שנית.' : 'An error occurred. Please try again.';
  String get optional => isHe ? 'אופציונלי' : 'Optional';
  String get showAll => isHe ? 'הצג הכל' : 'Show All';
  String get selectDate => isHe ? 'בחר/י תאריך' : 'Select date';
  String get noneYet => isHe ? 'אין עדיין' : 'None yet';

  // Navigation
  String get navHome => isHe ? 'ראשי' : 'Today';
  String get navTimeline => isHe ? 'ציר זמן' : 'Timeline';
  String get navShare => isHe ? 'שיתוף' : 'Share';
  String get navReminders => isHe ? 'תזכורות' : 'Reminders';
  String get navNotifications => isHe ? 'התראות' : 'Alerts';
  String get navSettings => isHe ? 'הגדרות' : 'Settings';

  // Baby
  String get selectBaby => isHe ? 'בחר/י תינוק' : 'Select Baby';
  String get addBaby => isHe ? 'הוספת תינוק' : 'Add Baby';
  String get babyName => isHe ? 'שם התינוק/ת' : 'Baby\'s Name';
  String get birthDate => isHe ? 'תאריך לידה' : 'Birth Date';
  String get gender => isHe ? 'מין' : 'Gender';
  String get girl => isHe ? 'בת' : 'Girl';
  String get boy => isHe ? 'בן' : 'Boy';
  String get avatarColor => isHe ? 'צבע נושא לאפליקציה' : 'App Theme Color';
  String get noBabiesYet => isHe ? 'עדיין לא הוספת תינוק למעקב' : 'No babies added yet';

  // Entry types
  String get feed => isHe ? 'האכלה' : 'Feeding';
  String get sleep => isHe ? 'שינה' : 'Sleep';
  String get diaper => isHe ? 'חיתול' : 'Diaper';
  String get growth => isHe ? 'גדילה' : 'Growth';
  String get medicine => isHe ? 'תרופה' : 'Medicine';
  String get note => isHe ? 'הערה' : 'Note';

  // Summary labels
  String get todaySummary => isHe ? 'סיכום היום' : 'Today\'s Overview';
  String get feedsCount => isHe ? 'האכלות' : 'Feedings';
  String get totalSleep => isHe ? 'שעות שינה' : 'Sleep Total';
  String get diaperChanges => isHe ? 'חיתולים' : 'Diapers';
  String get currentlySleeping => isHe ? 'ישנ/ה כעת' : 'Sleeping Now';
  String get isAwake => isHe ? 'ער/ה כעת' : 'is awake';
  String get wakeUp => isHe ? 'התעורר/ה' : 'Wake Up';
  String get startSleep => isHe ? 'התחלת שינה' : 'Start Sleep';
  String get quickActions => isHe ? 'פעולות מהירות' : 'Quick Actions';
  String get recentActivity => isHe ? 'פעילות אחרונה' : 'Recent Activity';
  String get noEntriesToday => isHe ? 'עדיין אין רישומים להיום. לחץ/י על אחת הפעולות למעלה כדי להתחיל!' : 'No entries yet today. Tap a quick action above to start!';
  String get sleepAlertNotice => isHe ? 'המעקב מתחיל כעת. העוקבים יקבלו התראה מיידית כאשר התינוק יתעורר!' : 'Will start active sleep tracking now. Followers will receive an alert when the baby wakes up!';

  // Feeding details
  String get breast => isHe ? 'הנקה' : 'Breastfeeding';
  String get bottle => isHe ? 'בקבוק' : 'Bottle';
  String get solids => isHe ? 'מוצקים' : 'Solids';
  String get side => isHe ? 'צד' : 'Side';
  String get sideLeft => isHe ? 'שמאל' : 'Left';
  String get sideRight => isHe ? 'ימין' : 'Right';
  String get sideBoth => isHe ? 'שני הצדדים' : 'Both Sides';
  String get amountMl => isHe ? 'כמות (מ״ל)' : 'Amount (ml)';
  String get foodType => isHe ? 'סוג המזון (למשל: מחית בטטה)' : 'Food (e.g. sweet potato puree)';

  // Diaper details
  String get diaperWet => isHe ? 'רטוב' : 'Wet';
  String get diaperDirty => isHe ? 'מלוכלך' : 'Dirty';
  String get diaperMixed => isHe ? 'רטוב + מלוכלך' : 'Wet & Dirty';
  String get diaperDry => isHe ? 'יבש' : 'Dry';

  // Growth & Meds
  String get weightKg => isHe ? 'משקל (ק״ג)' : 'Weight (kg)';
  String get heightCm => isHe ? 'גובה (ס״מ)' : 'Height (cm)';
  String get headCm => isHe ? 'היקף ראש (ס״מ)' : 'Head (cm)';
  String get medicineName => isHe ? 'שם התרופה' : 'Medicine Name';
  String get medicineDose => isHe ? 'מינון (למשל: 2.5 מ״ל)' : 'Dose (e.g. 2.5 ml)';
  String get isVaccine => isHe ? 'חיסון' : 'Vaccination';
  String get notesPlaceholder => isHe ? 'הערות נוספות או תיאור...' : 'Add a note or observation...';

  // Sharing
  String get sharingTitle => isHe ? 'שיתוף ומעקב משותף' : 'Share & Caregivers';
  String get shareSubtitle => isHe ? 'שתף/י עם בן/בת זוג, מטפלת או סבא וסבתא לפי אימייל או טלפון' : 'Invite your partner, nanny, or grandparents by email or phone';
  String get inviteNew => isHe ? 'הזמנת שותף/ה חדש/ה' : 'Invite New Person';
  String get shareRole => isHe ? 'הרשאה' : 'Permission Role';
  String get roleOwner => isHe ? 'בעלים' : 'Owner';
  String get roleCaregiver => isHe ? 'מטפל/ת (רישום ועדכון)' : 'Caregiver (Can log entries)';
  String get roleViewer => isHe ? 'צופה בלבד (מעקב והתראות)' : 'Viewer (Read-only + Alerts)';
  String get sendInvite => isHe ? 'שליחת הזמנה' : 'Send Invitation';
  String get currentMembers => isHe ? 'חברים במעקב' : 'Current Followers';
  String get pendingInvites => isHe ? 'הזמנות ממתינות' : 'Pending Invitations';
  String get receivedInvites => isHe ? 'הזמנות שנשלחו אליך' : 'Invitations For You';
  String get invitedBy => isHe ? 'הוזמנת על ידי' : 'Invited by';
  String get inviteSentSuccess => isHe ? 'ההזמנה נשלחה בהצלחה!' : 'Invitation sent successfully!';
  String get revoke => isHe ? 'ביטול הזמנה' : 'Revoke';
  String get caregiverLabel => isHe ? 'מטפל/ת' : 'Caregiver';
  String get viewerLabel => isHe ? 'צופה' : 'Viewer';
  String get roleLabel => isHe ? 'תפקיד' : 'Role';

  // Reminders
  String get remindersTitle => isHe ? 'תזכורות חכמות' : 'Smart Reminders';
  String get addReminder => isHe ? 'הוספת תזכורת' : 'Add Reminder';
  String get reminderTitle => isHe ? 'כותרת התזכורת' : 'Reminder Title';
  String get reminderType => isHe ? 'סוג התזכורת' : 'Reminder Type';
  String get afterLastEntry => isHe ? 'לאחר הרישום האחרון' : 'After Last Event';
  String get dailyAtTime => isHe ? 'קבוע בכל יום בשעה' : 'Daily at Specific Time';
  String get hoursInterval => isHe ? 'מרווח שעות' : 'Hours Interval';
  String get timeOfDay => isHe ? 'שעה' : 'Time';
  String get noRemindersSet => isHe ? 'עדיין לא הוגדרו תזכורות' : 'No reminders set yet';
  String get remindersHelp => isHe ? 'הוסף/י תזכורת כמו: "האכלה כל 3 שעות מההאכלה האחרונה" או "טיפות ויטמין D בכל יום בשעה 10:00"' : 'Add reminders like "Feed every 3 hours after last feed" or "Vitamin drops daily at 10 AM"';
  String get everyHoursAfter => isHe ? 'כל {hours} שעות לאחר {type}' : 'Every {hours}h after last {type}';
  String get dailyAt => isHe ? 'בכל יום בשעה {time}' : 'Daily at {time}';

  // Notifications
  String get notificationsCenter => isHe ? 'מרכז התראות' : 'Alerts Inbox';
  String get markAllRead => isHe ? 'סמן הכל כנקרא' : 'Mark all read';
  String get noNotifications => isHe ? 'אין התראות חדשות' : 'No notifications yet';
  String get notificationsSubtitle => isHe ? 'עדכונים מהמטפלים, סיום שינה ותזכורות יופיעו כאן' : 'Updates, sleep alerts, and reminders will appear here';
  String get notifySettings => isHe ? 'הגדרות התראה אישיות' : 'Notification Preferences';
  String get enablePush => isHe ? 'קבלת התראות למכשיר' : 'Enable Notifications';
  String get enablePushSubtitle => isHe ? 'קבלת התראה מיידית כאשר שותף/ה אחר/ת רושם/ת אירוע' : 'Receive instant notifications when other caregivers log an event';
  String get quietHours => isHe ? 'שעות שקט (ללא התראות בלילה)' : 'Quiet Hours (Do not disturb)';

  // Testing Notifications
  String get testNotificationTitle => isHe ? 'בדיקת התראות למספר שלך' : 'Test Notification to Phone';
  String get testNotificationSubtitle => isHe ? 'שלח/י התראת ניסיון מיידית למספר הטלפון שלך או למכשיר הנוכחי' : 'Send an instant test alert to your phone number or current device';
  String get sendTestAlert => isHe ? 'שלח התראת בדיקה' : 'Send Test Alert';
  String get testAlertSentSuccess => isHe ? 'התראת הבדיקה נשלחה בהצלחה!' : 'Test alert sent successfully!';
  String get enterTestPhone => isHe ? 'מספר טלפון לבדיקה (למשל: 0501234567)' : 'Phone number for test (e.g. +972501234567)';

  // Settings & Theme
  String get language => isHe ? 'שפה / Language' : 'Language / שפה';
  String get serverUrl => isHe ? 'כתובת שרת API' : 'API Server URL';
  String get appThemeColor => isHe ? 'עיצוב צבעוני לאפליקציה' : 'Application Theme Color';
  String get appThemeSubtitle => isHe ? 'בחר/י צבע שיוחל על כל המסכים, הכפתורים והכרטיסים' : 'Pick a color applied across all screens, buttons, and cards';
  String get serverUrlUpdated => isHe ? 'כתובת השרת עודכנה' : 'Server URL updated';

  // Actions & Confirmations
  String get confirmDeleteEntryTitle => isHe ? 'מחיקת רשומה' : 'Delete Entry';
  String get confirmDeleteEntryContent => isHe ? 'האם למחוק רשומה זו משגרת היום?' : 'Are you sure you want to delete this routine entry?';
  String get confirmRemoveMemberTitle => isHe ? 'הסרת חבר/ה מהמעקב' : 'Remove Follower';
  String get confirmRemoveMemberContent => isHe ? 'האם להסיר משתמש/ת זה מהמעקב? הם לא יקבלו יותר התראות ולא יוכלו לצפות בשגרה.' : 'Are you sure you want to remove this person? They will no longer receive routine alerts.';
  String get confirmDeleteReminderTitle => isHe ? 'מחיקת תזכורת' : 'Delete Reminder';
  String get confirmDeleteReminderContent => isHe ? 'האם למחוק תזכורת זו?' : 'Are you sure you want to delete this reminder?';
  String get memberRemovedSuccess => isHe ? 'החבר/ה הוסר/ה בהצלחה' : 'Member removed successfully';
  String get entryDeletedSuccess => isHe ? 'הרשומה נמחקה בהצלחה' : 'Entry deleted successfully';
  String get reminderDeletedSuccess => isHe ? 'התזכורת נמחקה בהצלחה' : 'Reminder deleted successfully';
  String get addMemberAndNotify => isHe ? 'הוספת שותף/ה והפעלת התראות' : 'Add Follower & Enable Alerts';
  String get memberAddedAndNotified => isHe ? 'השותף/ה נוסף/ה בהצלחה ויקבל/י התראות!' : 'Follower added successfully and will receive routine alerts!';
  String get registeredEmailSent => isHe ? 'הרשמתך הושלמה בהצלחה! נשלח אימייל עם כל הפרטים.' : 'Registered successfully! An email with all details was sent.';

  // Export & Social Share
  String get exportData => isHe ? 'ייצוא דוחות' : 'Export Reports';
  String get exportSubtitle => isHe ? 'הורדת יומן הפעילות כקובץ אקסל, PDF או וורד' : 'Download activity logs as Excel, PDF, or Word';
  String get exportCsv => isHe ? 'גיליון אקסל (CSV)' : 'Excel Spreadsheet (CSV)';
  String get exportPdf => isHe ? 'דוח PDF להדפסה ולרופא ילדים' : 'Pediatric PDF Report';
  String get exportWord => isHe ? 'מסמך וורד (Word DOC)' : 'Word Document (DOC)';
  String get shareDailySummary => isHe ? 'שיתוף שגרת יום' : 'Share Routine';
  String get shareWhatsApp => isHe ? 'שיתוף ב-WhatsApp' : 'Share on WhatsApp';
  String get shareTelegram => isHe ? 'שיתוף ב-Telegram' : 'Share on Telegram';
  String get shareAll => isHe ? 'שליחה לכל הערוצים (התראה + WhatsApp + Telegram)' : 'Send to All Channels';
  String get shareSuccess => isHe ? 'הודעת השיתוף הוכנה ונשלחה בהצלחה!' : 'Share message sent successfully!';

  // Appearance & Channels
  String get appearance => isHe ? 'מראה ותצוגה' : 'Appearance';
  String get themeModeAuto => isHe ? 'לפי הגדרות המכשיר' : 'System Default';
  String get themeModeLight => isHe ? 'מצב בהיר ☀️' : 'Light Mode ☀️';
  String get themeModeDark => isHe ? 'מצב כהה 🌙' : 'Dark Mode 🌙';
  String get messagingChannels => isHe ? 'ערוצי שיתוף והודעות' : 'Messaging Channels';
  String get channelsSubtitle => isHe ? 'בחר/י באילו אפליקציות ברצונך לשתף או לקבל התראות' : 'Select which channels to enable for sharing and alerts';
  String get enableWhatsApp => isHe ? 'WhatsApp' : 'WhatsApp';
  String get enableWhatsAppSubtitle => isHe ? 'אפשר שיתוף קישורים והזמנות ישירות לוואטסאפ' : 'Enable sharing links and invitations via WhatsApp';
  String get enableTelegram => isHe ? 'Telegram' : 'Telegram';
  String get enableTelegramSubtitle => isHe ? 'אפשר שיתוף קישורים והזמנות ישירות לטלגרם' : 'Enable sharing links and invitations via Telegram';
  String get emailSentNice => isHe ? 'נשלח אימייל הזמנה מעוצב עם קישור כניסה!' : 'A formatted invitation email with an entry link was sent!';
  String get emailNotSentWarn => isHe ? 'ההזמנה נוצרה, אך שליחת האימייל לא הוגדרה בשרת.' : 'Invitation created, but email sending is not configured on the server.';
  String get memberAddedDirectly => isHe ? 'המשתמש/ת כבר קיים במערכת וצורף ישירות למעקב!' : 'User exists and was directly added to the baby tracker!';
}
