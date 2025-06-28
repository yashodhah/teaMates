package com.mydrugs.order.service;

import com.mydrugs.order.controller.OrderRequest;
import com.mydrugs.order.messaging.EventPublisher;
import com.mydrugs.order.model.Order;
import com.mydrugs.order.model.OrderItem;
import com.mydrugs.order.model.Product;
import com.mydrugs.order.repository.OrderRepository;
import com.mydrugs.order.repository.ProductRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;
import java.util.stream.Collectors;

@Service
public class OrderService {

    private final OrderRepository orderRepository;
    private final ProductRepository productRepository;
    private final EventPublisher<Order> orderEventPublisher;

    public OrderService(OrderRepository orderRepository,
                        ProductRepository productRepository,
                        EventPublisher<Order> orderEventPublisher) {
        this.orderRepository = orderRepository;
        this.productRepository = productRepository;
        this.orderEventPublisher = orderEventPublisher;
    }

    @Transactional
    public Order createOrder(OrderRequest orderRequest) {
        // Fetch products & validate stock
        List<OrderItem> orderItems = orderRequest.items().stream()
                .map(item -> {
                    Product product = productRepository.findById(item.id())
                            .orElseThrow(() -> new IllegalArgumentException("Product not found: " + item.id()));

                    return OrderItem.builder()
                            .product(product)
                            .quantity(item.quantity())
                            .build();
                })
                .collect(Collectors.toList());

        // Create order entity
        Order order = Order.builder()
                .orderNumber("ORD-" + System.currentTimeMillis()) // Meaningful order number
                .customerId(orderRequest.customerId())
                .totalAmount(orderRequest.totalAmount())
                .status(Order.OrderStatus.PENDING)
                .createdAt(Instant.now())
                .items(orderItems)
                .build();

        // Set the parent order to each order item, circular reference here
        orderItems.forEach(orderItem -> orderItem.setOrder(order));

        // Save order & publish event
        Order savedOrder = orderRepository.save(order);
        // TODO: Send only required, Don't send the whole order
        orderEventPublisher.publishEvent(savedOrder);

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
