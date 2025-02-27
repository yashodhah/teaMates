package com.example.observability.payment.service;

import com.example.observability.payment.model.OrderPayment;
import io.micrometer.observation.annotation.Observed;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

@Service
@Slf4j
public class PaymentService {

    @Observed(name = "payment:processPayment")
    public void processPayment(OrderPayment orderPayment) {
        log.info("Starting payment processing for Order ID: {}", orderPayment.id());

        try {
            log.info("Validating payment details for Order ID: {}", orderPayment.id());
            Thread.sleep(500);
            log.info("Payment details validated for Order ID: {}", orderPayment.id());
            log.info("Authorizing payment for Order ID: {}", orderPayment.id());
            Thread.sleep(500);
            log.info("Payment authorized for Order ID: {}", orderPayment.id());
            log.info("Capturing payment for Order ID: {}", orderPayment.id());
            Thread.sleep(500);
            log.info("Payment captured for Order ID: {}", orderPayment.id());
            log.info("Completing payment processing for Order ID: {}", orderPayment.id());
            Thread.sleep(500);
            log.info("Payment processing completed for Order ID: {}", orderPayment.id());
        } catch (InterruptedException e) {
            log.error("Thread was interrupted while processing payment for Order ID: {}", orderPayment.id(), e);
        } catch (Exception e) {
            log.error("Exception occurred while processing payment for Order ID: {}", orderPayment.id(), e);
        }
    }
}
