package com.smartkrishi.backend.controllers;

import com.smartkrishi.backend.config.UserDetailsImpl;
import com.smartkrishi.backend.dtos.MessageRequest;
import com.smartkrishi.backend.models.Chat;
import com.smartkrishi.backend.models.ChatMessage;
import com.smartkrishi.backend.services.ChatService;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/chat")
@Tag(name = "Messaging System", description = "Endpoints for secure user-to-user chat conversations")
public class ChatController {

    @Autowired
    private ChatService chatService;

    @PostMapping("/session")
    public ResponseEntity<Chat> getOrCreateSession(
            Authentication authentication,
            @RequestParam String recipientUserId,
            @RequestParam(required = false) String orderId) {
        String userId = ((UserDetailsImpl) authentication.getPrincipal()).getId();
        return ResponseEntity.ok(chatService.getOrCreateChat(userId, recipientUserId, orderId));
    }

    @PostMapping("/messages")
    public ResponseEntity<ChatMessage> sendMessage(
            Authentication authentication, @Valid @RequestBody MessageRequest request) {
        String userId = ((UserDetailsImpl) authentication.getPrincipal()).getId();
        return ResponseEntity.ok(chatService.sendMessage(userId, request));
    }

    @GetMapping("/messages/{chatId}")
    public ResponseEntity<List<ChatMessage>> getMessages(Authentication authentication, @PathVariable String chatId) {
        String userId = ((UserDetailsImpl) authentication.getPrincipal()).getId();
        return ResponseEntity.ok(chatService.getMessages(userId, chatId));
    }

    @GetMapping("/conversations")
    public ResponseEntity<List<Chat>> getConversations(Authentication authentication) {
        String userId = ((UserDetailsImpl) authentication.getPrincipal()).getId();
        return ResponseEntity.ok(chatService.getConversations(userId));
    }
}
