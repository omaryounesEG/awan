# graphview — النسخة المحلية في «أوان»

هذا المجلد **نسخة 1.2.0** من حزمة `graphview` مع تعديلات صغيرة، كل منها مؤشَّر بتعليق
`AWAN SHIM` في المصدر. سبب وجودها:

**1.5.1 (الأحدث) لا تعمل هنا.** تستدعي `Color.withValues` وهي Flutter 3.27+ والمشروع على
3.24.3 (فشل بناء)، وبعد تحويلها إلى `withOpacity` تبني لكنها **لا ترسم شيئاً**: مسار
الرسم فيها يضع `RenderCustomLayoutBox` داخل `InteractiveViewer` بقيود غير محدودة
(`BoxConstraints(unconstrained)`) فيسقط التخطيط بـ`size: MISSING` و`RenderBox was not
laid out` — الرسائل نفسها ظهرت في سجل `flutter run` عند فتح شاشة الرسم.

**1.2.0 ترسم** لكنها تحتاج الإصلاحات التالية، وكلها ظهرت بقياس فعلي على الجهاز:

| التعديل | الملف | الأثر |
|---|---|---|
| `constraints.constrain(...)` لنتيجة التخطيط + تمرير المساحة الحقيقية للخوارزمية قبل تشغيلها (`setDimensions`) | `lib/GraphView.dart` | يمنع `RenderCustomLayoutBox does not meet its constraints` التي كانت **تمنع رسم كل العقد** (يتوقف التخطيط قبل إسناد مواضع العقد) |
| تخزين ناتج التخطيط (`_awanLayoutSize`) وإبطاله عند تغيّر الرسم/الخوارزمية/مقاس الشاشة | `lib/GraphView.dart` | الرسم لا يُعاد تخطيطه مع كل إعادة بناء |
| `run` لا يستبدل الأبعاد الواردة من صاحب الرسم | `lib/forcedirected/FruchtermanReingoldAlgorithm.dart` | المساحة تبقى مقاس الشاشة لا «أكبر عقدة × عدد العقد» (٣١ عقدة في مربع ١٣٠٠ بكسل) |
| `init` يخطّط فقط العقد التي لا موضع لها | `lib/forcedirected/FruchtermanReingoldAlgorithm.dart` | أي ترتيب مسبق يُحترم |
| قصّ كامل الدائرة داخل المساحة في `moveNodes` (بدل هامش ٤٠ بكسل للزاوية العليا) | `lib/forcedirected/FruchtermanReingoldAlgorithm.dart` | العقد لا تتدلّى خارج الحافة |

**التطبيق لا يستخدم `FruchtermanReingoldAlgorithm`**: رسم المتشابهات يستعمل
`RingLayoutAlgorithm` في المشروع (مركز + حلقة)، لأن تخطيط القوى لا يعرف المساحة المتاحة
فتوزّع ٣٠ آية على مساحة أوسع من الشاشة. الحزمة تبقى مسؤولة عن اللوحة والحواف والأسهم.

## متى تُحذف هذه النسخة

عند ترقية المشروع إلى Flutter ≥ 3.27: احذف `third_party/graphview` و`dependency_overrides`
من `pubspec.yaml`، وأعِد `graphview: ^1.5.1` من pub.dev، وتحقق أن مسار الرسم الجديد يرسم
العقد فعلاً (افتح شاشة الرسم على محاكٍ ولتقط صورة — لا تعتمد على `flutter analyze`).

`third_party/**` مستثنى من `flutter analyze` في `analysis_options.yaml`.
