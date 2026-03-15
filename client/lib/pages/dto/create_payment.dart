class CreatePaymentRequest {
  final int amount;
  final String currency;

  const CreatePaymentRequest({required this.amount, required this.currency});

  factory CreatePaymentRequest.fromJson(Map<String, dynamic> json) {
    return CreatePaymentRequest(
      amount: (json['amount'] as num).toInt(),
      currency: json['currency'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'amount': amount, 'currency': currency};
  }
}

class CreatePaymentResponse {
  final String orderId;
  final int amount;
  final String currency;
  final String receipt;

  const CreatePaymentResponse({
    required this.orderId,
    required this.amount,
    required this.currency,
    required this.receipt,
  });

  factory CreatePaymentResponse.fromJson(Map<String, dynamic> json) {
    return CreatePaymentResponse(
      orderId: json['orderId'] as String,
      amount: (json['amount'] as num).toInt(),
      currency: json['currency'] as String,
      receipt: json['receipt'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'orderId': orderId,
      'amount': amount,
      'currency': currency,
      'receipt': receipt,
    };
  }
}
