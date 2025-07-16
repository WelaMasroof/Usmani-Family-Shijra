import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/person.dart';


class ApiService {
<<<<<<< HEAD
  static const String apiUrl = "https://fast-api-shijra-nxa89pb0z-faaezs-projects-373a7c11.vercel.app/graphql"; // your actual endpoint
=======
  static const String apiUrl = "https://fast-api-shijra-77sqbw2ks-faaezs-projects-373a7c11.vercel.app/graphql"; // your actual endpoint
>>>>>>> 86b48afc3b0bd1c7102a56d76e18ff56fd1507f9

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
