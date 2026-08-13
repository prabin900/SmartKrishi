package com.smartkrishi.backend.repositories;

import com.smartkrishi.backend.models.CropContract;
import org.springframework.data.mongodb.repository.MongoRepository;
import java.util.List;

public interface CropContractRepository extends MongoRepository<CropContract, String> {
    List<CropContract> findByBusinessProfileId(String businessProfileId);
    List<CropContract> findByFarmerProfileId(String farmerProfileId);
    List<CropContract> findByAccepted(boolean accepted);
    List<CropContract> findByStatus(String status);
}
