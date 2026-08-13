package com.smartkrishi.backend.dtos;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import java.time.Instant;
import java.util.List;

public record ProductRequest(
    @NotBlank String name,
    @NotBlank String description,
    @NotBlank String categoryId,
    List<String> imageUrls,
    @Min(0) double price,
    @NotBlank String unit,
    @Min(0) double availableQuantity,
    Instant harvestDate,
    boolean organic,
    @NotBlank String city,
    @NotBlank String district,
    boolean pickupAvailable,
    boolean harvestOnDemand,
    boolean farmVisitAvailable
) {}
