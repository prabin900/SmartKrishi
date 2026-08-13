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
@Document(collection = "addresses")
public class Address {
    @Id
    private String id;
    private String userId;
    private String streetAddress;
    private String city;
    private String district;
    private String state;
    private String country = "Nepal";
    private double latitude;
    private double longitude;
    private boolean isDefault;
}
