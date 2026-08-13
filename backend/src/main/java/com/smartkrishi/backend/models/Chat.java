package com.smartkrishi.backend.models;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;

import java.time.Instant;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Document(collection = "chats")
public class Chat {
    @Id
    private String id;
    private List<String> participantUserIds; // e.g. [customerUserId, farmerUserId]
    private String associatedOrderId; // Optional link to an active order
    private Instant lastMessageTimestamp;
    private String lastMessageText;
}
