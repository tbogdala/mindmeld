import 'package:flutter/material.dart';

class EditLorebooksPage extends StatefulWidget {
  final String appTitle = 'MindMeld';
  final bool isFullPage;

  const EditLorebooksPage({super.key, required this.isFullPage});

  @override
  State<EditLorebooksPage> createState() => _EditLorebooksPageState();
}

class _EditLorebooksPageState extends State<EditLorebooksPage> {
  Widget buildInner(BuildContext context) {
    return const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Lorebook Editor'),
        ]);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isFullPage) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Edit Lorebooks'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: buildInner(context),
          ),
        ),
      );
    } else {
      return buildInner(context);
    }
  }
}
