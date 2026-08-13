package com.smartkrishi.backend.repositories;

import com.smartkrishi.backend.models.FarmerProfile;
import org.springframework.data.mongodb.repository.MongoRepository;
import java.util.Optional;

public interface FarmerProfileRepository extends MongoRepository<FarmerProfile, String> {
    Optional<FarmerProfile> findByUserId(String userId);
}
