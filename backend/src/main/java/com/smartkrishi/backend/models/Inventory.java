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
@Document(collection = "inventory")
public class Inventory {
    @Id
    private String id;
    private String productId;
    private double quantityChanged;
    private String changeType; // e.g. ADDED, SOLD, WASTED, RESERVED
    private String referenceId; // order ID, contract ID, etc.
    private String remarks;
    private Instant timestamp;
}
