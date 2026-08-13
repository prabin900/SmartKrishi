package com.smartkrishi.backend.dtos;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import java.util.List;

public record OrderRequest(
    @NotBlank String farmerProfileId,
    @NotEmpty List<CartItemRequest> items,
    double subtotal,
    double deliveryFee,
    double discount,
    double total,
    @NotBlank String deliveryMethod, // HOME_DELIVERY, FARM_PICKUP
    ShippingAddressRequest shippingAddress,
    @NotBlank String paymentMethod, // COD, ESEWA, KHALTI, FONEPAY
    String notes,
    boolean isBulkOrder
) {
    public record CartItemRequest(
        @NotBlank String productId,
        @NotBlank String productName,
        String productImage,
        double unitPrice,
        double quantity,
        @NotBlank String unit
    ) {}

    public record ShippingAddressRequest(
        String streetAddress,
        @NotBlank String city,
        @NotBlank String district,
        String state,
        double latitude,
        double longitude
    ) {}
}
