package com.mydrugs.orderprocessing.messaging;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.mydrugs.orderprocessing.model.OrderDTO;
import com.mydrugs.orderprocessing.service.OrderProcessingService;
import io.awspring.cloud.sqs.annotation.SqsListener;
import io.awspring.cloud.sqs.listener.QueueAttributes;
import io.awspring.cloud.sqs.listener.Visibility;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

@Service
@Slf4j
public class OrderProcessingSQSListener {

    private final OrderProcessingService orderProcessingService;
    private final ObjectMapper objectMapper;

    public OrderProcessingSQSListener(OrderProcessingService orderProcessingService, ObjectMapper objectMapper) {
        this.orderProcessingService = orderProcessingService;
        this.objectMapper = objectMapper;
    }

    @SqsListener({"${mydrugs.messaging.sqs.queueName}"})
    public void listen(String message, Visibility visibility, QueueAttributes queueAttributes, software.amazon.awssdk.services.sqs.model.Message originalMessage) {
        processMessage(message);
        log.info("Message processed and deleted from SQS");
    }

    private void processMessage(String message) {
        try {
            OrderDTO order = objectMapper.readValue(message, OrderDTO.class);
            log.info("Processing order {}", order.getOrderNumber());

            orderProcessingService.processOrder(order);
            log.info("Deleted order {} from SQS", order.getOrderNumber());
        } catch (Exception e) {
            log.error("Failed to process order message", e);
        }
    }
}
