package com.smartkrishi.backend.repositories;

import com.smartkrishi.backend.models.DeliveryPartnerProfile;
import org.springframework.data.mongodb.repository.MongoRepository;
import java.util.List;
import java.util.Optional;

public interface DeliveryPartnerProfileRepository extends MongoRepository<DeliveryPartnerProfile, String> {
    Optional<DeliveryPartnerProfile> findByUserId(String userId);
    List<DeliveryPartnerProfile> findByOnline(boolean online);
}
