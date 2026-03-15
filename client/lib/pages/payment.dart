import 'dart:convert';

import 'package:client/pages/dto/create_payment.dart';
import 'package:client/pages/dto/payment_verification.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:razorpay_flutter/razorpay_flutter.dart';

class Payment extends StatefulWidget {
  const Payment({super.key});

  @override
  State<Payment> createState() => _PaymentState();
}

class _PaymentState extends State<Payment> {
  static const _defaultAmount = '499';
  static const _defaultName = 'Test User';
  static const _defaultEmail = 'test.user@example.com';
  static const _defaultContact = '9876543210';

  final Razorpay razorpay = Razorpay();
  final TextEditingController _amountController = TextEditingController(
    text: _defaultAmount,
  );
  final TextEditingController _nameController = TextEditingController(
    text: _defaultName,
  );
  final TextEditingController _emailController = TextEditingController(
    text: _defaultEmail,
  );
  final TextEditingController _contactController = TextEditingController(
    text: _defaultContact,
  );
  final String? _baseUrl = dotenv.env['BASE_URL'];
  final String _razorpayKeyId = dotenv.env['RAZORPAY_KEY']!;

  bool _isProcessing = false;
  PaymentVerificationResponse? _latestVerification;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _contactController.dispose();
    razorpay.clear();
    super.dispose();
  }

  Future<CreatePaymentResponse> handleCreatePayment(
    CreatePaymentRequest request,
  ) async {
    final response = await http.post(
      Uri.parse("$_baseUrl/payments/create"),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to create payment: ${response.body}');
    }

    return CreatePaymentResponse.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<PaymentVerificationResponse> handlePaymentVerification(
    PaymentVerificationRequest request,
  ) async {
    final response = await http.post(
      Uri.parse("$_baseUrl/payments/verify"),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to verify payment: ${response.body}');
    }

    return PaymentVerificationResponse.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<void> _startPayment() async {
    FocusScope.of(context).unfocus();

    final amountRupees = int.tryParse(_amountController.text.trim());
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final contact = _contactController.text.trim();

    if (amountRupees == null || amountRupees <= 0) {
      _showSnackBar('Enter a valid amount in rupees.', isError: true);
      return;
    }

    if (name.isEmpty) {
      _showSnackBar('Enter customer name.', isError: true);
      return;
    }

    if (email.isEmpty || !email.contains('@')) {
      _showSnackBar('Enter a valid email.', isError: true);
      return;
    }

    if (contact.length < 10) {
      _showSnackBar('Enter a valid contact number.', isError: true);
      return;
    }

    setState(() {
      _isProcessing = true;
      _latestVerification = null;
      _statusMessage = 'Creating Razorpay order...';
    });

    try {
      final order = await handleCreatePayment(
        CreatePaymentRequest(amount: amountRupees * 100, currency: 'INR'),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _statusMessage = 'Opening Razorpay checkout...';
      });

      razorpay.open({
        'key': _razorpayKeyId,
        'amount': order.amount,
        'currency': order.currency,
        'order_id': order.orderId,
        'name': 'Razorpay Demo',
        'description': 'Demo payment for Flutter client',
        'prefill': {'name': name, 'email': email, 'contact': contact},
        'notes': {'receipt': order.receipt},
        'theme': {'color': '#1D4ED8'},
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isProcessing = false;
        _statusMessage = null;
      });

      _showSnackBar(
        _normalizeMessage(error.toString(), fallback: 'Payment failed.'),
        isError: true,
      );
    }
  }

  Future<void> _handlePaymentSuccess(PaymentSuccessResponse response) async {
    setState(() {
      _statusMessage = 'Verifying payment on server...';
    });

    try {
      final verification = await handlePaymentVerification(
        PaymentVerificationRequest(
          razorpayOrderId: response.orderId ?? '',
          razorpayPaymentId: response.paymentId ?? '',
          razorpaySignature: response.signature ?? '',
        ),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isProcessing = false;
        _latestVerification = verification;
        _statusMessage = _normalizeMessage(
          verification.message,
          fallback: verification.success
              ? 'Payment verified successfully.'
              : 'Payment verification failed.',
        );
      });

      _showSnackBar(verification.message, isError: !verification.success);
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isProcessing = false;
        _statusMessage = null;
      });

      _showSnackBar(
        _normalizeMessage(error.toString(), fallback: 'Verification failed.'),
        isError: true,
      );
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    final message = _normalizeMessage(
      response.message,
      fallback: 'Payment failed. Please try again.',
    );

    setState(() {
      _isProcessing = false;
      _statusMessage = message;
    });

    _showSnackBar(message, isError: true);
  }

  void _showSnackBar(String message, {bool isError = false}) {
    final safeMessage = _normalizeMessage(
      message,
      fallback: isError ? 'Something went wrong.' : 'Done.',
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(safeMessage),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
      ),
    );
  }

  String _normalizeMessage(String? value, {required String fallback}) {
    final normalized = value?.trim() ?? '';
    if (normalized.isEmpty || normalized.toLowerCase() == 'undefined') {
      return fallback;
    }
    return normalized;
  }

  Color _statusTone(bool isError) {
    return isError ? const Color(0xFFB42318) : const Color(0xFF1D4ED8);
  }

  @override
  Widget build(BuildContext context) {
    final amountRupees = int.tryParse(_amountController.text.trim()) ?? 0;
    final amountPaise = amountRupees * 100;
    final latestVerificationMessage = _latestVerification != null
        ? _normalizeMessage(
            _latestVerification!.message,
            fallback: _latestVerification!.success
                ? 'Payment verified successfully.'
                : 'Payment verification failed.',
          )
        : null;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Checkout'),
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF111E4A), Color(0xFF1D4ED8), Color(0xFFEAF2FF)],
            stops: [0, 0.44, 1],
          ),
        ),
        child: Stack(
          children: [
            const Positioned(
              top: -80,
              right: -60,
              child: _BackdropOrb(size: 220),
            ),
            const Positioned(
              top: 260,
              left: -90,
              child: _BackdropOrb(size: 260, opacity: 0.12),
            ),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _HeroSummary(
                          amountRupees: amountRupees,
                          amountPaise: amountPaise,
                        ),
                        const SizedBox(height: 18),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x26161D1A),
                                blurRadius: 30,
                                offset: Offset(0, 16),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _SectionTitle(
                                title: 'Customer details',
                                subtitle: 'Used to prefill Razorpay checkout.',
                              ),
                              const SizedBox(height: 14),
                              _CheckoutTextField(
                                controller: _nameController,
                                enabled: !_isProcessing,
                                textInputAction: TextInputAction.next,
                                labelText: 'Name',
                                icon: Icons.person_outline,
                              ),
                              const SizedBox(height: 12),
                              _CheckoutTextField(
                                controller: _emailController,
                                enabled: !_isProcessing,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                labelText: 'Email',
                                icon: Icons.alternate_email,
                              ),
                              const SizedBox(height: 12),
                              _CheckoutTextField(
                                controller: _contactController,
                                enabled: !_isProcessing,
                                keyboardType: TextInputType.phone,
                                textInputAction: TextInputAction.next,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                labelText: 'Contact',
                                hintText: '10 digit mobile number',
                                icon: Icons.phone_outlined,
                              ),
                              const SizedBox(height: 18),
                              _SectionTitle(
                                title: 'Payment amount',
                                subtitle: 'Charged in INR and sent in paise.',
                              ),
                              const SizedBox(height: 14),
                              _CheckoutTextField(
                                controller: _amountController,
                                enabled: !_isProcessing,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                onChanged: (_) => setState(() {}),
                                labelText: 'Amount (INR)',
                                hintText: '499',
                                icon: Icons.currency_rupee,
                              ),
                              const SizedBox(height: 12),
                              _AmountPreview(
                                amountRupees: amountRupees,
                                amountPaise: amountPaise,
                              ),
                              const SizedBox(height: 18),
                              _PayButton(
                                isProcessing: _isProcessing,
                                onPressed: _isProcessing ? null : _startPayment,
                              ),
                              if (_statusMessage != null)
                                _StatusBanner(
                                  message: _statusMessage!,
                                  tone: _statusTone(
                                    _latestVerification?.success == false,
                                  ),
                                ),
                              if (latestVerificationMessage != null)
                                _StatusBanner(
                                  message: latestVerificationMessage,
                                  tone: _statusTone(
                                    !_latestVerification!.success,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
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

class _BackdropOrb extends StatelessWidget {
  const _BackdropOrb({required this.size, this.opacity = 0.16});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            Colors.white.withValues(alpha: opacity),
            Colors.white.withValues(alpha: 0),
          ],
        ),
      ),
    );
  }
}

class _HeroSummary extends StatelessWidget {
  const _HeroSummary({required this.amountRupees, required this.amountPaise});

  final int amountRupees;
  final int amountPaise;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [Color(0xFF0B1335), Color(0xFF1A2B6B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Secure checkout',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.verified_user_outlined,
                color: Color(0xFF93C5FD),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            '₹$amountRupees',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$amountPaise paise will be sent to server',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: const Color(0xFF10211D),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(color: Colors.black54),
        ),
      ],
    );
  }
}

class _CheckoutTextField extends StatelessWidget {
  const _CheckoutTextField({
    required this.controller,
    required this.enabled,
    required this.labelText,
    required this.icon,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.hintText,
    this.onChanged,
  });

  final TextEditingController controller;
  final bool enabled;
  final String labelText;
  final IconData icon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final String? hintText;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: const Color(0xFFF6F9FF),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFD6E4FF)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF1D4ED8), width: 1.4),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

class _AmountPreview extends StatelessWidget {
  const _AmountPreview({required this.amountRupees, required this.amountPaise});

  final int amountRupees;
  final int amountPaise;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF4FF),
        border: Border.all(color: const Color(0xFFD5E2FF)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.receipt_long_outlined,
            size: 18,
            color: Color(0xFF1D4ED8),
          ),
          const SizedBox(width: 8),
          Text(
            '₹$amountRupees',
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          Text(
            '$amountPaise paise',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}

class _PayButton extends StatelessWidget {
  const _PayButton({required this.isProcessing, required this.onPressed});

  final bool isProcessing;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          colors: [Color(0xFF1E40AF), Color(0xFF2563EB)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x402563EB),
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: isProcessing
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.lock_outline),
        label: Text(isProcessing ? 'Processing...' : 'Pay now'),
        style: FilledButton.styleFrom(
          elevation: 0,
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.message, required this.tone});

  final String message;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    final icon = tone.value == const Color(0xFFB42318).value
        ? Icons.error_outline
        : Icons.check_circle_outline;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: tone.withValues(alpha: 0.32)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: tone),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: tone,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
