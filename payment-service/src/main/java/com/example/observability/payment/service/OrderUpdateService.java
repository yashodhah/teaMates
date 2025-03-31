package com.example.observability.payment.service;

import com.example.observability.payment.model.Order;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.service.annotation.PutExchange;


public interface OrderUpdateService {
    @PutExchange(url = "/api/v1/order")
    String updateOrderStatus(@RequestBody Order order);
}
