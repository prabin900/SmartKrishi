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
@Document(collection = "products")
public class Product {
    @Id
    private String id;
    private String name;
    private String description;
    private String categoryId;
    private List<String> imageUrls;
    private double price; // Price per unit (NPR)
    private String unit; // e.g. "kg", "crate", "piece"
    private double availableQuantity;
    private double reservedQuantity;
    private double soldQuantity;
    private Instant harvestDate;
    private boolean organic;
    private String city;
    private String district;
    private String farmerProfileId; // maps to FarmerProfile
    private boolean pickupAvailable;
    private boolean harvestOnDemand;
    private boolean farmVisitAvailable;

    @CreatedDate
    private Instant createdAt;

    @LastModifiedDate
    private Instant updatedAt;
}
