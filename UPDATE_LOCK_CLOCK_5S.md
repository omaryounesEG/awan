# التحديث: إغلاق شاشة قفل الصلاة تلقائياً بعد 5 ثوانٍ

## التعديل المضاف
في ملف `lib/features/prayer_clock/presentation/screens/prayer_clock_screen.dart`:
- تم إضافة مؤقت زمني (`Future.delayed` لمدة 5 ثوانٍ) عند عرض الشاشة في وضع `overLock` (فوق شاشة القفل).
- بمجرد انقضاء 5 ثوانٍ وبقاء الشاشة نشطة (`widget.overLock` مع `mounted`)، يتم استدعاء `backgroundApp()` لإخفاء التطبيق تلقائياً والعودة للخلف.

## الملفات المعدلة
- `lib/features/prayer_clock/presentation/screens/prayer_clock_screen.dart`
