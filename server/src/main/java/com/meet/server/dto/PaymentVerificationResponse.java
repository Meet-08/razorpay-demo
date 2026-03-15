package com.meet.server.dto;

public record PaymentVerificationResponse(
        boolean success,
        String message
) {
}
