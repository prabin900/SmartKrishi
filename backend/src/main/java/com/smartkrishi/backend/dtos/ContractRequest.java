package com.smartkrishi.backend.dtos;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;

import java.util.List;

public record ContractRequest(
    @NotBlank String cropName,
    @Min(1) double targetQuantity,
    @NotBlank String unit,
    @NotBlank String harvestMonth,
    @Min(1) double expectedPrice,
    String farmerProfileId,
    Boolean organicOnly,
    Boolean aGradeOnly,
    Boolean directPickupRequired,
    List<String> qualityStandards
) {}
