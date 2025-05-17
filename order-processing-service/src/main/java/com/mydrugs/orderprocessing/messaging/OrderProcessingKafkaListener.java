package com.mydrugs.orderprocessing.messaging;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.mydrugs.orderprocessing.model.Order;
import com.mydrugs.orderprocessing.model.OrderDTO;
import com.mydrugs.orderprocessing.repository.OrderRepository;
import com.mydrugs.orderprocessing.service.OrderProcessingService;
import lombok.extern.slf4j.Slf4j;
import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.springframework.context.annotation.Profile;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.kafka.support.Acknowledgment;
import org.springframework.stereotype.Service;

import java.util.Optional;

@Profile("k8")
@Service
@Slf4j
public class OrderProcessingKafkaListener {

    private final OrderRepository orderRepository;
    private final ObjectMapper objectMapper;
    private final OrderProcessingService orderProcessingService;

    public OrderProcessingKafkaListener(OrderRepository orderRepository, ObjectMapper objectMapper, OrderProcessingService orderProcessingService) {
        this.orderRepository = orderRepository;
        this.objectMapper = objectMapper;
        this.orderProcessingService = orderProcessingService;
    }

    @KafkaListener(topics = "order-events", groupId = "order-processing-group")
    public void processOrder(ConsumerRecord<String, String> record, Acknowledgment ack) {
        try {
            OrderDTO order = objectMapper.readValue(record.value(), OrderDTO.class);
            log.info("Received order for processing: {}", order.getOrderNumber());

            // Ensure order is saved in processing DB before processing
            Optional<Order> existingOrder = orderRepository.findByOrderNumber(order.getOrderNumber());

            if (existingOrder.isEmpty()) {
                order.setStatus(Order.OrderStatus.PENDING.name());
            }

            orderProcessingService.processOrder(order);
            ack.acknowledge();
        } catch (Exception e) {
            log.error("Error processing order: {}", e.getMessage(), e);
        }
    }
}
