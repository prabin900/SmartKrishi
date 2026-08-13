package com.smartkrishi.backend.repositories;

import com.smartkrishi.backend.models.Address;
import org.springframework.data.mongodb.repository.MongoRepository;
import java.util.List;
import java.util.Optional;

public interface AddressRepository extends MongoRepository<Address, String> {
    List<Address> findByUserId(String userId);
    Optional<Address> findByUserIdAndIsDefault(String userId, boolean isDefault);
}
