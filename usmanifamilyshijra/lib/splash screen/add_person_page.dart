import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

class AddPersonPage extends StatefulWidget {
  const AddPersonPage({Key? key}) : super(key: key);

  @override
  State<AddPersonPage> createState() => _AddPersonPageState();
}

class _AddPersonPageState extends State<AddPersonPage> {
  final _formKey = GlobalKey<FormState>();

  String name = '';
  String gender = 'male';
  String fatherName = '';
  String grandfatherName = '';
  String? motherName;

  String? _errorMessage; // holds the latest error

  final String createPersonMutation = """
    mutation CreatePerson(\$person: PersonInput!) {
      createPerson(person: \$person) {
        id
        name
      }
    }
  """;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Family Member")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Mutation(
          options: MutationOptions(
            document: gql(createPersonMutation),
            onCompleted: (dynamic resultData) {
              setState(() {
                _errorMessage = null;
              });

              final person = resultData?['createPerson'];
              final id = person?['id'] ?? 'N/A';
              final name = person?['name'] ?? 'N/A';

              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Person Added'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('✅ Person was successfully added.'),
                      const SizedBox(height: 8),
                      Text('🆔 ID: $id'),
                      Text('👤 Name: $name'),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
            onError: (error) {
              final message = error?.graphqlErrors.isNotEmpty == true
                  ? error!.graphqlErrors.first.message
                  : error?.linkException?.originalException?.toString() ?? "Unknown error";

              setState(() {
                _errorMessage = message;
              });
            },
          ),
          builder: (RunMutation runMutation, QueryResult? result) {
            return Column(
              children: [
                if (_errorMessage != null)
                  ExpansionTile(
                    initiallyExpanded: true,
                    title: const Text('❌ Error Occurred', style: TextStyle(color: Colors.red)),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.redAccent),
                        ),
                      ),
                    ],
                  ),
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      children: [
                        TextFormField(
                          decoration: const InputDecoration(labelText: "Name"),
                          onSaved: (val) => name = val!,
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
                          decoration: const InputDecoration(labelText: "Father's Name"),
                          onSaved: (val) => fatherName = val!,
                          validator: (val) => val!.isEmpty ? "Required" : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          decoration: const InputDecoration(labelText: "Grandfather's Name"),
                          onSaved: (val) => grandfatherName = val!,
                          validator: (val) => val!.isEmpty ? "Required" : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          decoration: const InputDecoration(labelText: "Mother's Name (optional)"),
                          onSaved: (val) => motherName = val,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              _formKey.currentState!.save();

                              runMutation({
                                "person": {
                                  "name": name,
                                  "gender": gender,
                                  "fatherName": fatherName,
                                  "grandfatherName": grandfatherName,
                                  "motherName": motherName,
                                }
                              });
                            }
                          },
                          child: const Text("Add Person"),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
