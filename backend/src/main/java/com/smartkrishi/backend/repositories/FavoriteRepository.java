package com.smartkrishi.backend.repositories;

import com.smartkrishi.backend.models.Favorite;
import org.springframework.data.mongodb.repository.MongoRepository;
import java.util.Optional;

public interface FavoriteRepository extends MongoRepository<Favorite, String> {
    Optional<Favorite> findByUserId(String userId);
}
