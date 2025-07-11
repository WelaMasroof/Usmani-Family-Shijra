import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decode/jwt_decode.dart';

class DeletePersonPage extends StatefulWidget {
  const DeletePersonPage({Key? key}) : super(key: key);

  @override
  State<DeletePersonPage> createState() => _DeletePersonPageState();
}

class _DeletePersonPageState extends State<DeletePersonPage> {
  final _storage = const FlutterSecureStorage();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _idController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _fatherNameController = TextEditingController();

  String? id;
  String? name;
  String? fatherName;

  String? _jwtToken;
  String? _userRole;
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _dialogShown = false;

  final String deletePersonMutation = """
    mutation DeletePerson(\$person: DeletePersonInput!) {
      deletePerson(person: \$person)
    }
  """;

  @override
  void initState() {
    super.initState();
    _initializeAuth();
    _idController.addListener(() => setState(() {}));
    _nameController.addListener(() => setState(() {}));
    _fatherNameController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    _fatherNameController.dispose();
    super.dispose();
  }

  Future<void> _initializeAuth() async {
    final token = await _storage.read(key: 'admin_token') ?? await _storage.read(key: 'jwt_token');
    String? role;

    if (token != null) {
      try {
        final decoded = Jwt.parseJwt(token);
        if (decoded.containsKey('role')) {
          role = decoded['role'];
          debugPrint('✅ Role found: $role');
        } else {
          print('❌ Role not found in token: $decoded');
        }

        debugPrint('🧾 Decoded JWT: $decoded');         // ✅ Full decoded token
        debugPrint('🛂 Decoded role: $role');           // ✅ Role only
      } catch (e) {
        debugPrint('Failed to decode JWT: $e');
      }
    }

    setState(() {
      _jwtToken = token;
      _userRole = role;
      _isLoading = false;
    });
  }


  Future<void> _submitForm(RunMutation runMutation) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    _formKey.currentState!.save();

    runMutation({
      "person": {
        if (id != null) "id": id,
        if (name != null) "name": name,
        if (fatherName != null) "fatherName": fatherName,
      },
    });
  }

  GraphQLClient _buildClient() {
    final httpLink = HttpLink(
      'http://127.0.0.1:8080/graphql',
      defaultHeaders: {
        if (_jwtToken != null) 'Authorization': 'Bearer $_jwtToken',
      },
    );

    return GraphQLClient(link: httpLink, cache: GraphQLCache());
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_jwtToken == null || _userRole != 'admin') {
      return Scaffold(
        appBar: AppBar(title: const Text("Delete Family Member")),
        body: const Center(
          child: Text(
            '🚫 Access Denied: Only Admins Can Delete',
            style: TextStyle(color: Colors.red, fontSize: 18),
          ),
        ),
      );
    }

    return GraphQLProvider(
      client: ValueNotifier(_buildClient()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Delete Family Member"),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await _storage.delete(key: 'admin_token');
                setState(() {
                  _jwtToken = null;
                  _userRole = null;
                });
              },
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Mutation(
            options: MutationOptions(
              document: gql(deletePersonMutation),
              onCompleted: (_) {
                setState(() {
                  _isSubmitting = false;
                  _dialogShown = false;
                });
              },
            ),
            builder: (RunMutation runMutation, QueryResult? result) {
              if (!_dialogShown &&
                  result != null &&
                  (result.data != null || result.hasException)) {
                _dialogShown = true;

                String message = 'Unknown response';

                if (result.hasException) {
                  message = result.exception!.graphqlErrors.isNotEmpty
                      ? result.exception!.graphqlErrors.first.message
                      : result.exception!.linkException?.originalException?.toString() ?? 'Unknown error';
                } else {
                  final msg = result.data?['deletePerson'] ?? 'No response';
                  message = msg.toString();

                }

                Future.microtask(() {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Status'),
                      content: Text(message),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            if (message.contains('successfully')) {
                              _formKey.currentState?.reset();
                              _idController.clear();
                              _nameController.clear();
                              _fatherNameController.clear();
                            }
                            setState(() => _dialogShown = false);
                          },
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                });
              }

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
        labelText: "Person ID (optional)",
        border: OutlineInputBorder(),
        helperText: "Provide ID or both name and father's name",
      ),
      enabled: _nameController.text.isEmpty && _fatherNameController.text.isEmpty,
      onSaved: (val) => id = val?.isNotEmpty == true ? val : null,
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      decoration: const InputDecoration(
        labelText: "Name (required if no ID)",
        border: OutlineInputBorder(),
      ),
      enabled: _idController.text.isEmpty,
      validator: (val) {
        if (_idController.text.isEmpty && val!.isEmpty) {
          return "Required when no ID is provided";
        }
        return null;
      },
      onSaved: (val) => name = val,
    );
  }

  Widget _buildFatherNameField() {
    return TextFormField(
      controller: _fatherNameController,
      decoration: const InputDecoration(
        labelText: "Father's Name (required if no ID)",
        border: OutlineInputBorder(),
      ),
      enabled: _idController.text.isEmpty,
      validator: (val) {
        if (_idController.text.isEmpty && val!.isEmpty) {
          return "Required when no ID is provided";
        }
        return null;
      },
      onSaved: (val) => fatherName = val,
    );
  }

  Widget _buildSubmitButton(RunMutation runMutation) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
        padding: const EdgeInsets.symmetric(vertical: 16),
        backgroundColor: Colors.red,
      ),
      onPressed: _isSubmitting ? null : () => _submitForm(runMutation),
      child: _isSubmitting
          ? const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Colors.white,
        ),
      )
          : const Text(
        'Delete Family Member',
        style: TextStyle(fontSize: 16, color: Colors.white),
      ),
    );
  }
}
