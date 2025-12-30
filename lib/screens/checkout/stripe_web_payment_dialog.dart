import 'dart:async';
import 'dart:html' as html;
import 'dart:js' as js;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';
import '../../utils/theme.dart';

/// Web payment dialog using Stripe Elements
class StripeWebPaymentDialog extends StatefulWidget {
  final String clientSecret;
  final String publishableKey;
  final double amount;

  const StripeWebPaymentDialog({
    super.key,
    required this.clientSecret,
    required this.publishableKey,
    required this.amount,
  });

  @override
  State<StripeWebPaymentDialog> createState() => _StripeWebPaymentDialogState();
}

class _StripeWebPaymentDialogState extends State<StripeWebPaymentDialog> {
  bool _isProcessing = false;
  String? _errorMessage;
  String? _paymentMethodId;
  html.DivElement? _stripeContainer;
  bool _stripeInitialized = false;
  String? _containerId;
  final GlobalKey _stripeKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initializeStripeElements();
      });
    }
  }

  @override
  void dispose() {
    _cleanupStripe();
    super.dispose();
  }

  void _cleanupStripe() {
    if (_containerId != null) {
      final containerId = _containerId!;
      js.context.callMethod('eval', [
        '''
        (function() {
          if (window['stripeInstance_${containerId}']) {
            delete window['stripeInstance_${containerId}'];
          }
          if (window['cardElementInstance_${containerId}']) {
            try {
              window['cardElementInstance_${containerId}'].unmount();
            } catch(e) {}
            delete window['cardElementInstance_${containerId}'];
          }
        })()
        '''
      ]);
    }
    _stripeContainer?.remove();
  }

  void _initializeStripeElements() {
    // Wait for Stripe.js to load
    Timer.periodic(const Duration(milliseconds: 100), (timer) {
      final stripeAvailable = js.context.callMethod('eval', [
        'typeof Stripe !== "undefined"'
      ]);
      
      if (stripeAvailable == true) {
        timer.cancel();
        _setupStripeElements();
      } else if (timer.tick > 50) {
        timer.cancel();
        setState(() {
          _errorMessage = 'Stripe.js failed to load. Please refresh the page.';
        });
      }
    });
  }

  void _setupStripeElements() {
    _containerId = 'stripe-${DateTime.now().millisecondsSinceEpoch}';
    final containerId = _containerId!; // Non-null for use in this method
    
    // Create container div for Stripe Elements
    _stripeContainer = html.DivElement()
      ..id = containerId
      ..style.width = '100%'
      ..style.padding = '0';

    // Create cardholder name input
    final nameInput = html.InputElement()
      ..type = 'text'
      ..id = '${containerId}-name'
      ..placeholder = 'Cardholder Name'
      ..style.width = '100%'
      ..style.padding = '12px'
      ..style.marginBottom = '16px'
      ..style.border = '1px solid #e0e0e0'
      ..style.borderRadius = '4px'
      ..style.boxSizing = 'border-box'
      ..style.fontSize = '16px';

    // Create container for card element
    final cardContainer = html.DivElement()
      ..id = '${containerId}-card'
      ..style.padding = '12px'
      ..style.marginBottom = '8px'
      ..style.border = '1px solid #e0e0e0'
      ..style.borderRadius = '4px'
      ..style.backgroundColor = 'white';

    // Create error container
    final errorContainer = html.DivElement()
      ..id = '${containerId}-errors'
      ..setAttribute('role', 'alert')
      ..style.color = '#fa755a'
      ..style.fontSize = '14px'
      ..style.minHeight = '20px'
      ..style.marginBottom = '16px';

    _stripeContainer!.append(nameInput);
    _stripeContainer!.append(cardContainer);
    _stripeContainer!.append(errorContainer);

    // Append to body (will be positioned by Flutter)
    html.document.body?.append(_stripeContainer!);
    
    // Make sure container is visible initially (will be repositioned)
    _stripeContainer!.style.display = 'block';
    _stripeContainer!.style.visibility = 'visible';

    // Wait a bit for DOM to update, then initialize Stripe Elements
    Future.delayed(const Duration(milliseconds: 200), () {
      if (!mounted) return;
      _initializeStripeJS(containerId);
    });
  }

  void _initializeStripeJS(String containerId) {
    // Initialize Stripe Elements
    final initCode = '''
      (function() {
        console.log('Initializing Stripe Elements...');
        if (typeof Stripe === 'undefined') {
          console.error('Stripe is not defined!');
          return false;
        }
        try {
          var cardContainer = document.getElementById('${containerId}-card');
          if (!cardContainer) {
            console.error('Card container not found: #${containerId}-card');
            return false;
          }
          
          var stripe = Stripe("${widget.publishableKey}");
          var elements = stripe.elements();
          
          var cardElement = elements.create('card', {
            style: {
              base: {
                fontSize: '16px',
                color: '#32325d',
                fontFamily: '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif',
                '::placeholder': {
                  color: '#aab7c4',
                },
              },
              invalid: {
                color: '#fa755a',
              },
            },
          });
          
          cardElement.mount('#${containerId}-card');
          console.log('Stripe Elements mounted successfully');
          
          cardElement.on('change', function(event) {
            var displayError = document.getElementById('${containerId}-errors');
            if (displayError) {
              if (event.error) {
                displayError.textContent = event.error.message;
              } else {
                displayError.textContent = '';
              }
            }
          });
          
          window['stripeInstance_${containerId}'] = stripe;
          window['cardElementInstance_${containerId}'] = cardElement;
          console.log('Stripe initialized successfully');
          return true;
        } catch(e) {
          console.error('Stripe init error:', e);
          return false;
        }
      })()
    ''';

    try {
      final initialized = js.context.callMethod('eval', [initCode]);
      
      if (initialized == true) {
        // Wait a bit for Stripe to mount, then position and show
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            // Position the container first
            _positionContainer();
            
            // Then mark as initialized
            setState(() {
              _stripeInitialized = true;
            });
          }
        });
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = 'Failed to initialize Stripe Elements. Check browser console (F12) for errors.';
            _stripeInitialized = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error initializing Stripe: ${e.toString()}';
          _stripeInitialized = false;
        });
      }
    }
  }

  void _positionContainer() {
    // Use a timer to position the container after the widget is rendered
    int attempts = 0;
    Timer.periodic(const Duration(milliseconds: 100), (timer) {
      attempts++;
      final renderObject = _stripeKey.currentContext?.findRenderObject();
      if (renderObject != null && renderObject is RenderBox) {
        timer.cancel();
        
        final position = renderObject.localToGlobal(Offset.zero);
        final size = renderObject.size;
        
        if (_stripeContainer != null && size.width > 0 && size.height > 0) {
          _stripeContainer!.style.position = 'fixed';
          _stripeContainer!.style.left = '${position.dx}px';
          _stripeContainer!.style.top = '${position.dy}px';
          _stripeContainer!.style.width = '${size.width}px';
          _stripeContainer!.style.height = '${size.height}px';
          _stripeContainer!.style.maxWidth = '${size.width}px';
          _stripeContainer!.style.maxHeight = '${size.height}px';
          _stripeContainer!.style.zIndex = '10000';
          _stripeContainer!.style.backgroundColor = 'white';
          _stripeContainer!.style.padding = '16px';
          _stripeContainer!.style.boxSizing = 'border-box';
          _stripeContainer!.style.borderRadius = '8px';
          _stripeContainer!.style.boxShadow = '0 4px 6px rgba(0, 0, 0, 0.1)';
          _stripeContainer!.style.display = 'block';
          _stripeContainer!.style.visibility = 'visible';
          _stripeContainer!.style.overflow = 'hidden';
        }
      } else if (attempts > 30) {
        timer.cancel();
        // Fallback: center it on screen
        if (_stripeContainer != null) {
          final screenWidth = html.window.innerWidth ?? 500;
          final screenHeight = html.window.innerHeight ?? 600;
          final containerWidth = screenWidth > 500 ? 500 : screenWidth * 0.9;
          
          _stripeContainer!.style.position = 'fixed';
          _stripeContainer!.style.left = '50%';
          _stripeContainer!.style.top = '50%';
          _stripeContainer!.style.transform = 'translate(-50%, -50%)';
          _stripeContainer!.style.width = '${containerWidth}px';
          _stripeContainer!.style.height = '220px';
          _stripeContainer!.style.zIndex = '10000';
          _stripeContainer!.style.backgroundColor = 'white';
          _stripeContainer!.style.padding = '16px';
          _stripeContainer!.style.borderRadius = '8px';
          _stripeContainer!.style.boxShadow = '0 4px 6px rgba(0, 0, 0, 0.1)';
          _stripeContainer!.style.display = 'block';
          _stripeContainer!.style.visibility = 'visible';
        }
      }
    });
  }

  Future<void> _processPayment() async {
    if (!_stripeInitialized || _containerId == null) {
      setState(() {
        _errorMessage = 'Stripe Elements not initialized';
      });
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      // Get cardholder name
      final containerId = _containerId!;
      final nameInput = html.document.getElementById('${containerId}-name') as html.InputElement?;
      final cardholderName = nameInput?.value ?? '';

      // Create payment method using Stripe Elements
      final createPaymentMethodCode = '''
        (function() {
          var stripe = window['stripeInstance_${containerId}'];
          var cardElement = window['cardElementInstance_${containerId}'];
          
          if (!stripe || !cardElement) {
            return Promise.reject({error: {message: 'Stripe not initialized'}});
          }
          
          return stripe.createPaymentMethod({
            type: 'card',
            card: cardElement,
            billing_details: {
              name: "$cardholderName",
            },
          });
        })()
      ''';

      final promise = js.context.callMethod('eval', [createPaymentMethodCode]) as js.JsObject;
      
      promise.callMethod('then', [
        (js.JsObject result) {
          final error = result['error'];
          if (error != null) {
            final errorMsg = error['message']?.toString() ?? 'Failed to create payment method';
            if (mounted) {
              setState(() {
                _errorMessage = errorMsg;
                _isProcessing = false;
              });
            }
            return;
          }

          final paymentMethod = result['paymentMethod'];
          final paymentMethodId = paymentMethod['id']?.toString() ?? '';
          
          _paymentMethodId = paymentMethodId;
          _confirmPayment();
        }
      ]).callMethod('catch', [
        (js.JsObject error) {
          final errorMsg = error['message']?.toString() ?? 'Payment failed';
          if (mounted) {
            setState(() {
              _errorMessage = errorMsg;
              _isProcessing = false;
            });
          }
        }
      ]);
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isProcessing = false;
        });
      }
    }
  }

  void _confirmPayment() {
    if (_paymentMethodId == null || _containerId == null) {
      setState(() {
        _errorMessage = 'Payment method not created';
        _isProcessing = false;
      });
      return;
    }

    // Confirm payment
    final containerId = _containerId!;
    final confirmCode = '''
      (function() {
        var stripe = window['stripeInstance_${containerId}'];
        
        if (!stripe) {
          return Promise.reject({error: {message: 'Stripe not initialized'}});
        }
        
        return stripe.confirmCardPayment("${widget.clientSecret}", {
          payment_method: "$_paymentMethodId",
        });
      })()
    ''';

    final promise = js.context.callMethod('eval', [confirmCode]) as js.JsObject;
    
    promise.callMethod('then', [
      (js.JsObject result) {
        final error = result['error'];
        if (error != null) {
          final errorMsg = error['message']?.toString() ?? 'Payment failed';
          if (mounted) {
            setState(() {
              _errorMessage = errorMsg;
              _isProcessing = false;
            });
          }
          return;
        }

        final paymentIntent = result['paymentIntent'];
        final status = paymentIntent['status']?.toString() ?? '';

        if (status == 'succeeded' && mounted) {
          Navigator.of(context).pop({
            'status': 'succeeded',
            'paymentIntentId': paymentIntent['id']?.toString() ?? '',
          });
        } else if (mounted) {
          setState(() {
            _errorMessage = 'Payment not completed. Status: $status';
            _isProcessing = false;
          });
        }
      }
    ]).callMethod('catch', [
      (js.JsObject error) {
        final errorMsg = error['message']?.toString() ?? 'Payment confirmation failed';
        if (mounted) {
          setState(() {
            _errorMessage = errorMsg;
            _isProcessing = false;
          });
        }
      }
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    
    // Responsive sizing
    final dialogWidth = screenWidth > 600 
        ? 500.0 
        : screenWidth * 0.95; // 95% of screen width on small screens
    final maxDialogHeight = screenHeight * 0.9; // 90% of screen height
    final isSmallScreen = screenWidth < 600;

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 8.0 : 24.0,
        vertical: isSmallScreen ? 8.0 : 24.0,
      ),
      child: Container(
        width: dialogWidth,
        constraints: BoxConstraints(
          maxWidth: dialogWidth,
          maxHeight: maxDialogHeight,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header (fixed)
            Container(
              padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Payment',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 20.0 : 24.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: _isProcessing ? null : () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Amount: ${currencyFormat.format(widget.amount)}',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 16.0 : 18.0,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            
            // Scrollable content
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 16.0 : 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Stripe Elements container - positioned overlay
                    if (kIsWeb)
                      Container(
                        key: _stripeKey,
                        height: 220,
                        constraints: const BoxConstraints(
                          minHeight: 220,
                          maxHeight: 220,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: _stripeInitialized
                            ? const SizedBox.shrink() // Elements are in DOM overlay
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const CircularProgressIndicator(),
                                  const SizedBox(height: 16),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                    child: Text(
                                      _errorMessage ?? 'Loading Stripe Elements...',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: _errorMessage != null ? Colors.red : Colors.grey,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                      )
                    else
                      const Text('Stripe Elements only available on web'),
                    const SizedBox(height: 16),

                    // Test Card Info
                    Container(
                      padding: EdgeInsets.all(isSmallScreen ? 10.0 : 12.0),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline, size: isSmallScreen ? 14.0 : 16.0, color: Colors.blue[700]),
                              const SizedBox(width: 4),
                              Text(
                                'Test Card',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 11.0 : 12.0,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[700],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Card: 4242 4242 4242 4242\nExpiry: Any future date (e.g., 12/25)\nCVC: Any 3 digits (e.g., 123)',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 10.0 : 11.0,
                              color: Colors.blue[700],
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (_errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: EdgeInsets.all(isSmallScreen ? 10.0 : 12.0),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, size: isSmallScreen ? 18.0 : 20.0, color: Colors.red[700]),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 11.0 : 12.0,
                                  color: Colors.red[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            
            // Pay Button (fixed at bottom)
            Container(
              padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Colors.grey[200]!),
                ),
              ),
              child: SafeArea(
                child: ElevatedButton(
                  onPressed: (_isProcessing || !_stripeInitialized) ? null : _processPayment,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      vertical: isSmallScreen ? 14.0 : 16.0,
                    ),
                  ),
                  child: _isProcessing
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'Pay ${currencyFormat.format(widget.amount)}',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 16.0 : 18.0,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension MapToJs on Map<String, dynamic> {
  js.JsObject get toJs => js.JsObject.jsify(this);
}
