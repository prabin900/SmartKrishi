package com.smartkrishi.backend.dtos;

import jakarta.validation.constraints.NotBlank;

public record MessageRequest(
    @NotBlank String chatId,
    String text,
    String imageUrl
) {}
