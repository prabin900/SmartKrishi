package com.smartkrishi.backend.models;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Document(collection = "delivery_partners")
public class DeliveryPartnerProfile {
    @Id
    private String id;
    private String userId; // maps to User
    private String vehicleType; // e.g. MOTORCYCLE, BICYCLE, VAN, TRUCK
    private String vehicleNumber;
    private String licenseNumber;
    private boolean online = false;
    private double currentLatitude;
    private double currentLongitude;
    private double rating = 5.0;
    private int deliveryCount = 0;
    private boolean verified = false;
}
