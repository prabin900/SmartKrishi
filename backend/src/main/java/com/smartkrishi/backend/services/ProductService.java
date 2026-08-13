package com.smartkrishi.backend.services;

import com.smartkrishi.backend.dtos.ProductRequest;
import com.smartkrishi.backend.models.*;
import com.smartkrishi.backend.repositories.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;

@Service
public class ProductService {

    @Autowired
    private ProductRepository productRepository;

    @Autowired
    private CategoryRepository categoryRepository;

    @Autowired
    private FarmerProfileRepository farmerProfileRepository;

    @Autowired
    private InventoryRepository inventoryRepository;

    @Autowired
    private UserRepository userRepository;

    @Transactional
    public Category createCategory(Category category) {
        if (categoryRepository.findByName(category.getName()).isPresent()) {
            throw new RuntimeException("Category already exists!");
        }
        return categoryRepository.save(category);
    }

    public List<Category> getAllCategories() {
        return categoryRepository.findAll();
    }

    @Transactional
    public Product uploadProduct(String userId, ProductRequest request) {
        FarmerProfile farmer = farmerProfileRepository.findByUserId(userId)
                .orElseThrow(() -> new RuntimeException("Farmer profile not found for user: " + userId));

        Product product = Product.builder()
                .name(request.name())
                .description(request.description())
                .categoryId(request.categoryId())
                .imageUrls(request.imageUrls() != null ? request.imageUrls() : new ArrayList<>())
                .price(request.price())
                .unit(request.unit())
                .availableQuantity(request.availableQuantity())
                .reservedQuantity(0.0)
                .soldQuantity(0.0)
                .harvestDate(request.harvestDate())
                .organic(request.organic())
                .city(request.city())
                .district(request.district())
                .farmerProfileId(farmer.getId())
                .pickupAvailable(request.pickupAvailable())
                .harvestOnDemand(request.harvestOnDemand())
                .farmVisitAvailable(request.farmVisitAvailable())
                .createdAt(Instant.now())
                .updatedAt(Instant.now())
                .build();

        Product saved = productRepository.save(product);

        // Log initial inventory entry
        inventoryRepository.save(Inventory.builder()
                .productId(saved.getId())
                .quantityChanged(saved.getAvailableQuantity())
                .changeType("ADDED")
                .remarks("Initial product harvest stock added")
                .timestamp(Instant.now())
                .build());

        return saved;
    }

    @Transactional
    public Product editProduct(String userId, String productId, ProductRequest request) {
        FarmerProfile farmer = farmerProfileRepository.findByUserId(userId)
                .orElseThrow(() -> new RuntimeException("Farmer profile not found"));

        Product product = productRepository.findById(productId)
                .orElseThrow(() -> new RuntimeException("Product not found"));

        if (!product.getFarmerProfileId().equals(farmer.getId())) {
            throw new RuntimeException("Unauthorized: You do not own this product!");
        }

        double oldQty = product.getAvailableQuantity();
        double newQty = request.availableQuantity();

        product.setName(request.name());
        product.setDescription(request.description());
        product.setCategoryId(request.categoryId());
        if (request.imageUrls() != null) {
            product.setImageUrls(request.imageUrls());
        }
        product.setPrice(request.price());
        product.setUnit(request.unit());
        product.setAvailableQuantity(newQty);
        product.setHarvestDate(request.harvestDate());
        product.setOrganic(request.organic());
        product.setCity(request.city());
        product.setDistrict(request.district());
        product.setPickupAvailable(request.pickupAvailable());
        product.setHarvestOnDemand(request.harvestOnDemand());
        product.setFarmVisitAvailable(request.farmVisitAvailable());
        product.setUpdatedAt(Instant.now());

        Product saved = productRepository.save(product);

        // Log inventory change if quantity is updated
        if (oldQty != newQty) {
            inventoryRepository.save(Inventory.builder()
                    .productId(saved.getId())
                    .quantityChanged(newQty - oldQty)
                    .changeType(newQty > oldQty ? "ADDED" : "ADJUSTED_DOWN")
                    .remarks("Manual quantity adjustment by farmer")
                    .timestamp(Instant.now())
                    .build());
        }

        return saved;
    }

    @Transactional
    public void deleteProduct(String userId, String productId) {
        FarmerProfile farmer = farmerProfileRepository.findByUserId(userId)
                .orElseThrow(() -> new RuntimeException("Farmer profile not found"));

        Product product = productRepository.findById(productId)
                .orElseThrow(() -> new RuntimeException("Product not found"));

        if (!product.getFarmerProfileId().equals(farmer.getId())) {
            throw new RuntimeException("Unauthorized: You do not own this product!");
        }

        productRepository.delete(product);

        inventoryRepository.save(Inventory.builder()
                .productId(productId)
                .quantityChanged(-product.getAvailableQuantity())
                .changeType("DELETED")
                .remarks("Product removed from marketplace")
                .timestamp(Instant.now())
                .build());
    }

    public List<Product> getProductsByFarmer(String farmerProfileId) {
        return productRepository.findByFarmerProfileId(farmerProfileId);
    }

    public List<Product> getProductsByCategory(String categoryId) {
        return productRepository.findByCategoryId(categoryId);
    }

    public List<Product> searchProducts(String query) {
        return productRepository.findByNameContainingIgnoreCase(query);
    }

    public List<Product> getProductsByCity(String city) {
        return productRepository.findByCityIgnoreCase(city);
    }

    public List<Product> getAllProducts() {
        return productRepository.findAll();
    }

    public Product getProductDetails(String id) {
        return productRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Product not found"));
    }

    public FarmerProfile getFarmerProfile(String userId) {
        return farmerProfileRepository.findByUserId(userId)
                .orElseGet(() -> {
                    User user = userRepository.findById(userId).orElse(null);
                    String fullName = user != null ? user.getFullName() : "Farmer";
                    String farmName = fullName + "'s Farm";
                    
                    FarmerProfile newProfile = FarmerProfile.builder()
                            .userId(userId)
                            .farmName(farmName)
                            .farmDescription("Organic Nepalese Farm")
                            .farmAddress("Nepal")
                            .latitude(27.7172)
                            .longitude(85.3240)
                            .galleryImageUrls(new ArrayList<>())
                            .rating(5.0)
                            .reviewCount(0)
                            .verified(false)
                            .build();
                    return farmerProfileRepository.save(newProfile);
                });
    }

    public FarmerProfile getFarmerProfileById(String id) {
        return farmerProfileRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Farmer profile not found for id: " + id));
    }

    public FarmerProfile updateFarmerProfileLocation(String userId, double latitude, double longitude) {
        FarmerProfile profile = getFarmerProfile(userId);
        profile.setLatitude(latitude);
        profile.setLongitude(longitude);
        return farmerProfileRepository.save(profile);
    }

    public List<FarmerProfile> getAllFarmerProfiles() {
        return farmerProfileRepository.findAll();
    }

    public FarmerProfile updateFarmerGallery(String userId, List<String> imageUrls) {
        FarmerProfile profile = getFarmerProfile(userId);
        profile.setGalleryImageUrls(imageUrls != null ? imageUrls : new ArrayList<>());
        return farmerProfileRepository.save(profile);
    }

    public FarmerProfile addFarmerGalleryImage(String userId, String imageUrl) {
        FarmerProfile profile = getFarmerProfile(userId);
        if (profile.getGalleryImageUrls() == null) {
            profile.setGalleryImageUrls(new ArrayList<>());
        }
        if (imageUrl != null && !imageUrl.trim().isEmpty() && !profile.getGalleryImageUrls().contains(imageUrl)) {
            profile.getGalleryImageUrls().add(imageUrl);
        }
        return farmerProfileRepository.save(profile);
    }

    public FarmerProfile removeFarmerGalleryImage(String userId, String imageUrl) {
        FarmerProfile profile = getFarmerProfile(userId);
        if (profile.getGalleryImageUrls() != null && imageUrl != null) {
            profile.getGalleryImageUrls().remove(imageUrl);
        }
        return farmerProfileRepository.save(profile);
    }
}
