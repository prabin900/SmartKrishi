package com.smartkrishi.backend.dtos;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import java.time.Instant;

public record FarmVisitRequest(
    @NotBlank String farmerProfileId,
    Instant visitDate,
    @Min(1) int numberOfGuests,
    String notes,
    String visitType,
    String targetCrop,
    Double targetQuantity,
    String unit
) {}
