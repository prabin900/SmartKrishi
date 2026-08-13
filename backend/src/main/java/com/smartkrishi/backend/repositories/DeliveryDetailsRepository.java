package com.smartkrishi.backend.repositories;

import com.smartkrishi.backend.models.DeliveryDetails;
import org.springframework.data.mongodb.repository.MongoRepository;
import java.util.Optional;

public interface DeliveryDetailsRepository extends MongoRepository<DeliveryDetails, String> {
    Optional<DeliveryDetails> findByOrderId(String orderId);
}
