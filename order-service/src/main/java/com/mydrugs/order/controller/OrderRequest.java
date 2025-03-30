package com.mydrugs.order.controller;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;

import java.util.List;

public record OrderRequest(
    @NotBlank(message = "Customer ID is required") String customerId,
    @Min(value = 1, message = "Total amount must be at least 1") double totalAmount,
    @NotEmpty(message = "Order must contain at least one item") List<OrderItemRequest> items
) {
}
