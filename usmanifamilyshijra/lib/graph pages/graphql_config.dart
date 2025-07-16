import 'package:flutter/cupertino.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

ValueNotifier<GraphQLClient> graphqlClient = ValueNotifier(
  GraphQLClient(
    link: HttpLink("fast-api-shijra-2008non12-faaezs-projects-373a7c11.vercel.app/graphql"),
    cache: GraphQLCache(),
  ),
);
