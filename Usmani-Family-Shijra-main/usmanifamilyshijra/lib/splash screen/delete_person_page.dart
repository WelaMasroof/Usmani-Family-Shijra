import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
<<<<<<< HEAD:usmanifamilyshijra/lib/splash screen/delete_person_page.dart
import 'package:jwt_decode/jwt_decode.dart';
=======
>>>>>>> 27dbb7915aed38a1b41836660e5d68b2b8e275d8:Usmani-Family-Shijra-main/usmanifamilyshijra/lib/splash screen/delete_person_page.dart

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
<<<<<<< HEAD:usmanifamilyshijra/lib/splash screen/delete_person_page.dart
  String? _userRole;
=======
>>>>>>> 27dbb7915aed38a1b41836660e5d68b2b8e275d8:Usmani-Family-Shijra-main/usmanifamilyshijra/lib/splash screen/delete_person_page.dart
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
<<<<<<< HEAD:usmanifamilyshijra/lib/splash screen/delete_person_page.dart
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
=======
    final token = await _storage.read(key: 'jwt_token');
    if (token == null) {
      _redirectToLogin();
      return;
    }
    setState(() {
      _jwtToken = token;
>>>>>>> 27dbb7915aed38a1b41836660e5d68b2b8e275d8:Usmani-Family-Shijra-main/usmanifamilyshijra/lib/splash screen/delete_person_page.dart
      _isLoading = false;
    });
  }

<<<<<<< HEAD:usmanifamilyshijra/lib/splash screen/delete_person_page.dart
=======
  void _redirectToLogin() {
    Navigator.pushReplacementNamed(context, '/login');
  }
>>>>>>> 27dbb7915aed38a1b41836660e5d68b2b8e275d8:Usmani-Family-Shijra-main/usmanifamilyshijra/lib/splash screen/delete_person_page.dart

  Future<void> _submitForm(RunMutation runMutation) async {
    if (!_formKey.currentState!.validate()) return;

<<<<<<< HEAD:usmanifamilyshijra/lib/splash screen/delete_person_page.dart
    setState(() => _isSubmitting = true);
=======
    setState(() {
      _isSubmitting = true;
    });

>>>>>>> 27dbb7915aed38a1b41836660e5d68b2b8e275d8:Usmani-Family-Shijra-main/usmanifamilyshijra/lib/splash screen/delete_person_page.dart
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

<<<<<<< HEAD:usmanifamilyshijra/lib/splash screen/delete_person_page.dart
    if (_jwtToken == null || _userRole != 'admin') {
      return Scaffold(
        appBar: AppBar(title: const Text("Delete Family Member")),
        body: const Center(
          child: Text(
            '🚫 Access Denied: Only Admins Can Delete',
            style: TextStyle(color: Colors.red, fontSize: 18),
=======
    if (_jwtToken == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('authentication required'),
              TextButton(
                onPressed: _redirectToLogin,
                child: const Text('go to login'),
              ),
            ],
>>>>>>> 27dbb7915aed38a1b41836660e5d68b2b8e275d8:Usmani-Family-Shijra-main/usmanifamilyshijra/lib/splash screen/delete_person_page.dart
          ),
        ),
      );
    }

    return GraphQLProvider(
      client: ValueNotifier(_buildClient()),
      child: Scaffold(
        appBar: AppBar(
<<<<<<< HEAD:usmanifamilyshijra/lib/splash screen/delete_person_page.dart
          title: const Text("Delete Family Member"),
=======
          title: const Text("delete family member"),
>>>>>>> 27dbb7915aed38a1b41836660e5d68b2b8e275d8:Usmani-Family-Shijra-main/usmanifamilyshijra/lib/splash screen/delete_person_page.dart
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
<<<<<<< HEAD:usmanifamilyshijra/lib/splash screen/delete_person_page.dart
                await _storage.delete(key: 'admin_token');
                setState(() {
                  _jwtToken = null;
                  _userRole = null;
                });
=======
                await _storage.delete(key: 'jwt_token');
                _redirectToLogin();
>>>>>>> 27dbb7915aed38a1b41836660e5d68b2b8e275d8:Usmani-Family-Shijra-main/usmanifamilyshijra/lib/splash screen/delete_person_page.dart
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
<<<<<<< HEAD:usmanifamilyshijra/lib/splash screen/delete_person_page.dart
              if (!_dialogShown &&
                  result != null &&
                  (result.data != null || result.hasException)) {
                _dialogShown = true;

                String message = 'Unknown response';
=======
              if (!_dialogShown && result != null && (result.data != null || result.hasException)) {
                _dialogShown = true;

                String message = 'unknown response';
>>>>>>> 27dbb7915aed38a1b41836660e5d68b2b8e275d8:Usmani-Family-Shijra-main/usmanifamilyshijra/lib/splash screen/delete_person_page.dart

                if (result.hasException) {
                  message = result.exception!.graphqlErrors.isNotEmpty
                      ? result.exception!.graphqlErrors.first.message
<<<<<<< HEAD:usmanifamilyshijra/lib/splash screen/delete_person_page.dart
                      : result.exception!.linkException?.originalException?.toString() ?? 'Unknown error';
                } else {
                  final msg = result.data?['deletePerson'] ?? 'No response';
                  message = msg.toString();

=======
                      : result.exception!.linkException?.originalException?.toString()
                      ?? 'unknown error';
                } else {
                  final success = result.data?['deletePerson'];
                  message = success == true
                      ? 'person deleted successfully'
                      : 'no matching person found to delete.';
>>>>>>> 27dbb7915aed38a1b41836660e5d68b2b8e275d8:Usmani-Family-Shijra-main/usmanifamilyshijra/lib/splash screen/delete_person_page.dart
                }

                Future.microtask(() {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
<<<<<<< HEAD:usmanifamilyshijra/lib/splash screen/delete_person_page.dart
                      title: const Text('Status'),
                      content: Text(message),
=======
                      title: const Text('status'),
                      content: Text(message), // <- shows exact error message
>>>>>>> 27dbb7915aed38a1b41836660e5d68b2b8e275d8:Usmani-Family-Shijra-main/usmanifamilyshijra/lib/splash screen/delete_person_page.dart
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
<<<<<<< HEAD:usmanifamilyshijra/lib/splash screen/delete_person_page.dart
                          child: const Text('OK'),
=======
                          child: const Text('ok'),
>>>>>>> 27dbb7915aed38a1b41836660e5d68b2b8e275d8:Usmani-Family-Shijra-main/usmanifamilyshijra/lib/splash screen/delete_person_page.dart
                        ),
                      ],
                    ),
                  );
                });
              }

<<<<<<< HEAD:usmanifamilyshijra/lib/splash screen/delete_person_page.dart
=======

>>>>>>> 27dbb7915aed38a1b41836660e5d68b2b8e275d8:Usmani-Family-Shijra-main/usmanifamilyshijra/lib/splash screen/delete_person_page.dart
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
<<<<<<< HEAD:usmanifamilyshijra/lib/splash screen/delete_person_page.dart
        labelText: "Person ID (optional)",
        border: OutlineInputBorder(),
        helperText: "Provide ID or both name and father's name",
=======
        labelText: "person id (optional)",
        border: OutlineInputBorder(),
        helperText: "either provide id or both name and father's name",
>>>>>>> 27dbb7915aed38a1b41836660e5d68b2b8e275d8:Usmani-Family-Shijra-main/usmanifamilyshijra/lib/splash screen/delete_person_page.dart
      ),
      enabled: _nameController.text.isEmpty && _fatherNameController.text.isEmpty,
      onSaved: (val) => id = val?.isNotEmpty == true ? val : null,
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      decoration: const InputDecoration(
<<<<<<< HEAD:usmanifamilyshijra/lib/splash screen/delete_person_page.dart
        labelText: "Name (required if no ID)",
=======
        labelText: "name (required if no id)",
>>>>>>> 27dbb7915aed38a1b41836660e5d68b2b8e275d8:Usmani-Family-Shijra-main/usmanifamilyshijra/lib/splash screen/delete_person_page.dart
        border: OutlineInputBorder(),
      ),
      enabled: _idController.text.isEmpty,
      validator: (val) {
        if (_idController.text.isEmpty && val!.isEmpty) {
<<<<<<< HEAD:usmanifamilyshijra/lib/splash screen/delete_person_page.dart
          return "Required when no ID is provided";
=======
          return "required when no id provided";
>>>>>>> 27dbb7915aed38a1b41836660e5d68b2b8e275d8:Usmani-Family-Shijra-main/usmanifamilyshijra/lib/splash screen/delete_person_page.dart
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
<<<<<<< HEAD:usmanifamilyshijra/lib/splash screen/delete_person_page.dart
        labelText: "Father's Name (required if no ID)",
=======
        labelText: "father's name (required if no id)",
>>>>>>> 27dbb7915aed38a1b41836660e5d68b2b8e275d8:Usmani-Family-Shijra-main/usmanifamilyshijra/lib/splash screen/delete_person_page.dart
        border: OutlineInputBorder(),
      ),
      enabled: _idController.text.isEmpty,
      validator: (val) {
        if (_idController.text.isEmpty && val!.isEmpty) {
<<<<<<< HEAD:usmanifamilyshijra/lib/splash screen/delete_person_page.dart
          return "Required when no ID is provided";
=======
          return "required when no id provided";
>>>>>>> 27dbb7915aed38a1b41836660e5d68b2b8e275d8:Usmani-Family-Shijra-main/usmanifamilyshijra/lib/splash screen/delete_person_page.dart
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
<<<<<<< HEAD:usmanifamilyshijra/lib/splash screen/delete_person_page.dart
        'Delete Family Member',
=======
        'delete family member',
>>>>>>> 27dbb7915aed38a1b41836660e5d68b2b8e275d8:Usmani-Family-Shijra-main/usmanifamilyshijra/lib/splash screen/delete_person_page.dart
        style: TextStyle(fontSize: 16, color: Colors.white),
      ),
    );
  }
}
