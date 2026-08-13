package com.smartkrishi.backend.dtos;

import jakarta.validation.constraints.NotBlank;
import org.hibernate.validator.constraints.Range;

public record MilestoneRequest(
    @NotBlank String description,
    @Range(min = 0, max = 100) double growthPercentage,
    String imageUrl
) {}
