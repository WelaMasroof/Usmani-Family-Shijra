import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'splash screen/home_page.dart';

void main() async {
  await initHiveForFlutter(); // important for caching
  runApp(const ShijraApp());
}

class ShijraApp extends StatelessWidget {
  const ShijraApp({super.key});

  @override
  Widget build(BuildContext context) {
    final HttpLink httpLink = HttpLink('http://localhost:8000/graphql'); // change if hosted

    final ValueNotifier<GraphQLClient> client = ValueNotifier(
      GraphQLClient(
        link: httpLink,
        cache: GraphQLCache(store: HiveStore()),
      ),
    );

    return GraphQLProvider(
      client: client,
      child: MaterialApp(
        title: 'Usmani Family Shijra',
        theme: ThemeData(
          primarySwatch: Colors.indigo,
          fontFamily: 'Roboto',
        ),
        home: const HomePage(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
