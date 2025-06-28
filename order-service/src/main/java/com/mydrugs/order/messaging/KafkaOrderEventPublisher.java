package com.mydrugs.order.messaging;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.mydrugs.order.model.Order;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.kafka.core.KafkaTemplate;

@Slf4j
public class KafkaOrderEventPublisher implements EventPublisher<Order> {

    @Autowired
    private KafkaTemplate<Integer, String> KafkaTemplate;

    @Autowired
    private  ObjectMapper objectMapper;


    @Override
    public void publishEvent(Order order) {
        try {
            String messageBody = objectMapper.writeValueAsString(order);
            KafkaTemplate.send("order-topic", messageBody);
            log.info("Published order {} to Kafka", order.getOrderNumber());
        } catch (Exception e) {
            log.error("Failed to publish order {} to Kafka", order.getOrderNumber(), e);
        }
    }
}
