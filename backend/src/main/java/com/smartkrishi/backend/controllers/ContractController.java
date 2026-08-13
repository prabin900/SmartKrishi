package com.smartkrishi.backend.controllers;

import com.smartkrishi.backend.config.UserDetailsImpl;
import com.smartkrishi.backend.dtos.ContractRequest;
import com.smartkrishi.backend.dtos.MilestoneRequest;
import com.smartkrishi.backend.models.CropContract;
import com.smartkrishi.backend.services.ContractService;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/contracts")
@Tag(name = "Contract Farming", description = "Endpoints for pre-planting crop requisitions, growth milestone reporting and tracking")
public class ContractController {

    @Autowired
    private ContractService contractService;

    @PostMapping("/business")
    @PreAuthorize("hasRole('BUSINESS')")
    public ResponseEntity<CropContract> requestContract(Authentication authentication, @Valid @RequestBody ContractRequest request) {
        String userId = ((UserDetailsImpl) authentication.getPrincipal()).getId();
        return ResponseEntity.ok(contractService.createContractRequest(userId, request));
    }

    @PostMapping("/{contractId}/accept")
    @PreAuthorize("hasRole('FARMER')")
    public ResponseEntity<CropContract> acceptContract(Authentication authentication, @PathVariable String contractId) {
        String userId = ((UserDetailsImpl) authentication.getPrincipal()).getId();
        return ResponseEntity.ok(contractService.acceptContract(userId, contractId));
    }

    @PostMapping("/{contractId}/milestones")
    @PreAuthorize("hasRole('FARMER')")
    public ResponseEntity<CropContract> addMilestone(
            Authentication authentication,
            @PathVariable String contractId,
            @Valid @RequestBody MilestoneRequest request) {
        String userId = ((UserDetailsImpl) authentication.getPrincipal()).getId();
        return ResponseEntity.ok(contractService.addProgressMilestone(userId, contractId, request));
    }

    @GetMapping("/business")
    @PreAuthorize("hasRole('BUSINESS')")
    public ResponseEntity<List<CropContract>> getBusinessContracts(Authentication authentication) {
        String userId = ((UserDetailsImpl) authentication.getPrincipal()).getId();
        return ResponseEntity.ok(contractService.getBusinessContracts(userId));
    }

    @GetMapping("/farmer")
    @PreAuthorize("hasRole('FARMER')")
    public ResponseEntity<List<CropContract>> getFarmerContracts(Authentication authentication) {
        String userId = ((UserDetailsImpl) authentication.getPrincipal()).getId();
        return ResponseEntity.ok(contractService.getFarmerContracts(userId));
    }

    @GetMapping("/available")
    public ResponseEntity<List<CropContract>> getAvailableContracts() {
        return ResponseEntity.ok(contractService.getAvailableContracts());
    }
}
