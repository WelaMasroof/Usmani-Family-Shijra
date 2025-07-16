import 'package:family_tree/splash%20screen/delete_person_page.dart';
import 'package:family_tree/splash%20screen/login%20page.dart';
import 'package:family_tree/splash%20screen/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Graph/forcedirectedgraph.dart';
import 'Graph/graph_page.dart';
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

  final httpLink = HttpLink('https://fast-api-shijra-2008non12-faaezs-projects-373a7c11.vercel.app/token'); // change to IP on real device

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
        '/': (context) => const GraphPage(),
        '/add': (context) => const AddPersonPage(),
        '/splash': (context) => const SplashScreen(),
        '/delete': (context) => const DeletePersonPage(),
        '/login': (context) => const LoginPage(),

      },
    );
  }
}
