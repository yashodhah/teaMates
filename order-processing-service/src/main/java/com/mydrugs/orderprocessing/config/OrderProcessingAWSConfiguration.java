package com.mydrugs.orderprocessing.config;

import com.fasterxml.jackson.databind.ObjectMapper;
import io.awspring.cloud.sqs.config.SqsListenerConfigurer;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class OrderProcessingAWSConfiguration {

//    @Bean
//    @ConfigurationProperties(prefix = "mydrugs.messaging.sqs")
//    SQSProperties sqsProperties() {
//        return new SQSProperties();
//    }
//
//    @Bean
//    public SqsAsyncClient sqsAsyncClient() {
//        return SqsAsyncClient.builder().build();
//    }
//
//    @Bean
//    public SqsTemplate sqsTemplate(ObjectMapper objectMapper, SQSProperties sqsProperties, SqsAsyncClient sqsAsyncClient) {
//        return SqsTemplate.builder()
//                .sqsAsyncClient(sqsAsyncClient)
//                .configure(options -> options
//                        .acknowledgementMode(TemplateAcknowledgementMode.MANUAL)
//                        .defaultQueue(sqsProperties.getQueueName())
//                )
//                .configureDefaultConverter(converter -> converter.setObjectMapper(objectMapper)
//                )
//                .build();
//    }

    @Bean
    SqsListenerConfigurer configurer(ObjectMapper objectMapper) {
        return registrar -> registrar.setObjectMapper(objectMapper);
    }

}
