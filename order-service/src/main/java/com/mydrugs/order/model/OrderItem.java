package com.mydrugs.order.model;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "order_items")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class OrderItem {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne
    @JoinColumn(name = "order_id", nullable = false)
    private Order order;  // Reference to the order

    @ManyToOne
    @JoinColumn(name = "product_id", nullable = false)
    private Product product;  // Reference to the product

    @Column(nullable = false)
    private int quantity;  // How many units of this product were ordered
}
