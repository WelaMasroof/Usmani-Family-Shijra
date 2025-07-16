import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeletePersonPage extends StatefulWidget {
  const DeletePersonPage({Key? key}) : super(key: key);

  @override
  State<DeletePersonPage> createState() => _DeletePersonPageState();
}

class _DeletePersonPageState extends State<DeletePersonPage> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _nameController = TextEditingController();
  final _fatherNameController = TextEditingController();

  bool _isSubmitting = false;
  bool _isLoading = true;
  ValueNotifier<GraphQLClient>? _client;

  final String deletePersonMutation = """
    mutation DeletePerson(\$person: DeletePersonInput!) {
      deletePerson(person: \$person)
    }
  """;

  bool _disableNameAndFather = false;
  bool _disableId = false;

  @override
  void initState() {
    super.initState();
    _initializeGraphQLClient();

    _idController.addListener(() {
      final hasId = _idController.text.isNotEmpty;
      if (hasId != _disableNameAndFather) {
        setState(() {
          _disableNameAndFather = hasId;
          if (hasId) {
            _nameController.clear();
            _fatherNameController.clear();
          }
        });
      }
    });

    void handleNameOrFatherChange() {
      final hasEither = _nameController.text.isNotEmpty || _fatherNameController.text.isNotEmpty;
      if (hasEither != _disableId) {
        setState(() {
          _disableId = hasEither;
          if (hasEither) {
            _idController.clear();
          }
        });
      }
    }

    _nameController.addListener(handleNameOrFatherChange);
    _fatherNameController.addListener(handleNameOrFatherChange);
  }


  Future<void> _initializeGraphQLClient() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt');

    final authLink = AuthLink(getToken: () async => 'Bearer $token');
<<<<<<< HEAD
    final httpLink = HttpLink('https://fast-api-shijra-nxa89pb0z-faaezs-projects-373a7c11.vercel.app/graphql');
=======
    final httpLink = HttpLink('https://fast-api-shijra-77sqbw2ks-faaezs-projects-373a7c11.vercel.app/graphql');
>>>>>>> 86b48afc3b0bd1c7102a56d76e18ff56fd1507f9
    final link = authLink.concat(httpLink);

    _client = ValueNotifier(
      GraphQLClient(
        link: link,
        cache: GraphQLCache(store: InMemoryStore()),
      ),
    );

    setState(() => _isLoading = false);
  }

  void _showDialog(String title, String message, {bool isError = false}) {
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
                _idController.clear();
                _nameController.clear();
                _fatherNameController.clear();
              }
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _client == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return GraphQLProvider(
      client: _client!,
      child: Scaffold(
        appBar: AppBar(title: const Text("Delete Family Member")),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Mutation(
            options: MutationOptions(
              document: gql(deletePersonMutation),
              onCompleted: (data) {
                setState(() => _isSubmitting = false);
                final result = data?['deletePerson'];
                final success = result == "Person deleted successfully.";
                _showDialog(
                  success ? "Deleted" : "Failed",
                  result ?? "Unknown result",
                  isError: !success,
                );
              },
              onError: (error) {
                setState(() => _isSubmitting = false);
                String message = "An unknown error occurred";
                if (error != null) {
                  if (error.graphqlErrors.isNotEmpty) {
                    message = error.graphqlErrors.first.message;
                    if (message.contains("Exception: ")) {
                      message = message.split("Exception: ").last;
                    }
                  } else if (error.linkException != null) {
                    message = error.linkException.toString();
                  }
                }
                _showDialog("Error", message, isError: true);
              },
            ),
            builder: (RunMutation runMutation, QueryResult? result) {
              return Form(
                key: _formKey,
                child: ListView(
                  children: [
                    _buildIdField(),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    _buildNameField(),
                    const SizedBox(height: 16),
                    _buildFatherNameField(),
                    const SizedBox(height: 24),
                    _buildSubmitButton(runMutation),
                    if (_isSubmitting)
                      const Padding(
                        padding: EdgeInsets.only(top: 16.0),
                        child: LinearProgressIndicator(),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
  Widget _buildIdField() {
    return TextFormField(
      controller: _idController,
      decoration: const InputDecoration(
        labelText: "person id (optional)",
        border: OutlineInputBorder(),
        helperText: "either provide id or both name and father's name",
      ),
      enabled: !_disableId,
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      decoration: const InputDecoration(
        labelText: "name (required if no id)",
        border: OutlineInputBorder(),
      ),
      enabled: !_disableNameAndFather,
      validator: (val) {
        if (_idController.text.isEmpty && val!.isEmpty) {
          return "required when no id provided";
        }
        return null;
      },
    );
  }

  Widget _buildFatherNameField() {
    return TextFormField(
      controller: _fatherNameController,
      decoration: const InputDecoration(
        labelText: "father's name (required if no id)",
        border: OutlineInputBorder(),
      ),
      enabled: !_disableNameAndFather,
      validator: (val) {
        if (_idController.text.isEmpty && val!.isEmpty) {
          return "required when no id provided";
        }
        return null;
      },
    );
  }



  Widget _buildSubmitButton(RunMutation runMutation) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
        backgroundColor: Colors.red,
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      onPressed: _isSubmitting
          ? null
          : () {
        if (_formKey.currentState!.validate()) {
          setState(() => _isSubmitting = true);
          runMutation({
            "person": {
              if (_idController.text.isNotEmpty) "id": _idController.text,
              if (_nameController.text.isNotEmpty) "name": _nameController.text,
              if (_fatherNameController.text.isNotEmpty) "fatherName": _fatherNameController.text,
            }
          });
        }
      },
      child: _isSubmitting
          ? const CircularProgressIndicator(color: Colors.white)
          : const Text("Delete Person", style: TextStyle(color: Colors.white)),
    );
  }

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    _fatherNameController.dispose();
    super.dispose();
  }
}
