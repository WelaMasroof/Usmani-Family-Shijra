import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'splash screen/home_page.dart';
import 'splash screen/add_person_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initHiveForFlutter(); // important for caching

  final client = await initGraphQLClient(); // 🔥 JWT-aware client
  runApp(GraphQLProvider(client: client, child: const ShijraApp()));
}

// 🔐 Function to initialize GraphQL client with AuthLink
Future<ValueNotifier<GraphQLClient>> initGraphQLClient() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('jwt');

  final authLink = AuthLink(
    getToken: () async => token != null ? 'Bearer $token' : null,
  );

  final httpLink = HttpLink('http://localhost:8000/graphql'); // change to IP on real device

  final link = authLink.concat(httpLink); // 💥 combine auth + http links

  return ValueNotifier(
    GraphQLClient(
      link: link,
      cache: GraphQLCache(store: HiveStore()),
    ),
  );
}

class ShijraApp extends StatelessWidget {
  const ShijraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Usmani Family Shijra',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        fontFamily: 'Roboto',
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const HomePage(),
        '/add': (context) => const AddPersonPage(),
      },
    );
  }
}
