import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../main.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _username = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _aadhar = TextEditingController();
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
        title: Text(context.watch<AppLocalizations>().getText('register')),
        actions: [
          IconButton(
            icon: context.watch<AppLocalizations>().isTranslating
                ? const SizedBox(
                    width: 20, 
                    height: 20, 
                    child: CircularProgressIndicator(strokeWidth: 2)
                  )
                : FaIcon(FontAwesomeIcons.globe),
            onPressed: context.watch<AppLocalizations>().isTranslating
                ? null
                : () => context.read<AppLocalizations>().toggleLanguage(),
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
                controller: _email,
                decoration: InputDecoration(labelText: context.read<AppLocalizations>().getText('email')),
                keyboardType: TextInputType.emailAddress,
                validator: (v) => (v ?? '').isEmpty ? context.read<AppLocalizations>().getText('enter_email') : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _username,
                decoration: InputDecoration(labelText: context.read<AppLocalizations>().getText('username')),
                validator: (v) => (v ?? '').isEmpty ? context.read<AppLocalizations>().getText('enter_username') : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _password,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: context.read<AppLocalizations>().getText('password'),
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
                validator: (v) => (v ?? '').isEmpty ? context.read<AppLocalizations>().getText('enter_password') : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phone,
                decoration: InputDecoration(labelText: context.read<AppLocalizations>().getText('phone_number')),
                keyboardType: TextInputType.phone,
                validator: (v) => (v ?? '').isEmpty ? context.read<AppLocalizations>().getText('enter_phone_number') : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _aadhar,
                decoration: InputDecoration(labelText: context.read<AppLocalizations>().getText('aadhar_number')),
                keyboardType: TextInputType.number,
                validator: (v) => (v ?? '').isEmpty ? context.read<AppLocalizations>().getText('enter_aadhar_number') : null,
              ),
              const SizedBox(height: 12),
              if (_error != null)
                Text(_error!, style: TextStyle(color: Colors.red)),
              ElevatedButton(
                onPressed: _loading ? null : () async {
                  if (!_formKey.currentState!.validate()) return;
                  setState(() { _loading = true; _error = null; });
                  final auth = context.read<AuthService>();
                  // Capture navigator before awaiting to avoid using BuildContext after await
                  final navigator = Navigator.of(context);
                  // Citizen registration (non-advocate)
                  final metadata = {
                    'email': _email.text.trim(),
                    'phone': _phone.text.trim(),
                    'aadhar': _aadhar.text.trim(),
                    'role': 'citizen',
                  };
                  final ok = await auth.register(_username.text.trim(), _password.text, isAdmin: false, metadata: metadata);
                  if (!mounted) return;
                  setState(() { _loading = false; });
                  if (!ok) {
                    setState(() { _error = context.read<AppLocalizations>().getText('user_already_exists'); });
                    return;
                  }
                  // auto-logged in after register; pop back
                  navigator.pop();
                },
                child: _loading ? const CircularProgressIndicator(color: Colors.white) : Text(context.watch<AppLocalizations>().getText('register')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
