package com.smartkrishi.backend.repositories;

import com.smartkrishi.backend.models.FarmVisit;
import org.springframework.data.mongodb.repository.MongoRepository;
import java.util.List;

public interface FarmVisitRepository extends MongoRepository<FarmVisit, String> {
    List<FarmVisit> findByCustomerId(String customerId);
    List<FarmVisit> findByFarmerProfileId(String farmerProfileId);
}
