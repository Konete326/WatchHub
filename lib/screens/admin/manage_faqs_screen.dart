import 'package:flutter/material.dart';
import '../../services/admin_service.dart';
import '../../services/support_service.dart';
import '../../models/faq.dart';
import '../../utils/theme.dart';

class ManageFAQsScreen extends StatefulWidget {
  const ManageFAQsScreen({super.key});

  @override
  State<ManageFAQsScreen> createState() => _ManageFAQsScreenState();
}

class _ManageFAQsScreenState extends State<ManageFAQsScreen> {
  final AdminService _adminService = AdminService();
  final SupportService _supportService = SupportService();
  final TextEditingController _searchController = TextEditingController();
  
  List<FAQ> _faqs = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadFAQs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFAQs() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Use support service to get FAQs (public endpoint)
      final result = await _supportService.getFAQs();
      
      if (mounted) {
        setState(() {
          _faqs = result['faqs'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load FAQs: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showAddEditDialog({FAQ? faq}) async {
    final questionController = TextEditingController(text: faq?.question ?? '');
    final answerController = TextEditingController(text: faq?.answer ?? '');
    final categoryController = TextEditingController(text: faq?.category ?? '');
    String? selectedCategory = faq?.category;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(faq != null ? 'Edit FAQ' : 'Add FAQ'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: questionController,
                  decoration: const InputDecoration(
                    labelText: 'Question *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: answerController,
                  decoration: const InputDecoration(
                    labelText: 'Answer *',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category *',
                    border: OutlineInputBorder(),
                  ),
                  items: ['General', 'Shipping', 'Returns', 'Payment', 'Products'].map((cat) {
                    return DropdownMenuItem(
                      value: cat,
                      child: Text(cat),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() => selectedCategory = value);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (questionController.text.isEmpty ||
                    answerController.text.isEmpty ||
                    selectedCategory == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill all required fields')),
                  );
                  return;
                }

                try {
                  if (faq != null) {
                    await _adminService.updateFAQ(
                      id: faq.id,
                      question: questionController.text,
                      answer: answerController.text,
                      category: selectedCategory!,
                    );
                  } else {
                    await _adminService.createFAQ(
                      question: questionController.text,
                      answer: answerController.text,
                      category: selectedCategory!,
                    );
                  }
                  
                  if (mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(faq != null ? 'FAQ updated' : 'FAQ created')),
                    );
                    _loadFAQs();
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to save FAQ: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: Text(faq != null ? 'Update' : 'Create'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteFAQ(String id, String question) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete FAQ'),
        content: Text('Are you sure you want to delete "$question"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _adminService.deleteFAQ(id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('FAQ deleted successfully')),
          );
          _loadFAQs();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete FAQ: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage FAQs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddEditDialog(),
            tooltip: 'Add FAQ',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadFAQs,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _faqs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.help_outline, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'No FAQs found',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadFAQs,
                      child: ListView.builder(
                        itemCount: _faqs.length,
                        padding: const EdgeInsets.all(16),
                        itemBuilder: (context, index) {
                          final faq = _faqs[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ExpansionTile(
                              title: Text(
                                faq.question,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(faq.category),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(faq.answer),
                                      const SizedBox(height: 16),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          TextButton.icon(
                                            icon: const Icon(Icons.edit),
                                            label: const Text('Edit'),
                                            onPressed: () => _showAddEditDialog(faq: faq),
                                          ),
                                          TextButton.icon(
                                            icon: const Icon(Icons.delete, color: Colors.red),
                                            label: const Text('Delete', style: TextStyle(color: Colors.red)),
                                            onPressed: () => _deleteFAQ(faq.id, faq.question),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}

