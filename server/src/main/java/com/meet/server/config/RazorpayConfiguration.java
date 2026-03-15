package com.meet.server.config;

import com.razorpay.RazorpayClient;
import com.razorpay.RazorpayException;
import lombok.Getter;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class RazorpayConfiguration {

    @Value("${razorpay.keyId}")
    private String keyId;

    @Getter
    @Value("${razorpay.secret}")
    private String keySecret;

    @Bean
    public RazorpayClient client() throws RazorpayException {
        return new RazorpayClient(keyId, keySecret);
    }
}
