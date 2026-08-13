package com.smartkrishi.backend.services;

import com.smartkrishi.backend.dtos.OrderRequest;
import com.smartkrishi.backend.models.*;
import com.smartkrishi.backend.repositories.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.security.SecureRandom;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class OrderService {

    @Autowired
    private com.smartkrishi.backend.repositories.FarmVisitRepository visitRepository;

    @Autowired
    private OrderRepository orderRepository;

    @Autowired
    private ProductRepository productRepository;

    @Autowired
    private InventoryRepository inventoryRepository;

    @Autowired
    private WishlistRepository wishlistRepository;

    @Autowired
    private FavoriteRepository favoriteRepository;

    @Autowired
    private DeliveryDetailsRepository deliveryDetailsRepository;

    @Autowired
    private DeliveryPartnerProfileRepository deliveryPartnerProfileRepository;

    private final SecureRandom secureRandom = new SecureRandom();

    @Transactional
    public Order placeOrder(String customerId, OrderRequest request) {
        List<OrderItem> orderItems = new ArrayList<>();

        for (OrderRequest.CartItemRequest itemReq : request.items()) {
            Product product = productRepository.findById(itemReq.productId())
                    .orElseThrow(() -> new RuntimeException("Product not found: " + itemReq.productId()));

            if (product.getAvailableQuantity() < itemReq.quantity()) {
                throw new RuntimeException("Insufficient stock for product: " + product.getName());
            }

            // Reserve stock
            product.setAvailableQuantity(product.getAvailableQuantity() - itemReq.quantity());
            product.setReservedQuantity(product.getReservedQuantity() + itemReq.quantity());
            productRepository.save(product);

            // Log inventory reservation
            inventoryRepository.save(Inventory.builder()
                    .productId(product.getId())
                    .quantityChanged(-itemReq.quantity())
                    .changeType("RESERVED")
                    .remarks("Reserved for order checkout")
                    .timestamp(Instant.now())
                    .build());

            OrderItem orderItem = OrderItem.builder()
                    .productId(product.getId())
                    .productName(product.getName())
                    .productImage(product.getImageUrls().isEmpty() ? "" : product.getImageUrls().get(0))
                    .unitPrice(itemReq.unitPrice())
                    .quantity(itemReq.quantity())
                    .unit(itemReq.unit())
                    .totalPrice(itemReq.unitPrice() * itemReq.quantity())
                    .build();

            orderItems.add(orderItem);
        }

        Address shippingAddress = null;
        if (request.shippingAddress() != null) {
            shippingAddress = Address.builder()
                    .streetAddress(request.shippingAddress().streetAddress())
                    .city(request.shippingAddress().city())
                    .district(request.shippingAddress().district())
                    .state(request.shippingAddress().state())
                    .latitude(request.shippingAddress().latitude())
                    .longitude(request.shippingAddress().longitude())
                    .build();
        }

        // Generate verification pins
        String otp = String.format("%06d", secureRandom.nextInt(1000000));
        String qrData = "SMARTKRISHI-ORDER-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase();

        Order order = Order.builder()
                .customerId(customerId)
                .farmerProfileId(request.farmerProfileId())
                .items(orderItems)
                .subtotal(request.subtotal())
                .deliveryFee(request.deliveryFee())
                .discount(request.discount())
                .total(request.total())
                .status(OrderStatus.PENDING)
                .deliveryMethod(request.deliveryMethod())
                .shippingAddress(shippingAddress)
                .paymentMethod(request.paymentMethod())
                .paymentStatus("PENDING")
                .otpCode(otp)
                .qrCodeData(qrData)
                .notes(request.notes())
                .isBulkOrder(request.isBulkOrder())
                .createdAt(Instant.now())
                .updatedAt(Instant.now())
                .build();

        Order savedOrder = orderRepository.save(order);

        // Initialize Delivery Tracking details
        DeliveryDetails deliveryDetails = DeliveryDetails.builder()
                .orderId(savedOrder.getId())
                .timeline(new ArrayList<>())
                .build();
        deliveryDetails.getTimeline().add(new DeliveryDetails.TrackingMilestone(
                "PENDING",
                "Order placed by customer, awaiting farmer confirmation",
                Instant.now()
        ));
        deliveryDetailsRepository.save(deliveryDetails);

        return savedOrder;
    }

    @Transactional
    public Order updateOrderStatus(String orderId, OrderStatus newStatus) {
        return updateOrderStatus(orderId, newStatus, null);
    }

    @Transactional
    public Order updateOrderStatus(String orderId, OrderStatus newStatus, String declineReason) {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new RuntimeException("Order not found: " + orderId));

        order.setStatus(newStatus);
        order.setUpdatedAt(Instant.now());

        if (newStatus == OrderStatus.CANCELLED && declineReason != null && !declineReason.trim().isEmpty()) {
            order.setDeclineReason(declineReason.trim());
        }

        if (newStatus == OrderStatus.CANCELLED) {
            try {
                // Find and decline associated farm visit if any
                java.util.List<com.smartkrishi.backend.models.FarmVisit> visits = visitRepository.findAll();
                for (com.smartkrishi.backend.models.FarmVisit v : visits) {
                    if (v.getNotes() != null && v.getNotes().contains("Order #" + orderId)) {
                        v.setStatus("DECLINED");
                        if (declineReason != null && !declineReason.trim().isEmpty()) {
                            v.setDeclineReason(declineReason.trim());
                        }
                        visitRepository.save(v);
                    }
                }
            } catch (Exception e) {
                // Ignore
            }
        }

        // Handle specific inventory deductions upon final states
        if (newStatus == OrderStatus.DELIVERED) {
            order.setPaymentStatus("PAID");
            for (OrderItem item : order.getItems()) {
                Optional<Product> prodOpt = productRepository.findById(item.getProductId());
                if (prodOpt.isPresent()) {
                    Product product = prodOpt.get();
                    product.setReservedQuantity(Math.max(0, product.getReservedQuantity() - item.getQuantity()));
                    product.setSoldQuantity(product.getSoldQuantity() + item.getQuantity());
                    productRepository.save(product);

                    inventoryRepository.save(Inventory.builder()
                            .productId(product.getId())
                            .quantityChanged(item.getQuantity())
                            .changeType("SOLD")
                            .remarks("Sold via order: " + orderId)
                            .timestamp(Instant.now())
                            .build());
                }
            }
        } else if (newStatus == OrderStatus.CANCELLED) {
            // Revert reserved stock back to available
            for (OrderItem item : order.getItems()) {
                Optional<Product> prodOpt = productRepository.findById(item.getProductId());
                if (prodOpt.isPresent()) {
                    Product product = prodOpt.get();
                    product.setReservedQuantity(Math.max(0, product.getReservedQuantity() - item.getQuantity()));
                    product.setAvailableQuantity(product.getAvailableQuantity() + item.getQuantity());
                    productRepository.save(product);

                    inventoryRepository.save(Inventory.builder()
                            .productId(product.getId())
                            .quantityChanged(item.getQuantity())
                            .changeType("RELEASED")
                            .remarks("Released from cancelled order: " + orderId)
                            .timestamp(Instant.now())
                            .build());
                }
            }
        }

        Order saved = orderRepository.save(order);

        // Update Tracking timeline
        DeliveryDetails details = deliveryDetailsRepository.findByOrderId(orderId)
                .orElse(DeliveryDetails.builder().orderId(orderId).timeline(new ArrayList<>()).build());
        details.getTimeline().add(new DeliveryDetails.TrackingMilestone(
                newStatus.name(),
                getDescriptionForStatus(newStatus),
                Instant.now()
        ));
        if (order.getDeliveryPartnerId() != null) {
            details.setDeliveryPartnerId(order.getDeliveryPartnerId());
        }
        deliveryDetailsRepository.save(details);

        return saved;
    }

    private String getDescriptionForStatus(OrderStatus status) {
        return switch (status) {
            case PENDING -> "Order submitted and pending validation.";
            case ACCEPTED -> "Farmer has accepted and acknowledged the order.";
            case HARVEST_STARTED -> "Farmer has started harvesting fresh crops directly from fields.";
            case HARVEST_COMPLETED -> "Harvest complete. Produce is packed and ready.";
            case PICKUP_ASSIGNED -> "Delivery partner assigned and headed to farm.";
            case PICKED_UP -> "Delivery partner picked up packages from farm.";
            case OUT_FOR_DELIVERY -> "Order is out for final delivery.";
            case DELIVERED -> "Successfully delivered and verified.";
            case CANCELLED -> "Order has been cancelled.";
        };
    }

    public List<Order> getOrdersByCustomer(String customerId) {
        return orderRepository.findByCustomerId(customerId);
    }

    public List<Order> getOrdersByFarmer(String farmerProfileId) {
        return orderRepository.findByFarmerProfileId(farmerProfileId);
    }

    public Order getOrderDetails(String id) {
        return orderRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Order not found"));
    }

    // Wishlist functions
    @Transactional
    public Wishlist addToWishlist(String userId, String productId) {
        Wishlist wishlist = wishlistRepository.findByUserId(userId)
                .orElseGet(() -> Wishlist.builder().userId(userId).productIds(new java.util.HashSet<>()).build());
        wishlist.getProductIds().add(productId);
        return wishlistRepository.save(wishlist);
    }

    @Transactional
    public Wishlist removeFromWishlist(String userId, String productId) {
        Wishlist wishlist = wishlistRepository.findByUserId(userId)
                .orElseThrow(() -> new RuntimeException("Wishlist not found"));
        wishlist.getProductIds().remove(productId);
        return wishlistRepository.save(wishlist);
    }

    public Wishlist getWishlist(String userId) {
        return wishlistRepository.findByUserId(userId)
                .orElseGet(() -> wishlistRepository.save(Wishlist.builder().userId(userId).productIds(new java.util.HashSet<>()).build()));
    }

    // Favorites functions
    @Transactional
    public Favorite addFavoriteFarmer(String userId, String farmerProfileId) {
        Favorite fav = favoriteRepository.findByUserId(userId)
                .orElseGet(() -> Favorite.builder().userId(userId).farmerProfileIds(new java.util.HashSet<>()).build());
        fav.getFarmerProfileIds().add(farmerProfileId);
        return favoriteRepository.save(fav);
    }

    @Transactional
    public Favorite removeFavoriteFarmer(String userId, String farmerProfileId) {
        Favorite fav = favoriteRepository.findByUserId(userId)
                .orElseThrow(() -> new RuntimeException("Favorites not found"));
        fav.getFarmerProfileIds().remove(farmerProfileId);
        return favoriteRepository.save(fav);
    }

    public Favorite getFavorites(String userId) {
        return favoriteRepository.findByUserId(userId)
                .orElseGet(() -> favoriteRepository.save(Favorite.builder().userId(userId).farmerProfileIds(new java.util.HashSet<>()).build()));
    }
}
