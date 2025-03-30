package com.mydrugs.orderprocessing.config;

import org.springframework.boot.context.properties.ConfigurationProperties;


@ConfigurationProperties(prefix = "mydrugs.messaging.sqs")
public record AWSMessagingProperties(String queueURL) {
}
