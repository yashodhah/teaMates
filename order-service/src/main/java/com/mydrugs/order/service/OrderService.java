package com.mydrugs.order.service;

import com.mydrugs.order.messaging.OrderEventPublisher;
import com.mydrugs.order.model.Order;
import com.mydrugs.order.repository.OrderRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

@Service
public class OrderService {

    private final OrderRepository orderRepository;
    private final OrderEventPublisher orderEventPublisher;

    public OrderService(OrderRepository orderRepository, OrderEventPublisher orderEventPublisher) {
        this.orderRepository = orderRepository;
        this.orderEventPublisher = orderEventPublisher;
    }

    @Transactional
    public Order createOrder(Order order) {
        if (order.getTotalAmount() == null || order.getTotalAmount() <= 0) {
            throw new IllegalArgumentException("Order total amount must be positive.");
        }

        if (order.getCustomerId() == null || order.getCustomerId().trim().isEmpty()) {
            throw new IllegalArgumentException("Customer ID is required.");
        }

        order.setOrderNumber(UUID.randomUUID().toString());
        order.setCreatedAt(Instant.now());
        order.setStatus(Order.OrderStatus.PENDING);

        Order savedOrder = orderRepository.save(order);
        orderEventPublisher.publishOrderCreatedEvent(savedOrder);

        return savedOrder;
    }

    public Order getOrderByNumber(String orderNumber) {
        return orderRepository.findByOrderNumber(orderNumber)
                .orElseThrow(() -> new IllegalArgumentException("Order not found."));
    }

    public List<Order> getAllOrders() {
        return orderRepository.findAll();
    }
}
