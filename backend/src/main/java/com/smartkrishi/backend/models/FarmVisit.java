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

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Document(collection = "farm_visits")
public class FarmVisit {
    @Id
    private String id;
    private String customerId; // User ID
    private String farmerProfileId; // FarmerProfile ID
    private String visitorName;
    private String visitorPhone;
    private Instant visitDate;
    private int numberOfGuests;
    private String status; // PENDING, CONFIRMED, COMPLETED, CANCELLED
    private String visitType; // FARM_TOUR, FIELD_PURCHASE
    private String targetCrop; // Crop name for buying visits
    private Double targetQuantity; // Target quantity for buying visits
    private String unit; // Unit e.g. kg
    private String otpCode; // 4-digit verification PIN for field purchase
    private String notes;
    private String declineReason;

    @CreatedDate
    private Instant createdAt;

    @LastModifiedDate
    private Instant updatedAt;
}
