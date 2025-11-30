import 'package:flutter/material.dart';
import '../utils/slide_route.dart';
import 'question_flow_screen.dart';

class NameAgeScreen extends StatefulWidget {
  const NameAgeScreen({super.key});

  @override
  State<NameAgeScreen> createState() => _NameAgeScreenState();
}

class _NameAgeScreenState extends State<NameAgeScreen> {
  final _nameCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    super.dispose();
  }

  void _next() {
    final name = _nameCtrl.text.trim();
    final ageText = _ageCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name')),
      );
      return;
    }

    final age = int.tryParse(ageText);

    Navigator.of(context).push(
      slideFromRight(
        QuestionFlowScreen(displayName: name, age: age ?? 0),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tell us about you'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Your name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _ageCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Age (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _next,
                child: const Text('Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
