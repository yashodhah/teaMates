package com.mydrugs.orderprocessing.messaging;

import org.springframework.kafka.annotation.KafkaListener;

public class OrderProcessingKafkaListener {

    @KafkaListener(id = "myListener", topics = "order-placed",
            autoStartup = "${listen.auto.start:true}", concurrency = "${listen.concurrency:3}")
    public void listen(String data) {

    }
}
