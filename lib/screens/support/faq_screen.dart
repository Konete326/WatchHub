import 'package:flutter/material.dart';
import '../../services/support_service.dart';
import '../../models/faq.dart';

class FAQScreen extends StatefulWidget {
  const FAQScreen({super.key});

  @override
  State<FAQScreen> createState() => _FAQScreenState();
}

class _FAQScreenState extends State<FAQScreen> {
  final SupportService _supportService = SupportService();
  List<FAQ> _faqs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFAQs();
  }

  Future<void> _loadFAQs() async {
    try {
      final result = await _supportService.getFAQs();
      setState(() {
        _faqs = result['faqs'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FAQ'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _faqs.isEmpty
              ? const Center(child: Text('No FAQs available'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _faqs.length,
                  itemBuilder: (context, index) {
                    final faq = _faqs[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ExpansionTile(
                        title: Text(
                          faq.question,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(faq.answer),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}

