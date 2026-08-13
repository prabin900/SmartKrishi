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
@Document(collection = "reviews")
public class Review {
    @Id
    private String id;
    private String orderId;
    private String userId; // Writer (Customer)
    private String targetType; // PRODUCT, FARMER
    private String targetId; // Product ID or FarmerProfile ID
    private double rating;
    private String comment;
    private Instant timestamp;
}
