package com.smartkrishi.backend.controllers;

import com.smartkrishi.backend.models.BusinessProfile;
import com.smartkrishi.backend.models.DeliveryPartnerProfile;
import com.smartkrishi.backend.models.FarmerProfile;
import com.smartkrishi.backend.repositories.*;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/admin")
@PreAuthorize("hasRole('ADMIN')")
@Tag(name = "Administrator Portal", description = "Endpoints for managing users, verification, analytics, and complaints")
public class AdminController {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private FarmerProfileRepository farmerProfileRepository;

    @Autowired
    private BusinessProfileRepository businessProfileRepository;

    @Autowired
    private DeliveryPartnerProfileRepository deliveryPartnerRepository;

    @Autowired
    private OrderRepository orderRepository;

    @Autowired
    private ProductRepository productRepository;

    @Autowired
    private CropContractRepository cropContractRepository;

    @Autowired
    private FarmVisitRepository farmVisitRepository;

    @GetMapping("/dashboard/stats")
    public ResponseEntity<Map<String, Object>> getStatsSummary() {
        long totalUsers = userRepository.count();
        long totalFarmers = farmerProfileRepository.count();
        long totalBusinesses = businessProfileRepository.count();
        long totalDeliveryPartners = deliveryPartnerRepository.count();
        long totalOrders = orderRepository.count();
        long totalProducts = productRepository.count();
        long totalContracts = cropContractRepository.count();
        long totalVisits = farmVisitRepository.count();

        double totalRevenue = orderRepository.findAll().stream()
                .filter(o -> o.getStatus() != com.smartkrishi.backend.models.OrderStatus.CANCELLED)
                .mapToDouble(com.smartkrishi.backend.models.Order::getTotal)
                .sum();

        long completedOrders = orderRepository.findAll().stream()
                .filter(o -> o.getStatus() == com.smartkrishi.backend.models.OrderStatus.DELIVERED)
                .count();

        Map<String, Object> stats = new HashMap<>();
        stats.put("totalUsers", totalUsers);
        stats.put("totalFarmers", totalFarmers);
        stats.put("totalBusinesses", totalBusinesses);
        stats.put("totalDeliveryPartners", totalDeliveryPartners);
        stats.put("totalOrders", totalOrders);
        stats.put("totalProducts", totalProducts);
        stats.put("totalContracts", totalContracts);
        stats.put("totalVisits", totalVisits);
        stats.put("totalRevenue", totalRevenue);
        stats.put("completedOrders", completedOrders);
        return ResponseEntity.ok(stats);
    }

    @GetMapping("/pending/farmers")
    public ResponseEntity<java.util.List<FarmerProfile>> getPendingFarmers() {
        java.util.List<FarmerProfile> pending = farmerProfileRepository.findAll().stream()
                .filter(f -> !f.isVerified())
                .toList();
        return ResponseEntity.ok(pending);
    }

    @GetMapping("/pending/delivery")
    public ResponseEntity<java.util.List<DeliveryPartnerProfile>> getPendingDeliveryPartners() {
        java.util.List<DeliveryPartnerProfile> pending = deliveryPartnerRepository.findAll().stream()
                .filter(d -> !d.isVerified())
                .toList();
        return ResponseEntity.ok(pending);
    }

    @PutMapping("/verify/farmer/{id}")
    public ResponseEntity<FarmerProfile> verifyFarmer(@PathVariable String id, @RequestParam boolean verified) {
        FarmerProfile farmer = farmerProfileRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Farmer profile not found"));
        farmer.setVerified(verified);
        return ResponseEntity.ok(farmerProfileRepository.save(farmer));
    }

    @PutMapping("/verify/business/{id}")
    public ResponseEntity<BusinessProfile> verifyBusiness(@PathVariable String id, @RequestParam boolean verified) {
        BusinessProfile business = businessProfileRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Business profile not found"));
        business.setVerified(verified);
        return ResponseEntity.ok(businessProfileRepository.save(business));
    }

    @PutMapping("/verify/delivery/{id}")
    public ResponseEntity<DeliveryPartnerProfile> verifyDelivery(@PathVariable String id, @RequestParam boolean verified) {
        DeliveryPartnerProfile delivery = deliveryPartnerRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Delivery partner profile not found"));
        delivery.setVerified(verified);
        return ResponseEntity.ok(deliveryPartnerRepository.save(delivery));
    }
}
