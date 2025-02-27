package com.mydrugs.order.messaging;

import com.mydrugs.order.model.Order;

public interface OrderEventPublisher {
    void publishOrderCreatedEvent(Order order);
}
