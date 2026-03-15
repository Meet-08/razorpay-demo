package com.meet.server.dto;

public record CreatePaymentRequest(
        Long amount,
        String currency
) {
}
