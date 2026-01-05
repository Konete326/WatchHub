import 'package:flutter/material.dart';
import 'package:animations/animations.dart';
import '../../utils/animation_utils.dart';
import '../../utils/theme.dart';
import 'faq_screen.dart';
import 'tickets_screen.dart';
import 'contact_screen.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Support'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: InkWell(
              onTap: () {
                AnimationUtils.pushSharedAxis(
                  context,
                  const FAQScreen(),
                  transitionType: SharedAxisTransitionType.vertical,
                );
              },
              child: const Padding(
                padding: EdgeInsets.all(20),
                child: Row(
                  children: [
                    Icon(Icons.help_outline, size: 32, color: AppTheme.primaryColor),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'FAQ',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text('Frequently Asked Questions'),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: InkWell(
              onTap: () {
                AnimationUtils.pushSharedAxis(
                  context,
                  const ContactScreen(),
                  transitionType: SharedAxisTransitionType.vertical,
                );
              },
              child: const Padding(
                padding: EdgeInsets.all(20),
                child: Row(
                  children: [
                    Icon(Icons.message, size: 32, color: AppTheme.primaryColor),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Contact Us',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text('Send us a message'),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: InkWell(
              onTap: () {
                AnimationUtils.pushSharedAxis(
                  context,
                  const TicketsScreen(),
                  transitionType: SharedAxisTransitionType.vertical,
                );
              },
              child: const Padding(
                padding: EdgeInsets.all(20),
                child: Row(
                  children: [
                    Icon(Icons.receipt_long, size: 32, color: AppTheme.primaryColor),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'My Tickets',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text('View your support tickets'),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

