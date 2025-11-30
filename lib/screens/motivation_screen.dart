import 'package:flutter/material.dart';

import 'question_flow_screen.dart';

class MotivationScreen extends StatefulWidget {
  final String displayName;
  final int age;

  const MotivationScreen({
    super.key,
    required this.displayName,
    required this.age,
  });

  @override
  State<MotivationScreen> createState() => _MotivationScreenState();
}

class _MotivationScreenState extends State<MotivationScreen> {
  String? _motivation;

  void _continue() {
    if (_motivation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a motivation")),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuestionFlowScreen(
          displayName: widget.displayName,
          age: widget.age,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final options = [
      "Improve health",
      "Increase focus",
      "Boost discipline",
      "Reduce stress",
      "Study better",
      "Fix sleep schedule",
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Why do you want to improve?"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              "Select your primary motivation:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: options.length,
                itemBuilder: (_, index) {
                  final item = options[index];
                  final selected = item == _motivation;

                  return Card(
                    child: ListTile(
                      title: Text(item),
                      trailing: selected
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : const Icon(Icons.circle_outlined),
                      onTap: () {
                        setState(() => _motivation = item);
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _continue,
                child: const Text("Continue"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
