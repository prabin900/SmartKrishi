package com.smartkrishi.backend.repositories;

import com.smartkrishi.backend.models.Order;
import com.smartkrishi.backend.models.OrderStatus;
import org.springframework.data.mongodb.repository.MongoRepository;
import java.util.List;

public interface OrderRepository extends MongoRepository<Order, String> {
    List<Order> findByCustomerId(String customerId);
    List<Order> findByFarmerProfileId(String farmerProfileId);
    List<Order> findByDeliveryPartnerId(String deliveryPartnerId);
    List<Order> findByStatus(OrderStatus status);
    List<Order> findByIsBulkOrder(boolean isBulkOrder);
}
