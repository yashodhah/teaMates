package com.mydrugs.orderprocessing.messaging;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.mydrugs.orderprocessing.model.Order;
import com.mydrugs.orderprocessing.repository.OrderRepository;
import com.mydrugs.orderprocessing.service.OrderProcessingService;
import lombok.extern.slf4j.Slf4j;
import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.springframework.context.annotation.Profile;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.kafka.support.Acknowledgment;
import org.springframework.stereotype.Service;

import java.util.Optional;

@Service
@Slf4j
public class OrderProcessingListener {

    private final OrderRepository orderRepository;
    private final ObjectMapper objectMapper;
    private final OrderProcessingService orderProcessingService;

    public OrderProcessingListener(OrderRepository orderRepository, ObjectMapper objectMapper, OrderProcessingService orderProcessingService) {
        this.orderRepository = orderRepository;
        this.objectMapper = objectMapper;
        this.orderProcessingService = orderProcessingService;
    }

    @KafkaListener(topics = "order-events", groupId = "order-processing-group")
    public void processOrder(ConsumerRecord<String, String> record, Acknowledgment ack) {
        try {
            Order order = objectMapper.readValue(record.value(), Order.class);
            log.info("Received order for processing: {}", order.getOrderNumber());

            // Ensure order is saved in processing DB before processing
            Optional<Order> existingOrder = orderRepository.findByOrderNumber(order.getOrderNumber());
            if (existingOrder.isEmpty()) {
                order.setStatus(Order.OrderStatus.PENDING);
                orderRepository.save(order);
            } else {
                order = existingOrder.get();
            }

            orderProcessingService.processOrder(order);

            ack.acknowledge();

        } catch (Exception e) {
            log.error("Error processing order: {}", e.getMessage(), e);
        }
    }
}
