package com.smartkrishi.backend.repositories;

import com.smartkrishi.backend.models.User;
import org.springframework.data.mongodb.repository.MongoRepository;
import java.util.List;
import java.util.Optional;

public interface UserRepository extends MongoRepository<User, String> {
    Optional<User> findByEmail(String email);
    List<User> findAllByEmail(String email);
    boolean existsByEmail(String email);
}
