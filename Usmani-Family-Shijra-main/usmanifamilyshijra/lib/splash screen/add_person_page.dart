import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AddPersonPage extends StatefulWidget {
  const AddPersonPage({Key? key}) : super(key: key);

  @override
  State<AddPersonPage> createState() => _AddPersonPageState();
}

class _AddPersonPageState extends State<AddPersonPage> {
  final _storage = const FlutterSecureStorage();
  final _formKey = GlobalKey<FormState>();
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  // Form fields
  String name = '';
  String gender = 'male';
  String fatherName = '';
  String grandfatherName = '';
  String? motherName;

  // Auth state
  String? _jwtToken;
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  // GraphQL mutation
  final String createPersonMutation = """
    mutation CreatePerson(\$person: PersonInput!) {
      createPerson(person: \$person) {
        id
        name
        gender
        fatherName
      }
    }
  """;

  @override
  void initState() {
    super.initState();
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      if (token == null) {
        await _redirectToLogin();
        return;
      }

      setState(() {
        _jwtToken = token;
        _isLoading = false;
      });
    } catch (e) {
      _handleError('Initialization failed: ${e.toString()}');
    }
  }

  Future<bool> _verifyToken(String token) async {
    try {
      final response = await http.get(
        Uri.parse('http://127.0.0.1:8080/verify-token'), // Create this endpoint in FastAPI
        headers: {'Authorization': 'Bearer $token'},

      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<void> _redirectToLogin() async {
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  void _handleError(String message) {
    setState(() {
      _errorMessage = message;
      _isLoading = false;
      _isSubmitting = false;
    });
  }

  Future<void> _submitForm(RunMutation runMutation) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    _formKey.currentState!.save();

    try {
      runMutation({
        "person": {
          "name": name,
          "gender": gender,
          "fatherName": fatherName,
          "grandfatherName": grandfatherName,
          if (motherName != null) "motherName": motherName,
        }
      });
    } catch (e) {
      _handleError('Submission failed: ${e.toString()}');
    }
  }

  GraphQLClient _buildClient() {
    final httpLink = HttpLink(
      'http://127.0.0.1:8080/graphql',
      defaultHeaders: {
        'Authorization': 'Bearer $_jwtToken',
      },
    );

    return GraphQLClient(
      link: httpLink,
      cache: GraphQLCache(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_jwtToken == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Authentication required'),
              TextButton(
                onPressed: _redirectToLogin,
                child: const Text('Go to Login'),
              ),
            ],
          ),
        ),
      );
    }

    return GraphQLProvider(
      client: ValueNotifier(_buildClient()),
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: const Text("Add Family Member"),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await _storage.delete(key: 'jwt_token');
                _redirectToLogin();
              },
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Mutation(
            options: MutationOptions(
              document: gql(createPersonMutation),
              onCompleted: (dynamic resultData) {
                setState(() => _isSubmitting = false);

                final person = resultData?['createPerson'];
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Success'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Added: ${person?['name']}'),
                        Text('ID: ${person?['id']}'),
                      ],
                    ),
                    actions: [
                      TextButton(
                        child: const Text('OK'),
                        onPressed: () {
                          Navigator.pop(context);
                          _formKey.currentState?.reset();
                        },
                      ),
                    ],
                  ),
                );
              },
              onError: (error) {
                final message = error?.graphqlErrors.isNotEmpty == true
                    ? error!.graphqlErrors.first.message
                    : error?.linkException?.originalException?.toString() ?? "Unknown error";

                _handleError(message);

                // Special case for token expiration
                if (message.contains('expired') ){
                WidgetsBinding.instance.addPostFrameCallback((_) {
                showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => AlertDialog(
                title: const Text('Session Expired'),
                content: const Text('Please login again'),
                actions: [
                TextButton(
                child: const Text('OK'),
                onPressed: () {
                Navigator.pop(context);
                _redirectToLogin();
                },
                ),
                ],
                ),
                );
                });
                }
                },
            ),
            builder: (RunMutation runMutation, QueryResult? result) {
              return Column(
                children: [
                  if (_errorMessage != null)
                    _buildErrorTile(),
                  Expanded(
                    child: Form(
                      key: _formKey,
                      child: ListView(
                        children: [
                          _buildNameField(),
                          const SizedBox(height: 16),
                          _buildGenderDropdown(),
                          const SizedBox(height: 16),
                          _buildFatherNameField(),
                          const SizedBox(height: 16),
                          _buildGrandfatherNameField(),
                          const SizedBox(height: 16),
                          _buildMotherNameField(),
                          const SizedBox(height: 24),
                          _buildSubmitButton(runMutation),
                          if (_isSubmitting)
                            const Padding(
                              padding: EdgeInsets.only(top: 16.0),
                              child: LinearProgressIndicator(),
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
      ),
    );
  }

  Widget _buildErrorTile() {
    return Card(
      color: Colors.red[50],
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            const Icon(Icons.error, color: Colors.red),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => setState(() => _errorMessage = null),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      decoration: const InputDecoration(
        labelText: "Full Name",
        border: OutlineInputBorder(),
      ),
      validator: (val) => val!.isEmpty ? "Required" : null,
      onSaved: (val) => name = val!,
    );
  }

  Widget _buildGenderDropdown() {
    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(
        labelText: "Gender",
        border: OutlineInputBorder(),
      ),
      value: gender,
      items: const [
        DropdownMenuItem(value: 'male', child: Text('Male')),
        DropdownMenuItem(value: 'female', child: Text('Female')),
      ],
      onChanged: (val) => setState(() => gender = val!),
    );
  }

  Widget _buildFatherNameField() {
    return TextFormField(
      decoration: const InputDecoration(
        labelText: "Father's Name",
        border: OutlineInputBorder(),
      ),
      validator: (val) => val!.isEmpty ? "Required" : null,
      onSaved: (val) => fatherName = val!,
    );
  }

  Widget _buildGrandfatherNameField() {
    return TextFormField(
      decoration: const InputDecoration(
        labelText: "Grandfather's Name",
        border: OutlineInputBorder(),
      ),
      validator: (val) => val!.isEmpty ? "Required" : null,
      onSaved: (val) => grandfatherName = val!,
    );
  }

  Widget _buildMotherNameField() {
    return TextFormField(
      decoration: const InputDecoration(
        labelText: "Mother's Name (optional)",
        border: OutlineInputBorder(),
      ),
      onSaved: (val) => motherName = val,
    );
  }

  Widget _buildSubmitButton(RunMutation runMutation) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
        padding: const EdgeInsets.symmetric(vertical: 16),
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
        'Add Family Member',
        style: TextStyle(fontSize: 16),
      ),
    );
  }
}