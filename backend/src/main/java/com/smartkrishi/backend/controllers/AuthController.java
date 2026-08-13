package com.smartkrishi.backend.controllers;

import com.smartkrishi.backend.dtos.*;
import com.smartkrishi.backend.services.AuthService;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/auth")
@Tag(name = "Authentication", description = "Endpoints for user register, login, reset password and token refresh")
public class AuthController {

    @Autowired
    private AuthService authService;

    @PostMapping("/register")
    public ResponseEntity<MessageResponse> register(@Valid @RequestBody RegisterRequest request) {
        return ResponseEntity.ok(authService.registerUser(request));
    }

    @PostMapping("/login")
    public ResponseEntity<JwtResponse> login(@Valid @RequestBody LoginRequest request) {
        return ResponseEntity.ok(authService.authenticateUser(request));
    }

    @PostMapping("/refresh")
    public ResponseEntity<TokenRefreshResponse> refresh(@Valid @RequestBody TokenRefreshRequest request) {
        return ResponseEntity.ok(authService.refreshAccessToken(request));
    }

    @PostMapping("/forgot-password")
    public ResponseEntity<MessageResponse> forgotPassword(@RequestParam String email) {
        return ResponseEntity.ok(authService.sendForgotPasswordCode(email));
    }

    @PostMapping("/reset-password")
    public ResponseEntity<MessageResponse> resetPassword(
            @RequestParam String email, 
            @RequestParam String code, 
            @RequestParam String newPassword) {
        return ResponseEntity.ok(authService.resetPassword(email, code, newPassword));
    }

    @PostMapping("/verify-email")
    public ResponseEntity<MessageResponse> verifyEmail(@RequestParam String email, @RequestParam String code) {
        return ResponseEntity.ok(authService.verifyEmail(email, code));
    }

    @PostMapping("/resend-code")
    public ResponseEntity<MessageResponse> resendCode(@RequestParam String email) {
        return ResponseEntity.ok(authService.resendVerificationCode(email));
    }
}
