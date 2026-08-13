package com.smartkrishi.backend.repositories;

import com.smartkrishi.backend.models.PaymentDetails;
import org.springframework.data.mongodb.repository.MongoRepository;
import java.util.Optional;

public interface PaymentDetailsRepository extends MongoRepository<PaymentDetails, String> {
    Optional<PaymentDetails> findByOrderId(String orderId);
}
