package com.smartkrishi.backend.dtos;

public record JwtResponse(
    String token,
    String refreshToken,
    String id,
    String email,
    String fullName,
    String role
) {}
