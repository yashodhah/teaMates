package com.mydrugs.order.messaging;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.mydrugs.order.model.Order;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Service;
import software.amazon.awssdk.services.sqs.SqsClient;
import software.amazon.awssdk.services.sqs.model.SendMessageRequest;

@Profile("aws")
@Slf4j
@Service
public class SqsOrderEventPublisher implements OrderEventPublisher {

    private final SqsClient sqsClient;
    private final ObjectMapper objectMapper;
    private final String queueUrl = "https://sqs.YOUR-REGION.amazonaws.com/YOUR-ACCOUNT-ID/order-queue";

    public SqsOrderEventPublisher(SqsClient sqsClient, ObjectMapper objectMapper) {
        this.sqsClient = sqsClient;
        this.objectMapper = objectMapper;
    }

    @Override
    public void publishOrderCreatedEvent(Order order) {
        try {
            String messageBody = objectMapper.writeValueAsString(order);
            SendMessageRequest sendMsgRequest = SendMessageRequest.builder()
                    .queueUrl(queueUrl)
                    .messageBody(messageBody)
                    .build();

            sqsClient.sendMessage(sendMsgRequest);
            log.info("Published order {} to SQS", order.getOrderNumber());
        } catch (JsonProcessingException e) {
            log.error("Failed to serialize order for SQS", e);
        }
    }
}
