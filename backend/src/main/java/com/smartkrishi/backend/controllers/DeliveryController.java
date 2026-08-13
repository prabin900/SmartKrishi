package com.smartkrishi.backend.controllers;

import com.smartkrishi.backend.config.UserDetailsImpl;
import com.smartkrishi.backend.models.DeliveryPartnerProfile;
import com.smartkrishi.backend.models.Order;
import com.smartkrishi.backend.services.DeliveryService;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/delivery")
@Tag(name = "Delivery Logistics", description = "Endpoints for delivery partner operations: route navigation, online toggle, verification OTP/QR")
public class DeliveryController {

    @Autowired
    private DeliveryService deliveryService;

    @PutMapping("/status")
    @PreAuthorize("hasRole('DELIVERY_PARTNER')")
    public ResponseEntity<DeliveryPartnerProfile> toggleOnlineStatus(
            Authentication authentication, @RequestParam boolean online) {
        String userId = ((UserDetailsImpl) authentication.getPrincipal()).getId();
        return ResponseEntity.ok(deliveryService.updateOnlineStatus(userId, online));
    }

    @PutMapping("/location")
    @PreAuthorize("hasRole('DELIVERY_PARTNER')")
    public ResponseEntity<DeliveryPartnerProfile> updateLocation(
            Authentication authentication, @RequestParam double latitude, @RequestParam double longitude) {
        String userId = ((UserDetailsImpl) authentication.getPrincipal()).getId();
        return ResponseEntity.ok(deliveryService.updateLocation(userId, latitude, longitude));
    }

    @PostMapping("/assign")
    @PreAuthorize("hasRole('ADMIN') or hasRole('FARMER')")
    public ResponseEntity<Order> assignPartner(@RequestParam String orderId, @RequestParam String partnerUserId) {
        return ResponseEntity.ok(deliveryService.assignDeliveryPartner(orderId, partnerUserId));
    }

    @PostMapping("/verify-otp")
    @PreAuthorize("hasRole('DELIVERY_PARTNER')")
    public ResponseEntity<Boolean> verifyOtp(@RequestParam String orderId, @RequestParam String otp) {
        return ResponseEntity.ok(deliveryService.verifyOtpHandshake(orderId, otp));
    }

    @PostMapping("/verify-qr")
    @PreAuthorize("hasRole('DELIVERY_PARTNER')")
    public ResponseEntity<Boolean> verifyQr(@RequestParam String orderId, @RequestParam String qrCode) {
        return ResponseEntity.ok(deliveryService.verifyQrHandshake(orderId, qrCode));
    }

    @GetMapping("/history")
    @PreAuthorize("hasRole('DELIVERY_PARTNER')")
    public ResponseEntity<List<Order>> getHistory(Authentication authentication) {
        String userId = ((UserDetailsImpl) authentication.getPrincipal()).getId();
        return ResponseEntity.ok(deliveryService.getPartnerDeliveryHistory(userId));
    }

    @GetMapping("/available")
    @PreAuthorize("hasRole('DELIVERY_PARTNER')")
    public ResponseEntity<List<Order>> getAvailable() {
        return ResponseEntity.ok(deliveryService.getAvailableOrdersForPickup());
    }

    @PostMapping("/claim")
    @PreAuthorize("hasRole('DELIVERY_PARTNER')")
    public ResponseEntity<Order> claimOrder(Authentication authentication, @RequestParam String orderId) {
        String userId = ((UserDetailsImpl) authentication.getPrincipal()).getId();
        return ResponseEntity.ok(deliveryService.assignDeliveryPartner(orderId, userId));
    }

    @GetMapping("/earnings")
    @PreAuthorize("hasRole('DELIVERY_PARTNER')")
    public ResponseEntity<Double> getEarnings(Authentication authentication) {
        String userId = ((UserDetailsImpl) authentication.getPrincipal()).getId();
        return ResponseEntity.ok(deliveryService.getPartnerEarnings(userId));
    }
}
