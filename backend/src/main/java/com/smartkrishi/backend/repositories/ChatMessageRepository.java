package com.smartkrishi.backend.repositories;

import com.smartkrishi.backend.models.ChatMessage;
import org.springframework.data.mongodb.repository.MongoRepository;
import java.util.List;

public interface ChatMessageRepository extends MongoRepository<ChatMessage, String> {
    List<ChatMessage> findByChatIdOrderByTimestampAsc(String chatId);
}
