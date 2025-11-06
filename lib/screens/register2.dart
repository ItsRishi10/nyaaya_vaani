import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../main.dart';
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
        title: Text(context.watch<AppLocalizations>().getText('register_as_advocate')),
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
          child: SingleChildScrollView(
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
                        _obscurePassword ? FontAwesomeIcons.eyeSlash : FontAwesomeIcons.eye,
                        color: Colors.grey,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) => (v ?? '').isEmpty ? context.read<AppLocalizations>().getText('enter_password') : null,
                ),
                const SizedBox(height: 12),
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
                TextFormField(
                  controller: _enrollment,
                  decoration: InputDecoration(labelText: context.read<AppLocalizations>().getText('advocate_enrollment_number')),
                  validator: (v) => (v ?? '').isEmpty ? context.read<AppLocalizations>().getText('enter_enrollment_number') : null,
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

                      // Capture localized strings before awaiting to avoid using BuildContext across async gap
                      final userExistsMsg = context.read<AppLocalizations>().getText('user_already_exists');
                      final regSubmitted = context.read<AppLocalizations>().getText('registration_submitted');
                      final regCreated = context.read<AppLocalizations>().getText('registration_created_advocate');
                      final okText = context.read<AppLocalizations>().getText('ok');

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
                        setState(() { _error = userExistsMsg; });
                        return;
                      }
                      // Optionally show a success dialog for advocates on next frame to avoid async-context issues
                      if (mounted) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          showDialog(context: context, builder: (_) => AlertDialog(
                            title: Text(regSubmitted),
                            content: Text(regCreated),
                            actions: [
                              TextButton(onPressed: () { Navigator.pop(context); navigator.pop(); }, child: Text(okText))
                            ],
                          ));
                        });
                      }
                    },
                    child: _loading ? const CircularProgressIndicator(color: Colors.white) : Text(context.watch<AppLocalizations>().getText('register')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
