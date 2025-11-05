import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class RegisterAdvocatePage extends StatefulWidget {
  const RegisterAdvocatePage({super.key});

  @override
  State<RegisterAdvocatePage> createState() => _RegisterAdvocatePageState();
}

class _RegisterAdvocatePageState extends State<RegisterAdvocatePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _username = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _aadhar = TextEditingController();
  final TextEditingController _enrollment = TextEditingController();
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
        title: const Text('Advocate Register')
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _email,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => (v ?? '').isEmpty ? 'Enter email' : null,
                ),
                const SizedBox(height: 12),
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
                        _obscurePassword ? FontAwesomeIcons.eyeSlash : FontAwesomeIcons.eye,
                        color: Colors.grey,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) => (v ?? '').isEmpty ? 'Enter password' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phone,
                  decoration: const InputDecoration(labelText: 'Phone Number'),
                  keyboardType: TextInputType.phone,
                  validator: (v) => (v ?? '').isEmpty ? 'Enter phone number' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _aadhar,
                  decoration: const InputDecoration(labelText: 'Aadhar Number'),
                  keyboardType: TextInputType.number,
                  validator: (v) => (v ?? '').isEmpty ? 'Enter Aadhar number' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _enrollment,
                  decoration: const InputDecoration(labelText: 'Advocate Enrollment Number'),
                  validator: (v) => (v ?? '').isEmpty ? 'Enter enrollment number' : null,
                ),
                const SizedBox(height: 16),
                if (_error != null)
                  Text(_error!, style: TextStyle(color: Colors.red)),
                ElevatedButton(
                  onPressed: _loading ? null : () async {
                    if (!_formKey.currentState!.validate()) return;
                    setState(() { _loading = true; _error = null; });
                    final auth = context.read<AuthService>();
                    final navigator = Navigator.of(context);
                    final metadata = {
                      'email': _email.text.trim(),
                      'phone': _phone.text.trim(),
                      'aadhar': _aadhar.text.trim(),
                      'role': 'advocate',
                      'enrollment': _enrollment.text.trim(),
                    };
                    final ok = await auth.register(_username.text.trim(), _password.text, isAdmin: false, metadata: metadata);
                    if (!mounted) return;
                    setState(() { _loading = false; });
                    if (!ok) {
                      setState(() { _error = 'User already exists'; });
                      return;
                    }
                    // Optionally show a success dialog for advocates
                    showDialog(context: context, builder: (_) => AlertDialog(
                      title: const Text('Registration submitted'),
                      content: const Text('Your advocate registration is created.'),
                      actions: [
                        TextButton(onPressed: () { Navigator.pop(context); navigator.pop(); }, child: const Text('OK'))
                      ],
                    ));
                  },
                  child: _loading ? CircularProgressIndicator(color: Colors.white) : const Text('Register Advocate'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
