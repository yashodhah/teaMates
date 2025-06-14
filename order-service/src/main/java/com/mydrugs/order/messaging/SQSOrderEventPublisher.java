package com.mydrugs.order.messaging;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.mydrugs.order.config.SQSProperties;
import com.mydrugs.order.model.Order;
import io.awspring.cloud.sqs.operations.SendResult;
import io.awspring.cloud.sqs.operations.SqsTemplate;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Service;

import java.util.Map;

@Profile("aws")
@Slf4j
@Service
public class SQSOrderEventPublisher implements EventPublisher<Order> {

    private final ObjectMapper objectMapper;
    private final SqsTemplate sqsTemplate;
    private final SQSProperties sqsProperties;

    public SQSOrderEventPublisher(ObjectMapper objectMapper,
                                  SqsTemplate sqsTemplate,
                                   SQSProperties sqsProperties) {
        this.objectMapper = objectMapper;
        this.sqsTemplate = sqsTemplate;
        this.sqsProperties = sqsProperties;
    }


    @Override
    public void publishEvent(Order order) {
        try {
            String messageBody = objectMapper.writeValueAsString(order);
            SendResult<String> result = sqsTemplate.send(to -> to
                    .payload(messageBody)
                    .queue(sqsProperties.getQueueName())
                    .headers(Map.of("key", "value"))
                    .delaySeconds(10)
            );

            log.info("Published order {} to SQS", order.getOrderNumber());
        } catch (JsonProcessingException e) {
            log.error("Failed to serialize order for SQS", e);
        }
    }
}
