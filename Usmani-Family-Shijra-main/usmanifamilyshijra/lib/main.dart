import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'splash screen/login.dart';
import 'splash screen/add_person_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const storage = FlutterSecureStorage();
  final token = await storage.read(key: 'jwt_token');

  print("Token at startup: $token");
  runApp(MyApp(initialRoute: token != null ? '/add-person' : '/login'));
}

class MyApp extends StatelessWidget {
  final String initialRoute;

  const MyApp({Key? key, required this.initialRoute}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Admin App',
      initialRoute: initialRoute,
      routes: {
        '/login': (context) => LoginScreen(),
        '/add-person': (context) => AddPersonPage(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
