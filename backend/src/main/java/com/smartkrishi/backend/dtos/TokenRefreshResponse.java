package com.smartkrishi.backend.dtos;

public record TokenRefreshResponse(
    String accessToken,
    String refreshToken
) {}
