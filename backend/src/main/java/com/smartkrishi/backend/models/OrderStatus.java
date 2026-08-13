package com.smartkrishi.backend.models;

public enum OrderStatus {
    PENDING,
    ACCEPTED,
    HARVEST_STARTED,
    HARVEST_COMPLETED,
    PICKUP_ASSIGNED,
    PICKED_UP,
    OUT_FOR_DELIVERY,
    DELIVERED,
    CANCELLED
}
