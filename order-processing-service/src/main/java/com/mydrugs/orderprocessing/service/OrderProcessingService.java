package com.mydrugs.orderprocessing.service;

import com.mydrugs.orderprocessing.model.Order;
import com.mydrugs.orderprocessing.model.OrderDTO;
import com.mydrugs.orderprocessing.repository.OrderRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@Slf4j
public class OrderProcessingService {

    private final OrderRepository orderRepository;

    public OrderProcessingService(OrderRepository orderRepository) {
        this.orderRepository = orderRepository;
    }

    @Transactional
    public void processOrder(OrderDTO orderDTO) {
        log.info("Processing order: {}", orderDTO.getOrderNumber());

        Order order = Order.fromOrderDTO(orderDTO);
        order.setStatus(Order.OrderStatus.PROCESSING);

        orderRepository.save(order);

        try {
            Thread.sleep(2000); // Simulating external operations (e.g., payment, stock check)
        } catch (InterruptedException e) {
            log.error("Processing interrupted for order {}", order.getOrderNumber());
        }

        order.setStatus(Order.OrderStatus.SHIPPED);
        orderRepository.save(order);

        log.info("Order {} successfully processed!", order.getOrderNumber());
    }
}
