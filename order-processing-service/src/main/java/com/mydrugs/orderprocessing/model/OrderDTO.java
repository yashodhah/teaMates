package com.mydrugs.orderprocessing.model;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.Instant;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class OrderDTO {

    private Long id;
    private String orderNumber;
    private String customerId;
    private Double totalAmount;
    private String status;
    private Instant createdAt;
    private List<ItemDTO> items;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ItemDTO {
        private Long id;
        private ProductDTO product;

        @Data
        @Builder
        @NoArgsConstructor
        @AllArgsConstructor
        public static class ProductDTO {
            private Long id;
            private String productCode;
            private String name;
            private String category;
            private Double price;
        }
    }
}
