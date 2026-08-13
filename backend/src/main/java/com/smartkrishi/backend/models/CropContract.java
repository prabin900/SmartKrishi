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
@Document(collection = "contracts")
public class CropContract {
    @Id
    private String id;
    private String businessProfileId;
    private String farmerProfileId; // Assigned once farmer accepts
    private String cropName;
    private double targetQuantity;
    private String unit;
    private String harvestMonth;
    private double expectedPrice; // Price offered per unit (NPR)
    private boolean accepted = false;
    private String status; // REQUESTED, ACCEPTED, PLANTED, GROWING, HARVESTED, COMPLETED, CANCELLED
    @Builder.Default
    private boolean organicOnly = true;
    @Builder.Default
    private boolean aGradeOnly = true;
    @Builder.Default
    private boolean directPickupRequired = false;
    private List<String> qualityStandards;
    private List<Milestone> progressMilestones;
    private Instant createdAt;
    private Instant updatedAt;

    @Data
    @AllArgsConstructor
    @NoArgsConstructor
    public static class Milestone {
        private String description;
        private double growthPercentage; // e.g. 0.0 to 100.0
        private String imageUrl;
        private Instant timestamp;
    }
}
