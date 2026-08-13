package com.smartkrishi.backend.repositories;

import com.smartkrishi.backend.models.Product;
import org.springframework.data.mongodb.repository.MongoRepository;
import java.util.List;

public interface ProductRepository extends MongoRepository<Product, String> {
    List<Product> findByCategoryId(String categoryId);
    List<Product> findByFarmerProfileId(String farmerProfileId);
    List<Product> findByNameContainingIgnoreCase(String query);
    List<Product> findByCityIgnoreCase(String city);
}
