import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

GraphQLClient getGraphQLClient(String token) {
  final httpLink = HttpLink(
    'https://fast-api-shijra-nxa89pb0z-faaezs-projects-373a7c11.vercel.app/graphql', // 🔁 Replace with your actual backend URL
  );

  final authLink = AuthLink(
    getToken: () async => 'Bearer $token',
  );

  final link = authLink.concat(httpLink);

  return GraphQLClient(
    cache: GraphQLCache(store: InMemoryStore()),
    link: link,
  );
}
