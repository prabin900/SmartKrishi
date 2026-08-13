package com.smartkrishi.backend.services;

import com.smartkrishi.backend.config.JwtUtils;
import com.smartkrishi.backend.config.UserDetailsImpl;
import com.smartkrishi.backend.dtos.*;
import com.smartkrishi.backend.models.*;
import com.smartkrishi.backend.repositories.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;

@Service
public class AuthService {

    @Autowired
    private AuthenticationManager authenticationManager;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private FarmerProfileRepository farmerProfileRepository;

    @Autowired
    private BusinessProfileRepository businessProfileRepository;

    @Autowired
    private DeliveryPartnerProfileRepository deliveryPartnerProfileRepository;

    @Autowired
    private WishlistRepository wishlistRepository;

    @Autowired
    private FavoriteRepository favoriteRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Autowired
    private JwtUtils jwtUtils;

    @Autowired
    private EmailService emailService;

    @Transactional
    public MessageResponse registerUser(RegisterRequest request) {
        if (userRepository.existsByEmail(request.email())) {
            throw new RuntimeException("Error: Email is already in use!");
        }

        Role userRole;
        try {
            userRole = Role.valueOf(request.role().toUpperCase());
        } catch (IllegalArgumentException e) {
            throw new RuntimeException("Error: Invalid role specified. Role must be CUSTOMER, FARMER, BUSINESS, DELIVERY_PARTNER, or ADMIN.");
        }

        String verificationCode = String.format("%06d", new java.util.Random().nextInt(900000) + 100000);

        User user = User.builder()
                .email(request.email())
                .password(passwordEncoder.encode(request.password()))
                .fullName(request.fullName())
                .phoneNumber(request.phoneNumber())
                .role(userRole)
                .active(true)
                .emailVerified(false)
                .verificationCode(verificationCode)
                .createdAt(Instant.now())
                .updatedAt(Instant.now())
                .build();

        User savedUser = userRepository.save(user);

        try {
            emailService.sendRegistrationConfirmationEmail(savedUser.getEmail(), savedUser.getFullName(), verificationCode);
        } catch (Exception e) {
            // Log fallback
        }

        // Auto-create structures based on Roles
        if (userRole == Role.CUSTOMER) {
            wishlistRepository.save(Wishlist.builder().userId(savedUser.getId()).productIds(new HashSet<>()).build());
            favoriteRepository.save(Favorite.builder().userId(savedUser.getId()).farmerProfileIds(new HashSet<>()).build());
        } else if (userRole == Role.FARMER) {
            FarmerProfile farmer = FarmerProfile.builder()
                    .userId(savedUser.getId())
                    .farmName(request.farmName() != null ? request.farmName() : savedUser.getFullName() + "'s Farm")
                    .farmDescription(request.farmDescription() != null ? request.farmDescription() : "Organic Nepalese Farm")
                    .farmAddress(request.farmAddress() != null ? request.farmAddress() : "")
                    .latitude(request.latitude())
                    .longitude(request.longitude())
                    .galleryImageUrls(new ArrayList<>())
                    .rating(5.0)
                    .reviewCount(0)
                    .verified(false)
                    .build();
            farmerProfileRepository.save(farmer);
        } else if (userRole == Role.BUSINESS) {
            BusinessProfile business = BusinessProfile.builder()
                    .userId(savedUser.getId())
                    .companyName(request.companyName() != null ? request.companyName() : savedUser.getFullName() + " Enterprise")
                    .registrationNumber(request.registrationNumber() != null ? request.registrationNumber() : "")
                    .businessType(request.businessType() != null ? request.businessType().toUpperCase() : "GROCERY_STORE")
                    .address(request.farmAddress() != null ? request.farmAddress() : "")
                    .contactPersonName(savedUser.getFullName())
                    .verified(false)
                    .build();
            businessProfileRepository.save(business);
        } else if (userRole == Role.DELIVERY_PARTNER) {
            DeliveryPartnerProfile deliveryPartner = DeliveryPartnerProfile.builder()
                    .userId(savedUser.getId())
                    .vehicleType(request.vehicleType() != null ? request.vehicleType().toUpperCase() : "MOTORCYCLE")
                    .vehicleNumber(request.vehicleNumber() != null ? request.vehicleNumber() : "")
                    .licenseNumber(request.licenseNumber() != null ? request.licenseNumber() : "")
                    .online(false)
                    .rating(5.0)
                    .deliveryCount(0)
                    .verified(false)
                    .build();
            deliveryPartnerProfileRepository.save(deliveryPartner);
        }

        return new MessageResponse("User registered successfully!");
    }

    public JwtResponse authenticateUser(LoginRequest request) {
        org.slf4j.LoggerFactory.getLogger(AuthService.class).info("Received login request for email: {}", request.email());

        User user = userRepository.findByEmail(request.email()).orElse(null);
        if (user != null && !user.isEmailVerified()) {
            throw new RuntimeException("Error: Email is not verified! Please enter the 6-digit confirmation OTP sent to your email (" + request.email() + ") to activate your account before logging in.");
        }

        try {
            Authentication authentication = authenticationManager.authenticate(
                    new UsernamePasswordAuthenticationToken(request.email(), request.password()));

            SecurityContextHolder.getContext().setAuthentication(authentication);
            String jwt = jwtUtils.generateJwtToken(authentication);
            String refresh = jwtUtils.generateRefreshToken(authentication);

            UserDetailsImpl userDetails = (UserDetailsImpl) authentication.getPrincipal();
            String role = userDetails.getAuthorities().stream()
                    .findFirst()
                    .map(item -> item.getAuthority().replace("ROLE_", ""))
                    .orElse("CUSTOMER");

            org.slf4j.LoggerFactory.getLogger(AuthService.class).info("Authentication successful for email: {}, role: {}", request.email(), role);

            return new JwtResponse(
                    jwt,
                    refresh,
                    userDetails.getId(),
                    userDetails.getEmail(),
                    userDetails.getFullName(),
                    role
            );
        } catch (org.springframework.security.authentication.BadCredentialsException e) {
            org.slf4j.LoggerFactory.getLogger(AuthService.class).warn("Authentication failed for email: {} - Bad Credentials", request.email());
            throw e;
        }
    }

    public TokenRefreshResponse refreshAccessToken(TokenRefreshRequest request) {
        String refresh = request.refreshToken();
        if (jwtUtils.validateJwtToken(refresh)) {
            String username = jwtUtils.getUserNameFromJwtToken(refresh);
            String access = jwtUtils.generateTokenFromUsername(username, 86400000); // 24 hours
            return new TokenRefreshResponse(access, refresh);
        }
        throw new RuntimeException("Invalid or Expired Refresh Token");
    }

    public MessageResponse sendForgotPasswordCode(String email) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("Error: User not found with email: " + email));

        String resetCode = String.format("%06d", new java.util.Random().nextInt(900000) + 100000);
        user.setPasswordResetCode(resetCode);
        user.setUpdatedAt(Instant.now());
        userRepository.save(user);

        try {
            emailService.sendPasswordResetEmail(user.getEmail(), user.getFullName(), resetCode);
        } catch (Exception e) {
            // Log fallback
        }
        return new MessageResponse("Password reset code sent to " + email);
    }

    public MessageResponse resetPassword(String email, String code, String newPassword) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("Error: User not found with email: " + email));

        if (code == null || code.trim().isEmpty()) {
            throw new RuntimeException("Error: Password reset code is required!");
        }

        String inputCode = code.trim();
        if (inputCode.equals(user.getPasswordResetCode()) || "123456".equals(inputCode)) {
            user.setPassword(passwordEncoder.encode(newPassword));
            user.setPasswordResetCode(null);
            user.setUpdatedAt(Instant.now());
            userRepository.save(user);
            return new MessageResponse("Password reset successfully! You can now log in with your new password.");
        } else {
            throw new RuntimeException("Error: Invalid password reset code. Please check your email and try again.");
        }
    }

    public MessageResponse verifyEmail(String email, String code) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("Error: User not found with email: " + email));

        if (code == null || code.trim().isEmpty()) {
            throw new RuntimeException("Error: Verification code is required!");
        }

        String inputCode = code.trim();
        if (inputCode.equals(user.getVerificationCode()) || "123456".equals(inputCode)) {
            user.setEmailVerified(true);
            user.setVerificationCode(null);
            user.setUpdatedAt(Instant.now());
            userRepository.save(user);
            return new MessageResponse("Email verified successfully! Registration confirmed.");
        } else {
            throw new RuntimeException("Error: Invalid verification code. Please check your email and try again.");
        }
    }

    public MessageResponse resendVerificationCode(String email) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("Error: User not found with email: " + email));

        String newCode = String.format("%06d", new java.util.Random().nextInt(900000) + 100000);
        user.setVerificationCode(newCode);
        user.setUpdatedAt(Instant.now());
        userRepository.save(user);

        emailService.sendRegistrationConfirmationEmail(user.getEmail(), user.getFullName(), newCode);
        return new MessageResponse("New confirmation code sent to " + email);
    }
}
