# إعداد Firebase

لتجربة ربط firebase بflutter اتبع الخطوات

> **ملاحظة:** قبل البدء تأكد أنه تم إضافتك للمشروع في https://console.firebase.google.com/

## الخطوة ١: استنساخ المشروع لجهازك
من الshell أو terminal

```bash
git clone https://github.com/AsmaFh241/uniclubs.git
```

```bash
cd uniclubs
```

لتحميل الباكجات الضرورية
```bash
flutter pub get
```

```bash
npm install -g firebase-tools
```

## الخطوة ٢: إعداد Firebase CLI

```bash
firebase login
```

```bash
firebase init firestore
```

- اختر مشروع `uniclubs-f926d`
- اقبل الأسماء الافتراضية للملفات

## الخطوة ٣: نشر قواعد Firestore

```bash
firebase deploy --only firestore:rules
```

## الخطوة ٤: تشغيل التطبيق

```bash
flutter run
```

## الخطوة ٥: اختبار Firebase (اختياري)

إذا تريد تختبر أن Firebase متصل بشكل صحيح، أنشئ ملف `lib/firebase_test_screen.dart` وانسخ الكود التالي:

```dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class FirebaseTestScreen extends StatefulWidget {
  const FirebaseTestScreen({super.key});

  @override
  State<FirebaseTestScreen> createState() => _FirebaseTestScreenState();
}

class _FirebaseTestScreenState extends State<FirebaseTestScreen> {
  final List<_TestResult> _results = [];
  bool _testing = false;

  Future<void> _runTests() async {
    setState(() {
      _results.clear();
      _testing = true;
    });

    // Test 1: Firebase Core
    try {
      final app = Firebase.app();
      _addResult('Firebase Core', true, 'Project: ${app.options.projectId}');
    } catch (e) {
      _addResult('Firebase Core', false, e.toString());
    }

    // Test 2: Firestore connectivity
    try {
      final doc = FirebaseFirestore.instance.collection('test').doc('ping');
      await doc.set({'timestamp': FieldValue.serverTimestamp()});
      await doc.delete();
      _addResult('Firestore', true, 'Read/write working');
    } catch (e) {
      _addResult('Firestore', false, e.toString());
    }

    // Test 3: Storage connectivity
    try {
      final ref = FirebaseStorage.instance.ref();
      await ref.listAll();
      _addResult('Storage', true, 'Connected');
    } catch (e) {
      _addResult('Storage', false, e.toString());
    }

    // Test 4: FCM
    try {
      final messaging = FirebaseMessaging.instance;
      final token = await messaging.getToken();
      _addResult('FCM', true, 'Token: ${token?.substring(0, 20)}...');
    } catch (e) {
      _addResult('FCM', false, e.toString());
    }

    setState(() => _testing = false);
  }

  void _addResult(String name, bool success, String detail) {
    setState(() {
      _results.add(_TestResult(name: name, success: success, detail: detail));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firebase Test'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _testing ? null : _runTests,
              child: _testing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Run Firebase Tests'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _results.length,
                itemBuilder: (context, index) {
                  final r = _results[index];
                  return Card(
                    child: ListTile(
                      leading: Icon(
                        r.success ? Icons.check_circle : Icons.error,
                        color: r.success ? Colors.green : Colors.red,
                      ),
                      title: Text(r.name),
                      subtitle: Text(r.detail,
                          maxLines: 3, overflow: TextOverflow.ellipsis),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TestResult {
  final String name;
  final bool success;
  final String detail;

  _TestResult(
      {required this.name, required this.success, required this.detail});
}
```

ثم عدّل `lib/main.dart` مؤقتاً:

```dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_test_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MaterialApp(home: FirebaseTestScreen()));
}
```

شغّل التطبيق واضغط **Run Firebase Tests**. يجب أن تظهر جميع الاختبارات باللون الأخضر:
- **Firebase Core** — التهيئة الأساسية
- **Firestore** — القراءة والكتابة
- **Storage** — الاتصال بالتخزين
- **FCM** — الإشعارات

> **ملاحظة:** بعد التأكد من الاتصال، ارجع `main.dart` لحالته الأصلية واحذف ملف `firebase_test_screen.dart`.