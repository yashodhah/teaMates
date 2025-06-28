package com.mydrugs.order.config;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.mydrugs.order.messaging.SQSOrderEventPublisher;
import io.awspring.cloud.sqs.operations.SqsTemplate;
import io.awspring.cloud.sqs.operations.TemplateAcknowledgementMode;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Profile;
import software.amazon.awssdk.services.sqs.SqsAsyncClient;

@Profile("aws")
@Configuration
public class AWSConfiguration {
    @Bean
    @ConfigurationProperties(prefix = "mydrugs.messaging.sqs")
    SQSProperties sqsProperties() {
        return new SQSProperties();
    }

    @Bean
    public SqsAsyncClient sqsAsyncClient() {
        return SqsAsyncClient.builder().build();
    }

    @Bean
    public SqsTemplate sqsTemplate(ObjectMapper objectMapper, SQSProperties sqsProperties, SqsAsyncClient sqsAsyncClient) {
        return SqsTemplate.builder()
                .sqsAsyncClient(sqsAsyncClient)
                .configure(options -> options
                        .acknowledgementMode(TemplateAcknowledgementMode.MANUAL)
                )
                .configureDefaultConverter(converter -> converter.setObjectMapper(objectMapper)
                )
                .build();
    }

    @Bean
    public SQSOrderEventPublisher sqsOrderEventPublisher(ObjectMapper objectMapper,
                                                         SqsTemplate sqsTemplate,
                                                         SQSProperties sqsProperties) {
        return new SQSOrderEventPublisher(objectMapper, sqsTemplate, sqsProperties);
    }
}
