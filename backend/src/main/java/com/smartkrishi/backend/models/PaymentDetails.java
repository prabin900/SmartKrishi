package com.smartkrishi.backend.models;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;

import java.time.Instant;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Document(collection = "payments")
public class PaymentDetails {
    @Id
    private String id;
    private String orderId;
    private double amount;
    private String paymentMethod; // COD, ESEWA, KHALTI, FONEPAY
    private String transactionId; // Reference from gateway
    private String status; // PENDING, COMPLETED, FAILED, REFUNDED
    private Instant timestamp;
}
