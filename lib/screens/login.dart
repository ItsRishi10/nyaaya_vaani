import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../main.dart';
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
    final loc = context.watch<AppLocalizations>();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: FaIcon(FontAwesomeIcons.arrowLeft),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(loc.getText('login')),
        actions: [
          IconButton(
            icon: loc.isTranslating
                ? const SizedBox(
                    width: 20, 
                    height: 20, 
                    child: CircularProgressIndicator(strokeWidth: 2)
                  )
                : FaIcon(FontAwesomeIcons.globe),
            onPressed: loc.isTranslating ? null : () => context.read<AppLocalizations>().toggleLanguage(),
          )
        ],
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
                decoration: InputDecoration(labelText: loc.getText('username')),
                validator: (v) => (v ?? '').isEmpty ? loc.getText('enter_username') : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _password,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: loc.getText('password'),
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
                validator: (v) => (v ?? '').isEmpty ? loc.getText('enter_password') : null,
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
                  final ok = await auth.login(_username.text.trim(), _password.text);
                  setState(() { _loading = false; });
                  if (!ok) {
                    setState(() { _error = loc.getText('invalid_credentials'); });
                    return;
                  }
                  // on success, navigate to DashboardPage directly since Home is not the auth-gate
                  if (!mounted) return;
                  navigator.pushReplacement(MaterialPageRoute(builder: (_) => const DashboardPage()));
                },
                child: _loading ? const CircularProgressIndicator(color: Colors.white) : Text(loc.getText('login')),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
