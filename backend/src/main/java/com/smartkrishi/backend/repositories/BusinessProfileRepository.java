package com.smartkrishi.backend.repositories;

import com.smartkrishi.backend.models.BusinessProfile;
import org.springframework.data.mongodb.repository.MongoRepository;
import java.util.Optional;

public interface BusinessProfileRepository extends MongoRepository<BusinessProfile, String> {
    Optional<BusinessProfile> findByUserId(String userId);
}
