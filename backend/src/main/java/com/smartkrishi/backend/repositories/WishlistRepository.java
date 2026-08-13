package com.smartkrishi.backend.repositories;

import com.smartkrishi.backend.models.Wishlist;
import org.springframework.data.mongodb.repository.MongoRepository;
import java.util.Optional;

public interface WishlistRepository extends MongoRepository<Wishlist, String> {
    Optional<Wishlist> findByUserId(String userId);
}
