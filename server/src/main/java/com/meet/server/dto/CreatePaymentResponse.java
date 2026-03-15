package com.meet.server.dto;

public record CreatePaymentResponse(
        String orderId,
        Long amount,
        String currency,
        String receipt
) {
}
