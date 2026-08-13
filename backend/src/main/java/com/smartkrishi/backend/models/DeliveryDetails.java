package com.smartkrishi.backend.models;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;

import java.time.Instant;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Document(collection = "deliveries")
public class DeliveryDetails {
    @Id
    private String id;
    private String orderId;
    private String deliveryPartnerId; // maps to User ID
    private double currentLatitude;
    private double currentLongitude;
    private Instant estimatedArrivalTime;
    private List<TrackingMilestone> timeline;

    @Data
    @AllArgsConstructor
    @NoArgsConstructor
    public static class TrackingMilestone {
        private String status; // matches OrderStatus or descriptive event
        private String description;
        private Instant timestamp;
    }
}
