package com.meet.server.service;

import com.meet.server.config.RazorpayConfiguration;
import com.meet.server.dto.CreatePaymentRequest;
import com.meet.server.dto.CreatePaymentResponse;
import com.meet.server.dto.PaymentVerificationRequest;
import com.meet.server.dto.PaymentVerificationResponse;
import com.razorpay.Order;
import com.razorpay.RazorpayClient;
import com.razorpay.RazorpayException;
import com.razorpay.Utils;
import lombok.RequiredArgsConstructor;
import org.json.JSONObject;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
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
        String payload = request.razorpayOrderId() + "|" + request.razorpayPaymentId();
        try {
            boolean isSuccess = Utils.verifySignature(
                    payload,
                    request.razorpaySignature(),
                    razorpayConfiguration.getKeySecret()
            );

            if (isSuccess) {
                return new PaymentVerificationResponse(true, "Payment verified");
            }

            return new PaymentVerificationResponse(false, "Payment verification failed");
        } catch (RazorpayException e) {
            throw new RuntimeException(e);
        }
    }
}
