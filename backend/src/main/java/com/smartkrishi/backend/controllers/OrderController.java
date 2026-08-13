package com.smartkrishi.backend.controllers;

import com.smartkrishi.backend.config.UserDetailsImpl;
import com.smartkrishi.backend.dtos.OrderRequest;
import com.smartkrishi.backend.models.Favorite;
import com.smartkrishi.backend.models.Order;
import com.smartkrishi.backend.models.OrderStatus;
import com.smartkrishi.backend.models.Wishlist;
import com.smartkrishi.backend.services.OrderService;
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
@Tag(name = "Order Management", description = "Endpoints for order checkouts, status tracking, wishlist and favorite farms")
public class OrderController {

    @Autowired
    private OrderService orderService;

    @PostMapping("/customer/orders")
    @PreAuthorize("hasRole('CUSTOMER') or hasRole('BUSINESS')")
    public ResponseEntity<Order> placeOrder(Authentication authentication, @Valid @RequestBody OrderRequest request) {
        String userId = ((UserDetailsImpl) authentication.getPrincipal()).getId();
        return ResponseEntity.ok(orderService.placeOrder(userId, request));
    }

    @GetMapping("/orders/{id}")
    public ResponseEntity<Order> getOrderDetails(@PathVariable String id) {
        return ResponseEntity.ok(orderService.getOrderDetails(id));
    }

    @GetMapping("/customer/orders")
    @PreAuthorize("hasRole('CUSTOMER') or hasRole('BUSINESS')")
    public ResponseEntity<List<Order>> getCustomerOrders(Authentication authentication) {
        String userId = ((UserDetailsImpl) authentication.getPrincipal()).getId();
        return ResponseEntity.ok(orderService.getOrdersByCustomer(userId));
    }

    @GetMapping("/farmer/orders")
    @PreAuthorize("hasRole('FARMER')")
    public ResponseEntity<List<Order>> getFarmerOrders(@RequestParam String farmerProfileId) {
        return ResponseEntity.ok(orderService.getOrdersByFarmer(farmerProfileId));
    }

    @PatchMapping("/orders/{id}/status")
    @PreAuthorize("hasRole('FARMER') or hasRole('DELIVERY_PARTNER') or hasRole('ADMIN')")
    public ResponseEntity<Order> updateOrderStatus(
            @PathVariable String id, 
            @RequestParam OrderStatus status,
            @RequestParam(required = false) String declineReason) {
        return ResponseEntity.ok(orderService.updateOrderStatus(id, status, declineReason));
    }

    // Wishlist Endpoints
    @GetMapping("/customer/wishlist")
    @PreAuthorize("hasRole('CUSTOMER')")
    public ResponseEntity<Wishlist> getWishlist(Authentication authentication) {
        String userId = ((UserDetailsImpl) authentication.getPrincipal()).getId();
        return ResponseEntity.ok(orderService.getWishlist(userId));
    }

    @PostMapping("/customer/wishlist/{productId}")
    @PreAuthorize("hasRole('CUSTOMER')")
    public ResponseEntity<Wishlist> addToWishlist(Authentication authentication, @PathVariable String productId) {
        String userId = ((UserDetailsImpl) authentication.getPrincipal()).getId();
        return ResponseEntity.ok(orderService.addToWishlist(userId, productId));
    }

    @DeleteMapping("/customer/wishlist/{productId}")
    @PreAuthorize("hasRole('CUSTOMER')")
    public ResponseEntity<Wishlist> removeFromWishlist(Authentication authentication, @PathVariable String productId) {
        String userId = ((UserDetailsImpl) authentication.getPrincipal()).getId();
        return ResponseEntity.ok(orderService.removeFromWishlist(userId, productId));
    }

    // Favorites Endpoints
    @GetMapping("/customer/favorites")
    @PreAuthorize("hasRole('CUSTOMER')")
    public ResponseEntity<Favorite> getFavorites(Authentication authentication) {
        String userId = ((UserDetailsImpl) authentication.getPrincipal()).getId();
        return ResponseEntity.ok(orderService.getFavorites(userId));
    }

    @PostMapping("/customer/favorites/{farmerProfileId}")
    @PreAuthorize("hasRole('CUSTOMER')")
    public ResponseEntity<Favorite> addFavorite(Authentication authentication, @PathVariable String farmerProfileId) {
        String userId = ((UserDetailsImpl) authentication.getPrincipal()).getId();
        return ResponseEntity.ok(orderService.addFavoriteFarmer(userId, farmerProfileId));
    }

    @DeleteMapping("/customer/favorites/{farmerProfileId}")
    @PreAuthorize("hasRole('CUSTOMER')")
    public ResponseEntity<Favorite> removeFavorite(Authentication authentication, @PathVariable String farmerProfileId) {
        String userId = ((UserDetailsImpl) authentication.getPrincipal()).getId();
        return ResponseEntity.ok(orderService.removeFavoriteFarmer(userId, farmerProfileId));
    }
}
