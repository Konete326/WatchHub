import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/theme.dart';
import '../../widgets/neumorphic_widgets.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  // No initial dummy data
  final List<Map<String, dynamic>> _paymentMethods = [];

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Controllers for form input
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();
  final TextEditingController _cardHolderController = TextEditingController();

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _cardHolderController.dispose();
    super.dispose();
  }

  // Helper to determine card brand
  String _getCardType(String number) {
    if (number.startsWith('4')) return 'Visa';
    if (number.startsWith('5')) return 'Mastercard';
    if (number.startsWith('3')) return 'Amex';
    return 'Visa'; // Default
  }

  Color _getCardColor(String type) {
    switch (type) {
      case 'Visa':
        return const Color(0xFF1A1F71);
      case 'Mastercard':
        return const Color(0xFF222222);
      case 'Amex':
        return const Color(0xFF006FCF);
      default:
        return const Color(0xFF1A1F71);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.softUiBackground,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: NeumorphicTopBar(
          title: 'Payment Methods',
          onBackTap: () => Navigator.pop(context),
          actions: [
            NeumorphicButton(
              onTap: _addNewCard,
              padding: const EdgeInsets.all(10),
              shape: BoxShape.circle,
              child: const Icon(Icons.add_rounded,
                  color: AppTheme.primaryColor, size: 20),
            ),
          ],
        ),
      ),
      body: _paymentMethods.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: _paymentMethods.length,
              itemBuilder: (context, index) {
                final card = _paymentMethods[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: _buildPaymentCard(card),
                );
              },
            ),
    );
  }

  Widget _buildPaymentCard(Map<String, dynamic> card) {
    return NeumorphicContainer(
      borderRadius: BorderRadius.circular(20),
      padding: const EdgeInsets.all(0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Card visual
            Container(
              height: 200,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    card['color'],
                    (card['color'] as Color).withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(
                        card['type'] == 'Visa'
                            ? Icons.payment
                            : Icons.credit_card,
                        color: Colors.white,
                        size: 32,
                      ),
                      if (card['isDefault'])
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'DEFAULT',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  Text(
                    '**** **** **** ${card['last4']}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CARD HOLDER',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            card['holder'].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'EXPIRES',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            card['expiry'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Actions overlay
            Positioned(
              top: 8,
              right: 8,
              child: PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onSelected: (value) {
                  if (value == 'delete') {
                    _deleteCard(card['id']);
                  } else if (value == 'default') {
                    _setDefault(card['id']);
                  }
                },
                itemBuilder: (context) => [
                  if (!card['isDefault'])
                    const PopupMenuItem(
                      value: 'default',
                      child: Text('Set as Default'),
                    ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Remove Card',
                        style: TextStyle(color: AppTheme.errorColor)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          NeumorphicContainer(
            shape: BoxShape.circle,
            padding: const EdgeInsets.all(40),
            isConcave: true,
            child: Icon(
              Icons.credit_card_off_rounded,
              size: 60,
              color: AppTheme.softUiTextColor.withOpacity(0.2),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Payment Methods',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.softUiTextColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Add a card to speed up your checkout.',
            style: TextStyle(
              color: AppTheme.softUiTextColor.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 32),
          NeumorphicButton(
            onTap: _addNewCard,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            borderRadius: BorderRadius.circular(16),
            child: const Text(
              'Add Card',
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _addNewCard() {
    _cardNumberController.clear();
    _expiryController.clear();
    _cvvController.clear();
    _cardHolderController.clear();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.softUiBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Add New Card'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Enter card details below.'),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cardNumberController,
                decoration: const InputDecoration(
                  labelText: 'Card Number',
                  hintText: '0000 0000 0000 0000',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.credit_card),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(16),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter card number';
                  }
                  if (value.length < 16) {
                    return 'Card number must be 16 digits';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _expiryController,
                      decoration: const InputDecoration(
                        labelText: 'Expiry',
                        hintText: 'MM/YY',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.datetime,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(5),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(value)) {
                          return 'Invalid format';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _cvvController,
                      decoration: const InputDecoration(
                        labelText: 'CVV',
                        hintText: '123',
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(3),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        if (value.length < 3) {
                          return 'Invalid CVV';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _cardHolderController,
                decoration: const InputDecoration(
                  labelText: 'Card Holder',
                  hintText: 'Name on card',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter name';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                final last4 = _cardNumberController.text.substring(12, 16);
                final type = _getCardType(_cardNumberController.text);

                setState(() {
                  _paymentMethods.add({
                    'id': DateTime.now().toString(),
                    'type': type,
                    'last4': last4,
                    'expiry': _expiryController.text,
                    'holder': _cardHolderController.text,
                    'isDefault':
                        _paymentMethods.isEmpty, // First card is default
                    'color': _getCardColor(type),
                  });
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Card added successfully')));
              }
            },
            child: const Text('Add Card',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _deleteCard(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Card'),
        content: const Text('Are you sure you want to remove this card?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _paymentMethods.removeWhere((card) => card['id'] == id);
              });
              Navigator.pop(context);
            },
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _setDefault(String id) {
    setState(() {
      for (var card in _paymentMethods) {
        card['isDefault'] = card['id'] == id;
      }
    });
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Default card updated')));
  }
}
