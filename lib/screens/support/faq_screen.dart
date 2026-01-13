import 'package:flutter/material.dart';
import '../../services/support_service.dart';
import '../../models/faq.dart';
import '../../utils/theme.dart';
import '../../widgets/neumorphic_widgets.dart';
import '../../utils/error_handler.dart';

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
      if (mounted) {
        setState(() {
          _faqs = (result['faqs'] as List).cast<FAQ>();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(FirebaseErrorHandler.getMessage(e)),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
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
          title: 'FAQ',
          onBackTap: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const _NeumorphicLoadingIndicator()
          : _faqs.isEmpty
              ? const Center(
                  child: Text(
                    'No FAQs available',
                    style: TextStyle(
                      color: AppTheme.softUiTextColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: _faqs.length,
                  physics: const BouncingScrollPhysics(),
                  itemBuilder: (context, index) {
                    return _FAQItem(faq: _faqs[index]);
                  },
                ),
    );
  }
}

class _FAQItem extends StatefulWidget {
  final FAQ faq;
  const _FAQItem({required this.faq});

  @override
  State<_FAQItem> createState() => _FAQItemState();
}

class _FAQItemState extends State<_FAQItem> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: NeumorphicContainer(
        borderRadius: BorderRadius.circular(20),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.faq.question,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.softUiTextColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  NeumorphicContainer(
                    isConcave: _isExpanded,
                    shape: BoxShape.circle,
                    padding: const EdgeInsets.all(8),
                    child: AnimatedRotation(
                      turns: _isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(
                        Icons.expand_more_rounded,
                        size: 20,
                        color: AppTheme.softUiTextColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox(width: double.infinity),
              secondChild: Column(
                children: [
                  const SizedBox(height: 20),
                  NeumorphicContainer(
                    isConcave: true,
                    borderRadius: BorderRadius.circular(15),
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      widget.faq.answer,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.softUiTextColor.withOpacity(0.8),
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
              crossFadeState: _isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 200),
            ),
          ],
        ),
      ),
    );
  }
}

class _NeumorphicLoadingIndicator extends StatefulWidget {
  const _NeumorphicLoadingIndicator();

  @override
  State<_NeumorphicLoadingIndicator> createState() =>
      _NeumorphicLoadingIndicatorState();
}

class _NeumorphicLoadingIndicatorState
    extends State<_NeumorphicLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ScaleTransition(
        scale: _animation,
        child: const NeumorphicContainer(
          isConcave: true,
          shape: BoxShape.circle,
          padding: EdgeInsets.all(30),
          child: Icon(
            Icons.help_outline_rounded,
            color: AppTheme.primaryColor,
            size: 40,
          ),
        ),
      ),
    );
  }
}
