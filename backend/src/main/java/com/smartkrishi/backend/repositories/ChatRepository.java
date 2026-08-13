package com.smartkrishi.backend.repositories;

import com.smartkrishi.backend.models.Chat;
import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.data.mongodb.repository.Query;
import java.util.List;
import java.util.Optional;

public interface ChatRepository extends MongoRepository<Chat, String> {
    List<Chat> findByParticipantUserIdsContaining(String userId);

    @Query("{ 'participantUserIds': { '$all': [ ?0, ?1 ] } }")
    Optional<Chat> findByParticipantUserIdsContainingAndParticipantUserIdsContaining(String userId1, String userId2);
    Optional<Chat> findByAssociatedOrderId(String associatedOrderId);
}
