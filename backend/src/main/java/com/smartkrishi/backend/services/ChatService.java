package com.smartkrishi.backend.services;

import com.smartkrishi.backend.dtos.MessageRequest;
import com.smartkrishi.backend.models.Chat;
import com.smartkrishi.backend.models.ChatMessage;
import com.smartkrishi.backend.repositories.ChatMessageRepository;
import com.smartkrishi.backend.repositories.ChatRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.Arrays;
import java.util.List;
import java.util.Optional;

@Service
public class ChatService {

    @Autowired
    private ChatRepository chatRepository;

    @Autowired
    private ChatMessageRepository messageRepository;

    @Transactional
    public Chat getOrCreateChat(String senderUserId, String recipientUserId, String orderId) {
        // Try to find existing chat between these participants
        Optional<Chat> chatOpt = chatRepository.findByParticipantUserIdsContainingAndParticipantUserIdsContaining(
                senderUserId, recipientUserId);
        
        if (chatOpt.isPresent()) {
            Chat chat = chatOpt.get();
            if (orderId != null && !orderId.equals(chat.getAssociatedOrderId())) {
                chat.setAssociatedOrderId(orderId);
                chatRepository.save(chat);
            }
            return chat;
        }

        Chat newChat = Chat.builder()
                .participantUserIds(Arrays.asList(senderUserId, recipientUserId))
                .associatedOrderId(orderId)
                .lastMessageTimestamp(Instant.now())
                .lastMessageText("Conversation started")
                .build();
        
        return chatRepository.save(newChat);
    }

    @Transactional
    public ChatMessage sendMessage(String senderUserId, MessageRequest request) {
        Chat chat = chatRepository.findById(request.chatId())
                .orElseThrow(() -> new RuntimeException("Conversation not found"));

        if (!chat.getParticipantUserIds().contains(senderUserId)) {
            throw new RuntimeException("Unauthorized: You are not a participant in this conversation");
        }

        ChatMessage message = ChatMessage.builder()
                .chatId(chat.getId())
                .senderUserId(senderUserId)
                .text(request.text())
                .imageUrl(request.imageUrl())
                .timestamp(Instant.now())
                .build();

        ChatMessage savedMessage = messageRepository.save(message);

        chat.setLastMessageTimestamp(savedMessage.getTimestamp());
        chat.setLastMessageText(savedMessage.getText() != null ? savedMessage.getText() : "Sent an image");
        chatRepository.save(chat);

        return savedMessage;
    }

    public List<ChatMessage> getMessages(String userId, String chatId) {
        Chat chat = chatRepository.findById(chatId)
                .orElseThrow(() -> new RuntimeException("Conversation not found"));

        if (!chat.getParticipantUserIds().contains(userId)) {
            throw new RuntimeException("Unauthorized");
        }

        return messageRepository.findByChatIdOrderByTimestampAsc(chatId);
    }

    public List<Chat> getConversations(String userId) {
        return chatRepository.findByParticipantUserIdsContaining(userId);
    }
}
