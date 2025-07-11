import 'package:flutter/cupertino.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

ValueNotifier<GraphQLClient> graphqlClient = ValueNotifier(
  GraphQLClient(
    link: HttpLink("https://your-vercel-url.vercel.app/graphql"),
    cache: GraphQLCache(),
  ),
);
