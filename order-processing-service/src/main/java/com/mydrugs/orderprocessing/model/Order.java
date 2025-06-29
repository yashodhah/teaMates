package com.mydrugs.orderprocessing.model;

import jakarta.persistence.*;
import lombok.*;

import java.time.Instant;

@Entity
@Table(name = "processing_orders")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Order {



    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true)
    private String orderNumber;

    @Column(nullable = false)
    private String customerId;

    @Column(nullable = false)
    private Double totalAmount;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private OrderStatus status;

    @Column(nullable = false, updatable = false)
    private Instant createdAt;

    public enum OrderStatus {
        PENDING, PROCESSING, SHIPPED, DELIVERED, CANCELLED
    }

public static Order fromOrderDTO(OrderDTO orderDTO) {
    return Order.builder()
            .id(orderDTO.getId())
            .orderNumber(orderDTO.getOrderNumber())
            .customerId(orderDTO.getCustomerId())
            .totalAmount(orderDTO.getTotalAmount())
            .status(OrderStatus.valueOf(orderDTO.getStatus()))
            .createdAt(orderDTO.getCreatedAt())
            .build();
}
}
