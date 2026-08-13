package com.smartkrishi.backend.dtos;

import jakarta.validation.constraints.NotBlank;

public record TokenRefreshRequest(
    @NotBlank String refreshToken
) {}
