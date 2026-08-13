package com.smartkrishi.backend.repositories;

import com.smartkrishi.backend.models.Inventory;
import org.springframework.data.mongodb.repository.MongoRepository;
import java.util.List;

public interface InventoryRepository extends MongoRepository<Inventory, String> {
    List<Inventory> findByProductId(String productId);
}
