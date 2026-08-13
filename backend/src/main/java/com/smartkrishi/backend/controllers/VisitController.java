package com.smartkrishi.backend.controllers;

import com.smartkrishi.backend.config.UserDetailsImpl;
import com.smartkrishi.backend.dtos.FarmVisitRequest;
import com.smartkrishi.backend.models.FarmVisit;
import com.smartkrishi.backend.services.VisitService;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/visits")
@Tag(name = "Farm Visits Booking", description = "Endpoints for scheduling and managing farm visits")
public class VisitController {

    @Autowired
    private VisitService visitService;

    @PostMapping
    @PreAuthorize("hasRole('CUSTOMER') or hasRole('BUSINESS')")
    public ResponseEntity<FarmVisit> bookVisit(Authentication authentication, @Valid @RequestBody FarmVisitRequest request) {
        String userId = ((UserDetailsImpl) authentication.getPrincipal()).getId();
        return ResponseEntity.ok(visitService.bookVisit(userId, request));
    }

    @PatchMapping("/{id}/status")
    @PreAuthorize("hasRole('FARMER') or hasRole('CUSTOMER') or hasRole('BUSINESS')")
    public ResponseEntity<FarmVisit> updateStatus(
            @PathVariable String id, 
            @RequestParam String status, 
            @RequestParam(required = false) String otpCode,
            @RequestParam(required = false) String declineReason) {
        return ResponseEntity.ok(visitService.updateVisitStatus(id, status, otpCode, declineReason));
    }

    @GetMapping("/customer")
    @PreAuthorize("hasRole('CUSTOMER') or hasRole('BUSINESS')")
    public ResponseEntity<List<FarmVisit>> getCustomerBookings(Authentication authentication) {
        String userId = ((UserDetailsImpl) authentication.getPrincipal()).getId();
        return ResponseEntity.ok(visitService.getCustomerVisits(userId));
    }

    @GetMapping("/farmer")
    @PreAuthorize("hasRole('FARMER')")
    public ResponseEntity<List<FarmVisit>> getFarmerBookings(@RequestParam String farmerProfileId) {
        return ResponseEntity.ok(visitService.getFarmerVisits(farmerProfileId));
    }
}
