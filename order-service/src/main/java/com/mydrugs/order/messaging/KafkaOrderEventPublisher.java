package com.mydrugs.order.messaging;

import com.mydrugs.order.model.Order;
import lombok.extern.slf4j.Slf4j;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Service;

@Service
@Slf4j
public class KafkaOrderEventPublisher implements OrderEventPublisher {

    private final KafkaTemplate<String, Order> kafkaTemplate;

    public KafkaOrderEventPublisher(KafkaTemplate<String, Order> kafkaTemplate) {
        this.kafkaTemplate = kafkaTemplate;
    }

    @Override
    public void publishOrderCreatedEvent(Order order) {
        kafkaTemplate.send("order-events", order);
        log.info("Published order {} to Kafka", order.getOrderNumber());
    }
}
