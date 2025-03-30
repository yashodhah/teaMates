package com.mydrugs.orderprocessing.messaging;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.mydrugs.orderprocessing.config.AWSMessagingProperties;
import com.mydrugs.orderprocessing.model.Order;
import com.mydrugs.orderprocessing.service.OrderProcessingService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.annotation.Profile;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import software.amazon.awssdk.services.sqs.SqsClient;
import software.amazon.awssdk.services.sqs.model.DeleteMessageRequest;
import software.amazon.awssdk.services.sqs.model.Message;
import software.amazon.awssdk.services.sqs.model.ReceiveMessageRequest;

import java.util.List;

@Profile("aws")
@Service
@Slf4j
public class OrderProcessingSQSListener {

    private final SqsClient sqsClient;
    private final ObjectMapper objectMapper;
    private final OrderProcessingService orderProcessingService;
    private final AWSMessagingProperties awsMessagingProperties;


    public OrderProcessingSQSListener(SqsClient sqsClient,
                                      ObjectMapper objectMapper,
                                      OrderProcessingService orderProcessingService,
                                      AWSMessagingProperties awsMessagingProperties) {
        this.sqsClient = sqsClient;
        this.objectMapper = objectMapper;
        this.orderProcessingService = orderProcessingService;
        this.awsMessagingProperties = awsMessagingProperties;
    }

    @Scheduled(fixedDelay = 5000)  // Poll every 5 seconds
    public void listenForOrders() {
        try {
            ReceiveMessageRequest receiveMessageRequest = ReceiveMessageRequest.builder()
                    .queueUrl(awsMessagingProperties.queueURL())
                    .maxNumberOfMessages(5)
                    .waitTimeSeconds(20) // Long polling reduces API calls
                    .build();

            List<Message> messages = sqsClient.receiveMessage(receiveMessageRequest).messages();

            for (Message message : messages) {
                processMessage(message);
            }
        } catch (Exception e) {
            log.error("Error while polling SQS", e);
        }
    }

    private void processMessage(Message message) {
        try {
            Order order = objectMapper.readValue(message.body(), Order.class);
            log.info("Processing order {}", order.getOrderNumber());

            orderProcessingService.processOrder(order);

            DeleteMessageRequest deleteMessageRequest = DeleteMessageRequest.builder()
                    .queueUrl(awsMessagingProperties.queueURL())
                    .receiptHandle(message.receiptHandle())
                    .build();
            sqsClient.deleteMessage(deleteMessageRequest);

            log.info("Deleted order {} from SQS", order.getOrderNumber());

        } catch (Exception e) {
            log.error("Failed to process order message", e);
        }
    }
}
