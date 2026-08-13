package com.smartkrishi.backend.controllers;

import com.smartkrishi.backend.config.UserDetailsImpl;
import com.smartkrishi.backend.dtos.ProductRequest;
import com.smartkrishi.backend.models.*;
import com.smartkrishi.backend.services.ProductService;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api")
@Tag(name = "Product Catalog", description = "Endpoints for category management and farmer inventory uploads")
public class ProductController {

    @Autowired
    private ProductService productService;

    @Autowired
    private com.smartkrishi.backend.repositories.UserRepository userRepository;

    @Autowired
    private com.smartkrishi.backend.repositories.BusinessProfileRepository businessProfileRepository;

    // Public endpoints
    @GetMapping("/public/categories")
    public ResponseEntity<List<Category>> getCategories() {
        return ResponseEntity.ok(productService.getAllCategories());
    }

    @GetMapping("/public/products")
    public ResponseEntity<List<Product>> getProducts(
            @RequestParam(required = false) String categoryId,
            @RequestParam(required = false) String city,
            @RequestParam(required = false) String search) {
        if (categoryId != null) {
            return ResponseEntity.ok(productService.getProductsByCategory(categoryId));
        } else if (city != null) {
            return ResponseEntity.ok(productService.getProductsByCity(city));
        } else if (search != null) {
            return ResponseEntity.ok(productService.searchProducts(search));
        }
        return ResponseEntity.ok(productService.getAllProducts());
    }

    @GetMapping("/public/products/{id}")
    public ResponseEntity<Product> getProductDetails(@PathVariable String id) {
        return ResponseEntity.ok(productService.getProductDetails(id));
    }

    @GetMapping("/public/farmers/{id}")
    public ResponseEntity<FarmerProfile> getFarmerProfileById(@PathVariable String id) {
        return ResponseEntity.ok(productService.getFarmerProfileById(id));
    }

    @GetMapping("/public/farmers")
    public ResponseEntity<List<FarmerProfile>> getAllFarmers() {
        return ResponseEntity.ok(productService.getAllFarmerProfiles());
    }

    @GetMapping("/public/users/{id}")
    public ResponseEntity<com.smartkrishi.backend.dtos.UserPublicResponse> getUserPublicProfile(@PathVariable String id) {
        User user = userRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("User not found: " + id));
        return ResponseEntity.ok(new com.smartkrishi.backend.dtos.UserPublicResponse(user.getFullName(), user.getPhoneNumber()));
    }

    // Admin endpoint
    @PostMapping("/admin/categories")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Category> createCategory(@Valid @RequestBody Category category) {
        return ResponseEntity.ok(productService.createCategory(category));
    }

    // Farmer endpoints
    @PostMapping("/farmer/products")
    @PreAuthorize("hasRole('FARMER')")
    public ResponseEntity<Product> uploadProduct(Authentication authentication, @Valid @RequestBody ProductRequest request) {
        String userId = ((UserDetailsImpl) authentication.getPrincipal()).getId();
        return ResponseEntity.ok(productService.uploadProduct(userId, request));
    }

    @PutMapping("/farmer/products/{productId}")
    @PreAuthorize("hasRole('FARMER')")
    public ResponseEntity<Product> editProduct(
            Authentication authentication,
            @PathVariable String productId,
            @Valid @RequestBody ProductRequest request) {
        String userId = ((UserDetailsImpl) authentication.getPrincipal()).getId();
        return ResponseEntity.ok(productService.editProduct(userId, productId, request));
    }

    @DeleteMapping("/farmer/products/{productId}")
    @PreAuthorize("hasRole('FARMER')")
    public ResponseEntity<Void> deleteProduct(Authentication authentication, @PathVariable String productId) {
        String userId = ((UserDetailsImpl) authentication.getPrincipal()).getId();
        productService.deleteProduct(userId, productId);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/farmer/products")
    @PreAuthorize("hasRole('FARMER')")
    public ResponseEntity<List<Product>> getFarmerProducts(@RequestParam String farmerProfileId) {
        return ResponseEntity.ok(productService.getProductsByFarmer(farmerProfileId));
    }

    @GetMapping("/farmer/profile")
    @PreAuthorize("hasRole('FARMER')")
    public ResponseEntity<FarmerProfile> getFarmerProfile(Authentication authentication) {
        String userId = ((UserDetailsImpl) authentication.getPrincipal()).getId();
        return ResponseEntity.ok(productService.getFarmerProfile(userId));
    }

    @PutMapping("/farmer/profile/location")
    @PreAuthorize("hasRole('FARMER')")
    public ResponseEntity<FarmerProfile> updateFarmerProfileLocation(
            Authentication authentication,
            @RequestParam double latitude,
            @RequestParam double longitude) {
        String userId = ((UserDetailsImpl) authentication.getPrincipal()).getId();
        return ResponseEntity.ok(productService.updateFarmerProfileLocation(userId, latitude, longitude));
    }

    @PutMapping("/farmer/profile/gallery")
    @PreAuthorize("hasRole('FARMER')")
    public ResponseEntity<FarmerProfile> updateFarmerGallery(
            Authentication authentication,
            @RequestBody List<String> imageUrls) {
        String userId = ((UserDetailsImpl) authentication.getPrincipal()).getId();
        return ResponseEntity.ok(productService.updateFarmerGallery(userId, imageUrls));
    }

    @PostMapping("/farmer/profile/gallery")
    @PreAuthorize("hasRole('FARMER')")
    public ResponseEntity<FarmerProfile> addFarmerGalleryImage(
            Authentication authentication,
            @RequestParam String imageUrl) {
        String userId = ((UserDetailsImpl) authentication.getPrincipal()).getId();
        return ResponseEntity.ok(productService.addFarmerGalleryImage(userId, imageUrl));
    }

    @DeleteMapping("/farmer/profile/gallery")
    @PreAuthorize("hasRole('FARMER')")
    public ResponseEntity<FarmerProfile> removeFarmerGalleryImage(
            Authentication authentication,
            @RequestParam String imageUrl) {
        String userId = ((UserDetailsImpl) authentication.getPrincipal()).getId();
        return ResponseEntity.ok(productService.removeFarmerGalleryImage(userId, imageUrl));
    }

    @GetMapping("/public/businesses/{id}")
    public ResponseEntity<BusinessProfile> getBusinessProfileById(@PathVariable String id) {
        BusinessProfile business = businessProfileRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Business Profile not found: " + id));
        return ResponseEntity.ok(business);
    }
}
