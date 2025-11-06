import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Survey page that presents questions as labeled input boxes (styled like the login page).
class SurveyPage extends StatefulWidget {
  const SurveyPage({super.key});

  @override
  State<SurveyPage> createState() => _SurveyPageState();
}

class _SurveyPageState extends State<SurveyPage> {
  static const String _prefsKey = 'survey_questions';

  final _formKey = GlobalKey<FormState>();
  bool _loading = true;
  bool _submitting = false;

  // questions: structured objects {text,type,options}
  List<Map<String, dynamic>> _questions = [];

  // controllers / selected answers
  final List<TextEditingController> _textControllers = [];
  final Map<int, String?> _mcqAnswers = {};

  // Use localization keys for default question texts/options so labels are localized via AppLocalizations
  final List<Map<String, dynamic>> _defaultQuestions = [
    {"text": 'topic_of_survey', "type": 'text', "options": []},
    {"text": 'purpose', "type": 'text', "options": []},
    {
      "text": 'user_type',
      "type": 'mcq',
      "options": [
        'user_type_option_political_party',
        'user_type_option_ngo',
        'user_type_option_welfare_association',
        'user_type_option_individual'
      ]
    },
    {"text": 'location_of_survey', "type": 'text', "options": []},
    {"text": 'no_of_respondents', "type": 'text', "options": []},
    {"text": 'mail_id', "type": 'text', "options": []},
    {"text": 'mobile_number', "type": 'text', "options": []},
  ];

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    setState(() => _loading = true);
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_prefsKey);
    if (raw == null || raw.isEmpty) {
      _questions = List.from(_defaultQuestions);
    } else {
      final parsed = <Map<String, dynamic>>[];
      for (final s in raw) {
        try {
          final obj = jsonDecode(s);
          if (obj is Map<String, dynamic> && obj.containsKey('text')) {
            parsed.add(obj);
            continue;
          }
        } catch (_) {}
        parsed.add({"text": s, "type": 'text', "options": []});
      }
      _questions = parsed;
    }
    _prepareControllers();
    if (mounted) setState(() => _loading = false);
  }

  void _prepareControllers() {
    for (final c in _textControllers) {
      c.dispose();
    }
    _textControllers.clear();
    _mcqAnswers.clear();
    for (int i = 0; i < _questions.length; i++) {
      final q = _questions[i];
      if (q['type'] == 'mcq') {
        _mcqAnswers[i] = null;
        _textControllers.add(TextEditingController());
      } else {
        _textControllers.add(TextEditingController());
      }
    }
  }

  @override
  void dispose() {
    for (final c in _textControllers) c.dispose();
    super.dispose();
  }

  //Future<void> _submit() async {
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    // simulate brief submission
    await Future.delayed(const Duration(milliseconds: 400));
    setState(() => _submitting = false);
    final loc = context.read<AppLocalizations>();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.getText('survey_submitted'))));
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<AppLocalizations>();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const FaIcon(FontAwesomeIcons.arrowLeft),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(loc.getText('survey')),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: _questions.length,
                        itemBuilder: (context, i) {
                          final q = _questions[i];
                          final qText = q['text'] as String? ?? '';
                          // If qText is a key in englishTexts, use localized text, otherwise use literal
                          final displayLabel = loc.englishTexts.containsKey(qText) ? loc.getText(qText) : qText;
                          if (q['type'] == 'mcq') {
                            final opts = (q['options'] as List<dynamic>?)?.cast<String>() ?? [];
                            if (opts.isEmpty) {
                              // show a friendly disabled field when no options are configured
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: InputDecorator(
                                  decoration: InputDecoration(labelText: qText),
                                    child: Text(loc.getText('no_options_configured')),
                                ),
                              );
                            }

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: DropdownButtonFormField<String>(
                                  decoration: InputDecoration(
                                    labelText: displayLabel,
                                    suffixIcon: const FaIcon(FontAwesomeIcons.angleDown), // Downward arrow
                                  ),
                                  initialValue: _mcqAnswers[i],
                                  items: opts.map((o) {
                                    final optLabel = loc.englishTexts.containsKey(o) ? loc.getText(o) : o;
                                    return DropdownMenuItem(value: o, child: Text(optLabel));
                                  }).toList(),
                                onChanged: (v) => setState(() => _mcqAnswers[i] = v),
                                validator: (v) => (v == null || v.isEmpty) ? loc.getText('please_select') : null,
                              ),
                            );
                          }

                            final controller = i < _textControllers.length ? _textControllers[i] : null;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: TextFormField(
                                controller: controller,
                                decoration: InputDecoration(labelText: displayLabel),
                                validator: (v) => (v ?? '').isEmpty ? loc.getText('enter_text') : null,
                              ),
                            );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _submitting ? null : _submit,
                      child: _submitting ? const CircularProgressIndicator(color: Colors.white) : Text(loc.getText('submit')),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
