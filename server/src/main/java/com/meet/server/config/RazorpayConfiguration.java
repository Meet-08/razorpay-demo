package com.meet.server.config;

import com.razorpay.RazorpayClient;
import com.razorpay.RazorpayException;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;

@Configuration
public class RazorpayConfiguration {

    @Value("${razorpay.keyId}")
    private String keyId;

    @Value("${razorpay.secret}")
    private String keySecret;

    public RazorpayClient client() throws RazorpayException {
        return new RazorpayClient(keyId, keySecret);
    }
}
