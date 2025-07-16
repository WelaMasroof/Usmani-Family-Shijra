import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ValueNotifier<GraphQLClient>> initGraphQLClient() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('jwt');

  final authLink = AuthLink(getToken: () async => 'Bearer $token');
<<<<<<< HEAD
  final httpLink = HttpLink('https://fast-api-shijra-nxa89pb0z-faaezs-projects-373a7c11.vercel.app/graphql');
=======
  final httpLink = HttpLink('https://fast-api-shijra-77sqbw2ks-faaezs-projects-373a7c11.vercel.app/graphql');
>>>>>>> 86b48afc3b0bd1c7102a56d76e18ff56fd1507f9

  final link = authLink.concat(httpLink);

  return ValueNotifier(
    GraphQLClient(
      link: link,
      cache: GraphQLCache(store: InMemoryStore()),
    ),
  );
}

class AddPersonPage extends StatefulWidget {
  const AddPersonPage({Key? key}) : super(key: key);

  @override
  State<AddPersonPage> createState() => _AddPersonPageState();
}

class _AddPersonPageState extends State<AddPersonPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _fatherNameController = TextEditingController();
  final _grandfatherNameController = TextEditingController();
  final _motherNameController = TextEditingController();

  String gender = 'male';
  bool _isSubmitting = false;

  final String createPersonMutation = """
    mutation CreatePerson(\$person: PersonInput!) {
      createPerson(person: \$person) {
        id
        name
      }
    }
  """;

  void _showResultDialog(String title, String message, {bool isError = false}) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Row(
          children: [
            Icon(isError ? Icons.error : Icons.check_circle,
                color: isError ? Colors.red : Colors.green),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (!isError) {
                _formKey.currentState?.reset();
                _nameController.clear();
                _fatherNameController.clear();
                _grandfatherNameController.clear();
                _motherNameController.clear();
              }
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ValueNotifier<GraphQLClient>>(
      future: initGraphQLClient(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return GraphQLProvider(
          client: snapshot.data!,
          child: Scaffold(
            appBar: AppBar(title: const Text("Add Family Member")),
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Mutation(
                options: MutationOptions(
                  document: gql(createPersonMutation),
                  onCompleted: (dynamic resultData) {
                    if (!mounted) return;
                    setState(() => _isSubmitting = false);

                    final person = resultData?['createPerson'];
                    if (person != null) {
                      _showResultDialog(
                        "Person Added",
                        "Person was successfully added.\n\nID: ${person['id'] ?? 'N/A'}\nName: ${person['name'] ?? 'N/A'}",
                      );
                    }
                  },
                  onError: (error) {
                    if (!mounted) return;
                    setState(() => _isSubmitting = false);

                    String errorMessage = "An unknown error occurred";
                    if (error != null) {
                      if (error.graphqlErrors.isNotEmpty) {
                        errorMessage = error.graphqlErrors.first.message;
                        if (errorMessage.contains("Exception: ")) {
                          errorMessage = errorMessage.split("Exception: ").last;
                        }
                      } else if (error.linkException != null) {
                        errorMessage = error.linkException.toString();
                      }
                    }

                    _showResultDialog("Error", errorMessage, isError: true);
                  },
                ),
                builder: (RunMutation runMutation, QueryResult? result) {
                  return Form(
                    key: _formKey,
                    child: ListView(
                      children: [
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(labelText: "Name"),
                          validator: (val) => val!.isEmpty ? "Required" : null,
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(labelText: "Gender"),
                          value: gender,
                          items: const [
                            DropdownMenuItem(value: 'male', child: Text('Male')),
                            DropdownMenuItem(value: 'female', child: Text('Female')),
                          ],
                          onChanged: (value) {
                            if (value != null) setState(() => gender = value);
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _fatherNameController,
                          decoration: const InputDecoration(labelText: "Father's Name"),
                          validator: (val) => val!.isEmpty ? "Required" : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _grandfatherNameController,
                          decoration: const InputDecoration(labelText: "Grandfather's Name"),
                          validator: (val) => val!.isEmpty ? "Required" : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _motherNameController,
                          decoration: const InputDecoration(labelText: "Mother's Name (optional)"),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _isSubmitting
                              ? null
                              : () {
                            if (_formKey.currentState!.validate()) {
                              setState(() => _isSubmitting = true);
                              runMutation({
                                "person": {
                                  "name": _nameController.text,
                                  "gender": gender,
                                  "fatherName": _fatherNameController.text,
                                  "grandfatherName": _grandfatherNameController.text,
                                  "motherName": _motherNameController.text.isNotEmpty
                                      ? _motherNameController.text
                                      : null,
                                }
                              });
                            }
                          },
                          child: _isSubmitting
                              ? const CircularProgressIndicator()
                              : const Text("Add Person"),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _fatherNameController.dispose();
    _grandfatherNameController.dispose();
    _motherNameController.dispose();
    super.dispose();
  }
}
