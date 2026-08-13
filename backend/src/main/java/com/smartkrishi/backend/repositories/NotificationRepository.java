package com.smartkrishi.backend.repositories;

import com.smartkrishi.backend.models.Notification;
import org.springframework.data.mongodb.repository.MongoRepository;
import java.util.List;

public interface NotificationRepository extends MongoRepository<Notification, String> {
    List<Notification> findByUserIdOrderByTimestampDesc(String userId);
    List<Notification> findByUserIdAndRead(String userId, boolean read);
}
