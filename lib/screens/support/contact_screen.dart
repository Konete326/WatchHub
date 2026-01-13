import 'package:flutter/material.dart';
import '../../services/support_service.dart';
import '../../models/support_ticket.dart';
import '../../utils/theme.dart';
import '../../widgets/neumorphic_widgets.dart';

class ContactScreen extends StatefulWidget {
  final SupportTicket? ticket;
  const ContactScreen({super.key, this.ticket});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  final SupportService _supportService = SupportService();
  bool _isSubmitting = false;

  String _selectedPriority = 'MEDIUM';
  String? _selectedCategory;
  final List<String> _priorities = ['LOW', 'MEDIUM', 'HIGH', 'URGENT'];
  final List<String> _categories = [
    'Product',
    'Order',
    'Shipping',
    'Payment',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.ticket != null) {
      _subjectController.text = widget.ticket!.subject;
      _messageController.text = widget.ticket!.message;
      _selectedPriority = widget.ticket!.priority;
      _selectedCategory = widget.ticket!.category;
    }
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submitTicket() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      if (widget.ticket != null) {
        await _supportService.updateTicket(
          id: widget.ticket!.id,
          subject: _subjectController.text.trim(),
          message: _messageController.text.trim(),
          priority: _selectedPriority,
          status: widget.ticket!.status,
        );
      } else {
        await _supportService.createTicket(
          subject: _subjectController.text.trim(),
          message: _messageController.text.trim(),
          priority: _selectedPriority,
          category: _selectedCategory,
        );
      }

      if (!mounted) return;

      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.ticket != null
              ? 'Ticket updated successfully'
              : 'Support ticket created successfully'),
          backgroundColor: AppTheme.successColor,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.softUiBackground,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(90),
        child: NeumorphicTopBar(
          title: widget.ticket != null ? 'Edit Ticket' : 'Contact Support',
          onBackTap: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildDropdownField(
                label: 'Category',
                value: _selectedCategory,
                items: _categories,
                onChanged: (v) => setState(() => _selectedCategory = v),
              ),
              const SizedBox(height: 24),
              _buildDropdownField(
                label: 'Priority',
                value: _selectedPriority,
                items: _priorities,
                onChanged: (v) => setState(() => _selectedPriority = v!),
              ),
              const SizedBox(height: 24),
              _buildInputField(
                label: 'Subject',
                controller: _subjectController,
                icon: Icons.subject_rounded,
                hintText: 'What can we help you with?',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a subject';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              _buildInputField(
                label: 'Message',
                controller: _messageController,
                icon: Icons.message_rounded,
                hintText: 'Describe your issue in detail...',
                maxLines: 6,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a message';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 40),
              NeumorphicButton(
                onTap: _isSubmitting ? () {} : _submitTicket,
                padding: const EdgeInsets.symmetric(vertical: 20),
                borderRadius: BorderRadius.circular(15),
                isPressed: _isSubmitting,
                child: Center(
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: AppTheme.primaryColor,
                          ),
                        )
                      : const Text(
                          'Submit Ticket',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.softUiTextColor,
          ),
        ),
        const SizedBox(height: 12),
        NeumorphicContainer(
          isConcave: true,
          borderRadius: BorderRadius.circular(15),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              hint: Text('Select $label'),
              items: items
                  .map((i) => DropdownMenuItem(value: i, child: Text(i)))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String hintText,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.softUiTextColor,
          ),
        ),
        const SizedBox(height: 12),
        NeumorphicContainer(
          isConcave: true,
          borderRadius: BorderRadius.circular(15),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: TextFormField(
            controller: controller,
            maxLines: maxLines,
            style: const TextStyle(color: AppTheme.softUiTextColor),
            cursorColor: AppTheme.primaryColor,
            decoration: InputDecoration(
              prefixIcon: Icon(
                icon,
                color: AppTheme.softUiTextColor.withOpacity(0.5),
              ),
              hintText: hintText,
              hintStyle: TextStyle(
                color: AppTheme.softUiTextColor.withOpacity(0.3),
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorStyle: const TextStyle(height: 0, color: Colors.transparent),
            ),
            validator: validator,
          ),
        ),
      ],
    );
  }
}
