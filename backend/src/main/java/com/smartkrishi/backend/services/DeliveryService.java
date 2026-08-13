package com.smartkrishi.backend.services;

import com.smartkrishi.backend.models.*;
import com.smartkrishi.backend.repositories.DeliveryDetailsRepository;
import com.smartkrishi.backend.repositories.DeliveryPartnerProfileRepository;
import com.smartkrishi.backend.repositories.OrderRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;

@Service
public class DeliveryService {

    @Autowired
    private DeliveryPartnerProfileRepository partnerRepository;

    @Autowired
    private OrderRepository orderRepository;

    @Autowired
    private DeliveryDetailsRepository trackingRepository;

    @Autowired
    private OrderService orderService;

    public DeliveryPartnerProfile updateOnlineStatus(String userId, boolean online) {
        DeliveryPartnerProfile partner = partnerRepository.findByUserId(userId)
                .orElseThrow(() -> new RuntimeException("Delivery Partner profile not found"));
        partner.setOnline(online);
        return partnerRepository.save(partner);
    }

    public DeliveryPartnerProfile updateLocation(String userId, double lat, double lon) {
        DeliveryPartnerProfile partner = partnerRepository.findByUserId(userId)
                .orElseThrow(() -> new RuntimeException("Delivery Partner profile not found"));
        partner.setCurrentLatitude(lat);
        partner.setCurrentLongitude(lon);
        
        // Also update any active tracking coordinates
        List<Order> activeOrders = orderRepository.findByDeliveryPartnerId(userId);
        for (Order order : activeOrders) {
            if (order.getStatus() == OrderStatus.PICKED_UP || order.getStatus() == OrderStatus.OUT_FOR_DELIVERY) {
                trackingRepository.findByOrderId(order.getId()).ifPresent(details -> {
                    details.setCurrentLatitude(lat);
                    details.setCurrentLongitude(lon);
                    trackingRepository.save(details);
                });
            }
        }
        
        return partnerRepository.save(partner);
    }

    @Transactional
    public Order assignDeliveryPartner(String orderId, String partnerUserId) {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new RuntimeException("Order not found"));
        
        order.setDeliveryPartnerId(partnerUserId);
        orderRepository.save(order);
        
        Order finalUpdated = orderService.updateOrderStatus(orderId, OrderStatus.PICKUP_ASSIGNED);
        
        // Update partner ID on delivery details
        trackingRepository.findByOrderId(orderId).ifPresent(details -> {
            details.setDeliveryPartnerId(partnerUserId);
            trackingRepository.save(details);
        });
        
        return finalUpdated;
    }

    @Transactional
    public boolean verifyOtpHandshake(String orderId, String otp) {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new RuntimeException("Order not found"));
        
        if (order.getOtpCode().equals(otp)) {
            // Success: update status to DELIVERED
            orderService.updateOrderStatus(orderId, OrderStatus.DELIVERED);
            
            // Increment partner deliveries
            if (order.getDeliveryPartnerId() != null) {
                partnerRepository.findByUserId(order.getDeliveryPartnerId()).ifPresent(partner -> {
                    partner.setDeliveryCount(partner.getDeliveryCount() + 1);
                    partnerRepository.save(partner);
                });
            }
            return true;
        }
        return false;
    }

    @Transactional
    public boolean verifyQrHandshake(String orderId, String qrCode) {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new RuntimeException("Order not found"));
        
        if (order.getQrCodeData().equals(qrCode)) {
            // Success: update status to DELIVERED
            orderService.updateOrderStatus(orderId, OrderStatus.DELIVERED);
            
            if (order.getDeliveryPartnerId() != null) {
                partnerRepository.findByUserId(order.getDeliveryPartnerId()).ifPresent(partner -> {
                    partner.setDeliveryCount(partner.getDeliveryCount() + 1);
                    partnerRepository.save(partner);
                });
            }
            return true;
        }
        return false;
    }

    public List<Order> getPartnerDeliveryHistory(String partnerUserId) {
        return orderRepository.findByDeliveryPartnerId(partnerUserId);
    }

    public double getPartnerEarnings(String partnerUserId) {
        // Simple mock calculations: NPR 150 per successful delivery
        List<Order> completed = orderRepository.findByDeliveryPartnerId(partnerUserId).stream()
                .filter(o -> o.getStatus() == OrderStatus.DELIVERED)
                .toList();
        return completed.size() * 150.0;
    }

    public List<Order> getAvailableOrdersForPickup() {
        List<OrderStatus> statuses = List.of(OrderStatus.ACCEPTED, OrderStatus.HARVEST_STARTED, OrderStatus.HARVEST_COMPLETED);
        return orderRepository.findAll().stream()
                .filter(o -> statuses.contains(o.getStatus())
                        && o.getDeliveryPartnerId() == null
                        && (o.getDeliveryMethod() == null || "HOME_DELIVERY".equalsIgnoreCase(o.getDeliveryMethod())))
                .toList();
    }
}
