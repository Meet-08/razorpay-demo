package com.meet.server.dto;

public record PaymentVerificationRequest(
        String razorpayOrderId,
        String razorpayPaymentId,
        String razorpaySignature
) {
}
