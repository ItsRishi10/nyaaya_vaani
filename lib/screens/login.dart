import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _username = TextEditingController();
  final TextEditingController _password = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: FaIcon(FontAwesomeIcons.arrowLeft),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Login')
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _username,
                decoration: const InputDecoration(labelText: 'Username'),
                validator: (v) => (v ?? '').isEmpty ? 'Enter username' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _password,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  suffixIcon: IconButton(
                    icon: FaIcon(
                      _obscurePassword
                          ? FontAwesomeIcons.eyeSlash
                          : FontAwesomeIcons.eye,
                      color: Colors.grey,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                validator: (v) => (v ?? '').isEmpty ? 'Enter password' : null,
              ),
              const SizedBox(height: 16),
              if (_error != null)
                Text(_error!, style: TextStyle(color: Colors.red)),
              ElevatedButton(
                onPressed: _loading ? null : () async {
                  if (!_formKey.currentState!.validate()) return;
                  setState(() { _loading = true; _error = null; });
                  final auth = context.read<AuthService>();
                  final ok = await auth.login(_username.text.trim(), _password.text);
                  setState(() { _loading = false; });
                  if (!ok) {
                    setState(() { _error = 'Invalid credentials'; });
                    return;
                  }
                  // on success, Navigator will be handled by listening provider in the app
                },
                child: _loading ? CircularProgressIndicator(color: Colors.white) : const Text('Login'),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
