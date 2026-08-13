package com.smartkrishi.backend;

import com.smartkrishi.backend.dtos.RegisterRequest;
import com.smartkrishi.backend.models.Role;
import com.smartkrishi.backend.models.User;
import com.smartkrishi.backend.repositories.UserRepository;
import com.smartkrishi.backend.repositories.WishlistRepository;
import com.smartkrishi.backend.repositories.FavoriteRepository;
import com.smartkrishi.backend.services.AuthService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;
import org.springframework.security.crypto.password.PasswordEncoder;

import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;

class AuthServiceTest {

    @Mock
    private UserRepository userRepository;

    @Mock
    private WishlistRepository wishlistRepository;

    @Mock
    private FavoriteRepository favoriteRepository;

    @Mock
    private PasswordEncoder passwordEncoder;

    @InjectMocks
    private AuthService authService;

    @BeforeEach
    void setUp() {
        MockitoAnnotations.openMocks(this);
    }

    @Test
    void testRegisterUser() {
        RegisterRequest request = new RegisterRequest(
                "customer@smartkrishi.com.np",
                "password123",
                "Hari Bahadur",
                "9841999888",
                "CUSTOMER",
                null, null, null, 0.0, 0.0,
                null, null, null,
                null, null, null
        );

        when(userRepository.existsByEmail(request.email())).thenReturn(false);
        when(passwordEncoder.encode(request.password())).thenReturn("encodedPassword");
        
        User user = User.builder()
                .id("u_1")
                .email(request.email())
                .role(Role.CUSTOMER)
                .build();
        when(userRepository.save(any(User.class))).thenReturn(user);

        var response = authService.registerUser(request);
        assertNotNull(response);
    }
}
