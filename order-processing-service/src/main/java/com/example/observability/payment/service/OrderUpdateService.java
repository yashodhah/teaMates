package com.example.observability.payment.service;

import com.example.observability.payment.model.Order;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.service.annotation.PostExchange;


public interface OrderUpdateService {
    @PostExchange(url = "/api/v1/order/update-order-status")
    String updateOrderStatus(@RequestBody Order order);
}
