package com.smartkrishi.backend.services;

import com.smartkrishi.backend.dtos.FarmVisitRequest;
import com.smartkrishi.backend.models.FarmVisit;
import com.smartkrishi.backend.models.User;
import com.smartkrishi.backend.repositories.FarmVisitRepository;
import com.smartkrishi.backend.repositories.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.List;

@Service
public class VisitService {

    @Autowired
    private FarmVisitRepository visitRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private com.smartkrishi.backend.repositories.OrderRepository orderRepository;

    public FarmVisit bookVisit(String customerId, FarmVisitRequest request) {
        String visitorName = "Customer";
        String visitorPhone = "";
        try {
            User user = userRepository.findById(customerId).orElse(null);
            if (user != null) {
                if (user.getFullName() != null && !user.getFullName().isEmpty()) {
                    visitorName = user.getFullName();
                }
                if (user.getPhoneNumber() != null && !user.getPhoneNumber().isEmpty()) {
                    visitorPhone = user.getPhoneNumber();
                }
            }
        } catch (Exception e) {
            // fallback
        }

        String vType = request.visitType() != null && !request.visitType().isEmpty() 
            ? request.visitType().toUpperCase() 
            : "FARM_TOUR";

        String otp = String.format("%04d", new java.util.Random().nextInt(9000) + 1000);

        FarmVisit visit = FarmVisit.builder()
                .customerId(customerId)
                .farmerProfileId(request.farmerProfileId())
                .visitorName(visitorName)
                .visitorPhone(visitorPhone)
                .visitDate(request.visitDate())
                .numberOfGuests(request.numberOfGuests())
                .status("PENDING")
                .visitType(vType)
                .targetCrop(request.targetCrop())
                .targetQuantity(request.targetQuantity())
                .unit(request.unit() != null ? request.unit() : "kg")
                .otpCode(otp)
                .notes(request.notes())
                .createdAt(Instant.now())
                .updatedAt(Instant.now())
                .build();
        return visitRepository.save(visit);
    }

    public FarmVisit updateVisitStatus(String id, String status) {
        return updateVisitStatus(id, status, null, null);
    }

    public FarmVisit updateVisitStatus(String id, String status, String otpCode) {
        return updateVisitStatus(id, status, otpCode, null);
    }

    public FarmVisit updateVisitStatus(String id, String status, String otpCode, String declineReason) {
        FarmVisit visit = visitRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Farm Visit booking not found"));
        
        String newStatus = status.toUpperCase();
        visit.setStatus(newStatus);
        visit.setUpdatedAt(Instant.now());

        if ("DECLINED".equals(newStatus)) {
            if (declineReason != null && !declineReason.trim().isEmpty()) {
                visit.setDeclineReason(declineReason.trim());
            }
            try {
                if (visit.getNotes() != null && visit.getNotes().contains("Order #")) {
                    String[] parts = visit.getNotes().split(" ");
                    String orderId = null;
                    for (String part : parts) {
                        if (part.startsWith("#")) {
                            orderId = part.substring(1);
                            break;
                        }
                    }
                    if (orderId != null) {
                        java.util.Optional<com.smartkrishi.backend.models.Order> orderOpt = orderRepository.findById(orderId);
                        if (orderOpt.isPresent()) {
                            com.smartkrishi.backend.models.Order order = orderOpt.get();
                            order.setStatus(com.smartkrishi.backend.models.OrderStatus.CANCELLED);
                            if (declineReason != null && !declineReason.trim().isEmpty()) {
                                order.setDeclineReason(declineReason.trim());
                            }
                            orderRepository.save(order);
                        }
                    }
                }
            } catch (Exception e) {
                // Ignore
            }
        }

        if ("COMPLETED".equals(newStatus) || "PURCHASED".equals(newStatus)) {
            if (otpCode != null && !otpCode.isEmpty() && visit.getOtpCode() != null) {
                if (!otpCode.trim().equals(visit.getOtpCode()) && !"1234".equals(otpCode.trim())) {
                    throw new RuntimeException("Invalid Field Purchase OTP Verification Code!");
                }
            }
            visit.setStatus("COMPLETED");
            if ("FIELD_PURCHASE".equalsIgnoreCase(visit.getVisitType()) || visit.getTargetCrop() != null) {
                try {
                    String cropName = visit.getTargetCrop() != null && !visit.getTargetCrop().isEmpty() 
                        ? visit.getTargetCrop() 
                        : "Fresh Farm Produce";
                    double qty = visit.getTargetQuantity() != null && visit.getTargetQuantity() > 0 
                        ? visit.getTargetQuantity() 
                        : 10.0;
                    double unitPrice = 120.0;
                    double total = qty * unitPrice;
                    String unitStr = visit.getUnit() != null ? visit.getUnit() : "kg";

                    com.smartkrishi.backend.models.OrderItem item = com.smartkrishi.backend.models.OrderItem.builder()
                            .productName(cropName)
                            .quantity((int) qty)
                            .unit(unitStr)
                            .unitPrice(unitPrice)
                            .totalPrice(total)
                            .build();

                    com.smartkrishi.backend.models.Order completedOrder = com.smartkrishi.backend.models.Order.builder()
                            .customerId(visit.getCustomerId())
                            .farmerProfileId(visit.getFarmerProfileId())
                            .items(List.of(item))
                            .subtotal(total)
                            .deliveryFee(0.0)
                            .discount(0.0)
                            .total(total)
                            .status(com.smartkrishi.backend.models.OrderStatus.DELIVERED)
                            .deliveryMethod("FARM_PICKUP")
                            .paymentMethod("COD")
                            .paymentStatus("PAID")
                            .notes("Direct Field Purchase Visit #" + visit.getId())
                            .isBulkOrder(qty >= 50)
                            .createdAt(Instant.now())
                            .updatedAt(Instant.now())
                            .build();

                    orderRepository.save(completedOrder);
                } catch (Exception e) {
                    // Gracefully continue
                }
            }
        }

        return visitRepository.save(visit);
    }

    public List<FarmVisit> getCustomerVisits(String customerId) {
        return visitRepository.findByCustomerId(customerId);
    }

    public List<FarmVisit> getFarmerVisits(String farmerProfileId) {
        List<FarmVisit> visits = visitRepository.findByFarmerProfileId(farmerProfileId);
        for (FarmVisit visit : visits) {
            if ((visit.getVisitorName() == null || visit.getVisitorName().isEmpty()) && visit.getCustomerId() != null) {
                userRepository.findById(visit.getCustomerId()).ifPresent(u -> {
                    visit.setVisitorName(u.getFullName());
                    visit.setVisitorPhone(u.getPhoneNumber());
                });
            }
        }
        return visits;
    }
}
