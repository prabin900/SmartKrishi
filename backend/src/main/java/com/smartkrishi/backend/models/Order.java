package com.smartkrishi.backend.models;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.Id;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.mongodb.core.mapping.Document;

import java.time.Instant;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Document(collection = "orders")
public class Order {
    @Id
    private String id;
    private String customerId; // User ID
    private String farmerProfileId; // FarmerProfile ID
    private List<OrderItem> items;
    private double subtotal;
    private double deliveryFee;
    private double discount;
    private double total;
    private OrderStatus status;
    private String deliveryMethod; // HOME_DELIVERY, FARM_PICKUP
    private Address shippingAddress;
    private String paymentMethod; // COD, ESEWA, KHALTI, FONEPAY
    private String paymentStatus; // PENDING, PAID, FAILED
    private String otpCode; // 4 or 6 digit verification code
    private String qrCodeData;
    private String deliveryPartnerId; // User ID of delivery partner
    private String notes;
    private String declineReason;
    private boolean isBulkOrder;

    @CreatedDate
    private Instant createdAt;

    @LastModifiedDate
    private Instant updatedAt;
}
