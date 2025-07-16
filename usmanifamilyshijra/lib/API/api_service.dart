import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/person.dart';


class ApiService {
  static const String apiUrl = "https://fast-api-shijra-2008non12-faaezs-projects-373a7c11.vercel.app/graphql"; // your actual endpoint

  static Future<List<Person>> fetchPersons() async {
    const query = '''
      query {
        allPersons {
          id
          name
          fatherName
          motherName
        }
      }
    ''';

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'query': query}),
    );

    if (response.statusCode == 200) {
      final List persons = json.decode(response.body)['data']['allPersons'];
      return persons.map((json) => Person.fromJson(json)).toList();
    } else {
      throw Exception("Failed to load family data");
    }
  }
}
