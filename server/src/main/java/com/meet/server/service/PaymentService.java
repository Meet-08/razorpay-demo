package com.meet.server.service;

import com.meet.server.config.RazorpayConfiguration;
import com.meet.server.dto.CreatePaymentRequest;
import com.meet.server.dto.CreatePaymentResponse;
import com.meet.server.dto.PaymentVerificationRequest;
import com.meet.server.dto.PaymentVerificationResponse;
import com.razorpay.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.json.JSONObject;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
@Slf4j
public class PaymentService {
    private final RazorpayClient razorpayClient;
    private final RazorpayConfiguration razorpayConfiguration;

    public CreatePaymentResponse createPayment(CreatePaymentRequest request) {
        String receipt = "rcpt_" + System.currentTimeMillis();
        JSONObject options = new JSONObject();
        options.put("amount", request.amount());
        options.put("currency", request.currency());
        options.put("receipt", receipt);

        try {
            Order rzpOrder = razorpayClient.orders.create(options);

            return new CreatePaymentResponse(
                    rzpOrder.get("id"),
                    request.amount(),
                    request.currency(),
                    receipt
            );
        } catch (RazorpayException e) {
            throw new RuntimeException(e);
        }
    }

    public PaymentVerificationResponse verifyPayment(PaymentVerificationRequest request) {
        try {
            // 1. Signature Verification
            String payload = request.razorpayOrderId() + "|" + request.razorpayPaymentId();
            boolean isSignatureValid = Utils.verifySignature(
                    payload,
                    request.razorpaySignature(),
                    razorpayConfiguration.getKeySecret()
            );

            if (!isSignatureValid) {
                return new PaymentVerificationResponse(false, "Invalid signature");
            }

            // 2. Fetch Payment and Order details from Razorpay
            Payment payment = razorpayClient.payments.fetch(request.razorpayPaymentId());
            Order order = razorpayClient.orders.fetch(request.razorpayOrderId());

            // 3. Validate Payment Status
            String status = payment.get("status");
            if (!"captured".equals(status) && !"authorized".equals(status)) {
                return new PaymentVerificationResponse(false, "Payment not captured or authorized. Current status: " + status);
            }

            // 4. Validate Payment matches Order
            String paymentOrderId = payment.get("order_id");
            if (!request.razorpayOrderId().equals(paymentOrderId)) {
                return new PaymentVerificationResponse(false, "Payment order ID mismatch");
            }

            // 5. Validate Amount and Currency
            Integer paymentAmount = payment.get("amount");
            Integer orderAmount = order.get("amount");
            String paymentCurrency = payment.get("currency");
            String orderCurrency = order.get("currency");

            if (!paymentAmount.equals(orderAmount)) {
                return new PaymentVerificationResponse(false, "Payment amount mismatch");
            }

            if (!orderCurrency.equalsIgnoreCase(paymentCurrency)) {
                return new PaymentVerificationResponse(false, "Payment currency mismatch");
            }

            return new PaymentVerificationResponse(true, "Payment verified successfully");

        } catch (RazorpayException e) {
            log.error("Error verifying payment with Razorpay API", e);
            return new PaymentVerificationResponse(false, "Error communicating with Razorpay: " + e.getMessage());
        } catch (Exception e) {
            log.error("Unexpected error during payment verification", e);
            return new PaymentVerificationResponse(false, "An unexpected error occurred: " + e.getMessage());
        }
    }
}
