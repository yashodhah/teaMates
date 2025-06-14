package com.mydrugs.order.messaging;


public interface EventPublisher<T> {
    void publishEvent(T event);
}
