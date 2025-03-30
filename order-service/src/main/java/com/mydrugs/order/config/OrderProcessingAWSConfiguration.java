package com.mydrugs.order.config;

import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Profile;

@Profile("aws")
@Configuration
@EnableConfigurationProperties(AWSMessagingProperties.class)
public class OrderProcessingAWSConfiguration {
}
