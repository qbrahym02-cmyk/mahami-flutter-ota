# مهامي — تطبيق To-Do بـ Flutter مع تحديث عن بُعد

تطبيق مهام عربي (RTL) بتصميم Material 3، يمكنك تحديثه عن بُعد بثلاث طرق:

| الطريقة | ماذا تغيّر؟ | كيف تصل للمستخدم؟ | يحتاج تثبيت؟ |
|---|---|---|---|
| **1. الإعدادات عن بُعد** — `remote/config.json` | الإعلانات، اللون، اسم التطبيق، تفعيل/إخفاء ميزات، مهام سريعة، وضع الصيانة | خلال دقائق عند فتح التطبيق أو سحب الشاشة للأسفل | ❌ لا |
| **2. تحديث داخل التطبيق (APK)** | أي تغيير في الكود | شريط "نسخة جديدة متوفرة ← حدّث الآن" ينزّل ويفتح التثبيت مباشرة | زر واحد فقط، بدون متجر وبدون تحميل يدوي |
| **3. نسخة الويب** — GitHub Pages | أي تغيير في الكود | تلقائياً عند إعادة فتح الصفحة | ❌ لا |

> المهام محفوظة على الجهاز (`shared_preferences`) ولا تُمسح عند أي تحديث.

---

## 🚀 كيف تحدّث التطبيق

### أ) تغيير فوري بدون أي تثبيت
عدّل `remote/config.json` مباشرة من GitHub (أيقونة القلم ✏️) واحفظ. مثال:

```json
{
  "app_title": "مهامي",
  "primary_color": "#0E9F6E",
  "announcement": { "enabled": true, "type": "success", "text": "ميزة جديدة وصلت! 🎉" },
  "features": { "show_stats": true, "show_priority": true, "confirm_delete": true },
  "quick_tasks": ["شرب الماء 💧", "رياضة 🏃"],
  "maintenance": { "enabled": false, "message": "" }
}
```

- `type` للإعلان: `info` أو `success` أو `warning`
- `maintenance.enabled: true` يعرض شاشة صيانة بدل التطبيق
- ⏱️ GitHub يخزّن الملفات الخام مؤقتاً، فقد يستغرق التغيير **حتى 5 دقائق**

### ب) تحديث الكود (نسخة جديدة)
1. عدّل أي ملف داخل `lib/` (أو `android/` أو `pubspec.yaml`) وادفعه إلى `main`.
2. **GitHub Actions** يقوم تلقائياً بـ:
   - بناء APK موقّع برقم بناء جديد
   - نشره في **Releases**
   - تحديث `remote/version.json`
   - نشر نسخة الويب
3. عند فتح التطبيق يظهر للمستخدم: **"نسخة جديدة متوفرة ← حدّث الآن"**.

يمكنك أيضاً تشغيله يدوياً من **Actions ← Build & Publish Update ← Run workflow** وكتابة "ما الجديد"، واختيار **تحديث إجباري** (يمنع إخفاء الشريط).

---

## 📲 التثبيت لأول مرة
1. نزّل `mahami.apk` من صفحة **Releases** في المستودع.
2. اسمح بـ "التثبيت من مصادر غير معروفة" عند الطلب.
3. بعدها كل التحديثات تأتي من داخل التطبيق.

---

## 🔐 مفتاح التوقيع (مهم جداً)
أندرويد **يرفض** تثبيت التحديث إن لم يكن موقّعاً بنفس مفتاح النسخة المثبّتة.
المفتاح محفوظ كـ Secrets في المستودع:

| Secret | المحتوى |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | ملف `upload-keystore.jks` بصيغة base64 |
| `ANDROID_KEYSTORE_PASSWORD` | كلمة مرور المخزن |
| `ANDROID_KEY_ALIAS` | `mahami` |
| `ANDROID_KEY_PASSWORD` | كلمة مرور المفتاح |

**احتفظ بنسخة احتياطية من ملف الـ keystore وكلمة المرور.** إن ضاع، لن تستطيع إصدار تحديثات للنسخ المثبّتة.
لا ترفع الـ keystore أو `key.properties` إلى المستودع أبداً (موجودة في `.gitignore`).

---

## 🛠️ التشغيل محلياً
```bash
flutter pub get
flutter run                 # على جهاز أندرويد
flutter run -d chrome       # على المتصفح
flutter test
```
للبناء الموقّع محلياً ضع `android/key.properties`:
```properties
storePassword=...
keyPassword=...
keyAlias=mahami
storeFile=/path/to/upload-keystore.jks
```

لتغيير مصدر التحديثات (مثلاً سيرفرك الخاص) عدّل `lib/config.dart`.

---

## 🐦 اختياري: Shorebird (تحديث الكود بصمت بدون أي شاشة تثبيت)
[Shorebird](https://shorebird.dev) هو حل "Code Push" الرسمي لـ Flutter: يرسل تعديلات كود Dart
فتُطبَّق عند إعادة فتح التطبيق **بدون أي شاشة تثبيت**.
```bash
curl --proto '=https' --tlsv1.2 https://raw.githubusercontent.com/shorebirdtech/install/main/install.sh -sSf | bash
shorebird login
shorebird init
shorebird release android --artifact apk   # وزّع هذه النسخة مرة واحدة
# بعد أي تعديل في lib/ :
shorebird patch android                    # يصل للمستخدمين بصمت
```
ملاحظة: Shorebird يحدّث كود Dart فقط؛ تغييرات الكود الأصلي (Android/plugins جديدة) تحتاج APK جديد عبر الطريقة (ب).

---

## 📁 هيكل المشروع
```
lib/
  config.dart                      ← روابط مصدر التحديث
  main.dart                        ← التطبيق + الفحص الدوري عند العودة للتطبيق
  models/task.dart
  services/task_repository.dart    ← حفظ المهام محلياً
  services/remote_config_service.dart  ← الإعدادات عن بُعد (مع كاش يعمل بدون إنترنت)
  services/update_service.dart     ← فحص/تنزيل/تثبيت APK الجديد
  screens/home_screen.dart
  screens/about_screen.dart        ← رقم النسخة + فحص التحديثات يدوياً
  widgets/...
remote/
  config.json                      ← عدّله للتحديث الفوري
  version.json                     ← يحدّثه GitHub Actions تلقائياً
.github/workflows/release.yml      ← البناء والنشر التلقائي
```
