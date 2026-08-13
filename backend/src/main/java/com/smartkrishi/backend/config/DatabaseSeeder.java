package com.smartkrishi.backend.config;

import com.smartkrishi.backend.dtos.RegisterRequest;
import com.smartkrishi.backend.models.Category;
import com.smartkrishi.backend.models.Product;
import com.smartkrishi.backend.models.Role;
import com.smartkrishi.backend.models.User;
import com.smartkrishi.backend.repositories.CategoryRepository;
import com.smartkrishi.backend.repositories.ProductRepository;
import com.smartkrishi.backend.repositories.UserRepository;
import com.smartkrishi.backend.services.AuthService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;

import java.time.Instant;
import java.util.List;

@Component
public class DatabaseSeeder implements CommandLineRunner {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private AuthService authService;

    @Autowired
    private CategoryRepository categoryRepository;

    @Autowired
    private ProductRepository productRepository;

    @Autowired
    private com.smartkrishi.backend.repositories.FarmerProfileRepository farmerProfileRepository;

    @Override
    public void run(String... args) throws Exception {
        // 0. Deduplicate users before seeding
        List<String> emails = userRepository.findAll().stream().map(User::getEmail).distinct().toList();
        for (String email : emails) {
            List<User> users = userRepository.findAllByEmail(email);
            if (users.size() > 1) {
                for (int i = 1; i < users.size(); i++) {
                    userRepository.delete(users.get(i));
                }
                System.out.println("Removed " + (users.size() - 1) + " duplicate users for email: " + email);
            }
        }

        // 1. Seed Roles/Users
        seedUser("admin@smartkrishi.com.np", "ADMIN", "Super Admin", "01-4443322");
        seedUser("farmer@smartkrishi.com.np", "FARMER", "Ram Prasad Shrestha", "9841002233");
        seedUser("business@smartkrishi.com.np", "BUSINESS", "Kathmandu Marriott Hotel", "01-5970050");
        seedUser("delivery@smartkrishi.com.np", "DELIVERY_PARTNER", "Suman Thapa", "9803124567");
        seedUser("customer@smartkrishi.com.np", "CUSTOMER", "Hari Bahadur", "9841999888");

        // 2. Seed default categories if empty
        if (categoryRepository.count() == 0) {
            categoryRepository.save(new Category(null, "Vegetables", "Fresh organic vegetables directly from farm greenhouses.", "https://images.unsplash.com/photo-1566385278603-605b5cfd6582?auto=format&fit=crop&q=80&w=400"));
            categoryRepository.save(new Category(null, "Fruits", "Sweet mountain apples, mangoes, and citrus fruits.", "https://images.unsplash.com/photo-1610832958506-ee56336191d1?auto=format&fit=crop&q=80&w=400"));
            categoryRepository.save(new Category(null, "Grains", "High grade rice, lentils, and organic wheat flour.", "https://images.unsplash.com/photo-1574323347407-f5e1ad6d020b?auto=format&fit=crop&q=80&w=400"));
            System.out.println("Default marketplace categories seeded successfully!");
        }

        // 3. Seed default product if empty and farmer profile is created
        if (productRepository.count() == 0) {
            List<User> farmers = userRepository.findAllByEmail("farmer@smartkrishi.com.np");
            User farmer = farmers.isEmpty() ? null : farmers.get(0);
            Category veg = categoryRepository.findByName("Vegetables").orElse(null);
            Category fruit = categoryRepository.findByName("Fruits").orElse(null);
            
            if (farmer != null) {
                com.smartkrishi.backend.models.FarmerProfile profile = farmerProfileRepository.findByUserId(farmer.getId()).orElse(null);
                String profileId = (profile != null) ? profile.getId() : "farm_1";

                Product product1 = Product.builder()
                        .name("Organic Vine Tomatoes")
                        .description("Perfectly ripe vine tomatoes grown using drip irrigation and organic fertilizers in Lalitpur.")
                        .price(90.0)
                        .unit("kg")
                        .imageUrls(List.of("https://images.unsplash.com/photo-1595855759920-86582396756a?auto=format&fit=crop&q=80&w=400"))
                        .categoryId(veg != null ? veg.getId() : null)
                        .availableQuantity(250.0)
                        .farmerProfileId(profileId)
                        .createdAt(Instant.now())
                        .updatedAt(Instant.now())
                        .build();
                productRepository.save(product1);

                Product product2 = Product.builder()
                        .name("Highland Apples")
                        .description("Sweet and crunchy apples freshly plucked from the high hills of Mustang.")
                        .price(220.0)
                        .unit("kg")
                        .imageUrls(List.of("https://images.unsplash.com/photo-1619546813926-a78fa6372cd2?auto=format&fit=crop&q=80&w=400"))
                        .categoryId(fruit != null ? fruit.getId() : null)
                        .availableQuantity(120.0)
                        .farmerProfileId(profileId)
                        .createdAt(Instant.now())
                        .updatedAt(Instant.now())
                        .build();
                productRepository.save(product2);
                System.out.println("Default marketplace crops seeded successfully!");
            }
        }
    }

    private void seedUser(String email, String role, String fullName, String phone) {
        if (!userRepository.existsByEmail(email)) {
            RegisterRequest req = new RegisterRequest(
                    email,
                    "password123",
                    fullName,
                    phone,
                    role,
                    "Shrestha Organic Farm",
                    "Pioneering organic vegetable farming in Lalitpur.",
                    "Lalitpur, Nepal",
                    27.6710,
                    85.3120,
                    "Kathmandu Marriott Hotel",
                    "PAN-60601243",
                    "HOTEL",
                    "MOTORCYCLE",
                    "Ba 3 Pa 1234",
                    "LIC-1010456"
            );
            try {
                authService.registerUser(req);
                List<User> seededUsers = userRepository.findAllByEmail(email);
                if (!seededUsers.isEmpty()) {
                    User u = seededUsers.get(0);
                    u.setEmailVerified(true);
                    userRepository.save(u);
                }
                System.out.println("Seeded default account: " + email + " with role: " + role);
            } catch (Exception e) {
                System.err.println("Failed to seed account " + email + ": " + e.getMessage());
            }
        }
    }
}
