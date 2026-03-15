class PaymentVerificationRequest {
  final String razorpayOrderId;
  final String razorpayPaymentId;
  final String razorpaySignature;

  const PaymentVerificationRequest({
    required this.razorpayOrderId,
    required this.razorpayPaymentId,
    required this.razorpaySignature,
  });

  factory PaymentVerificationRequest.fromJson(Map<String, dynamic> json) {
    return PaymentVerificationRequest(
      razorpayOrderId: json['razorpayOrderId'] as String,
      razorpayPaymentId: json['razorpayPaymentId'] as String,
      razorpaySignature: json['razorpaySignature'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'razorpayOrderId': razorpayOrderId,
      'razorpayPaymentId': razorpayPaymentId,
      'razorpaySignature': razorpaySignature,
    };
  }
}

class PaymentVerificationResponse {
  final bool success;
  final String message;

  const PaymentVerificationResponse({
    required this.success,
    required this.message,
  });

  factory PaymentVerificationResponse.fromJson(Map<String, dynamic> json) {
    return PaymentVerificationResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'success': success, 'message': message};
  }
}
