import 'package:firebase_core/firebase_core.dart';

class FirebaseConfig {
  FirebaseConfig._();

  static Future<void> initialize() async {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'AIzaSyD02mGcStKA2dKEB5mBB6nQls3o2whxTis',
        authDomain: 'museek-1043d.firebaseapp.com',
        projectId: 'museek-1043d',
        storageBucket: 'museek-1043d.firebasestorage.app',
        messagingSenderId: '747352084910',
        appId: '1:747352084910:web:594f2d8fb50b0e1a26f83f',
      ),
    );
  }
}
