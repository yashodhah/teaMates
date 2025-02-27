package com.mydrugs.order.messaging;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.mydrugs.order.model.Order;
import lombok.extern.slf4j.Slf4j;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Service;

@Service
@Slf4j
public class KafkaOrderEventPublisher implements OrderEventPublisher {

    private final KafkaTemplate<String, String> kafkaTemplate; // Send JSON as String
    private final ObjectMapper objectMapper; // JSON serializer

    public KafkaOrderEventPublisher(KafkaTemplate<String, String> kafkaTemplate, ObjectMapper objectMapper) {
        this.kafkaTemplate = kafkaTemplate;
        this.objectMapper = objectMapper;
    }

    @Override
    public void publishOrderCreatedEvent(Order order) {
        try {
            String jsonOrder = objectMapper.writeValueAsString(order); // Convert to JSON
            kafkaTemplate.send("order-events", jsonOrder);
            log.info("Published order {} to Kafka as JSON", order.getOrderNumber());
        } catch (JsonProcessingException e) {
            log.error("Failed to serialize order to JSON", e);
        }
    }
}
