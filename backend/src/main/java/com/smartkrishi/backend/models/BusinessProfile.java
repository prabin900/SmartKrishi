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
@Document(collection = "businesses")
public class BusinessProfile {
    @Id
    private String id;
    private String userId; // maps to User
    private String companyName;
    private String registrationNumber;
    private String businessType; // e.g. HOTEL, RESTAURANT, GROCERY_STORE, WHOLESALER
    private String address;
    private String contactPersonName;
    private boolean verified = false;
}
