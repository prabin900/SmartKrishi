package com.smartkrishi.backend.models;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;

import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Document(collection = "farmers")
public class FarmerProfile {
    @Id
    private String id;
    private String userId; // maps to User
    private String farmName;
    private String farmDescription;
    private String farmAddress;
    private double latitude;
    private double longitude;
    private List<String> galleryImageUrls;
    private double rating = 5.0;
    private int reviewCount = 0;
    private boolean verified = false;
}
