import 'package:flutter/cupertino.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

ValueNotifier<GraphQLClient> graphqlClient = ValueNotifier(
  GraphQLClient(
    link: HttpLink("https://fast-api-shijra.vercel.app/graphql"),
    cache: GraphQLCache(),
  ),
);
