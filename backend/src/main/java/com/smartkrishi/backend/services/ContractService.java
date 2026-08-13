package com.smartkrishi.backend.services;

import com.smartkrishi.backend.dtos.ContractRequest;
import com.smartkrishi.backend.dtos.MilestoneRequest;
import com.smartkrishi.backend.models.*;
import com.smartkrishi.backend.repositories.BusinessProfileRepository;
import com.smartkrishi.backend.repositories.CropContractRepository;
import com.smartkrishi.backend.repositories.FarmerProfileRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;

@Service
public class ContractService {

    @Autowired
    private CropContractRepository contractRepository;

    @Autowired
    private BusinessProfileRepository businessProfileRepository;

    @Autowired
    private FarmerProfileRepository farmerProfileRepository;

    public CropContract createContractRequest(String businessUserId, ContractRequest request) {
        BusinessProfile business = businessProfileRepository.findByUserId(businessUserId)
                .orElseThrow(() -> new RuntimeException("Business Profile not found"));

        CropContract contract = CropContract.builder()
                .businessProfileId(business.getId())
                .farmerProfileId(request.farmerProfileId())
                .cropName(request.cropName())
                .targetQuantity(request.targetQuantity())
                .unit(request.unit())
                .harvestMonth(request.harvestMonth())
                .expectedPrice(request.expectedPrice())
                .accepted(false)
                .status("REQUESTED")
                .organicOnly(request.organicOnly() != null ? request.organicOnly() : true)
                .aGradeOnly(request.aGradeOnly() != null ? request.aGradeOnly() : true)
                .directPickupRequired(request.directPickupRequired() != null ? request.directPickupRequired() : false)
                .qualityStandards(request.qualityStandards() != null ? request.qualityStandards() : new ArrayList<>())
                .progressMilestones(new ArrayList<>())
                .createdAt(Instant.now())
                .updatedAt(Instant.now())
                .build();
        return contractRepository.save(contract);
    }

    @Transactional
    public CropContract acceptContract(String farmerUserId, String contractId) {
        FarmerProfile farmer = farmerProfileRepository.findByUserId(farmerUserId)
                .orElseThrow(() -> new RuntimeException("Farmer Profile not found"));

        CropContract contract = contractRepository.findById(contractId)
                .orElseThrow(() -> new RuntimeException("Contract request not found"));

        if (contract.isAccepted()) {
            throw new RuntimeException("Contract is already accepted by another farmer");
        }

        contract.setFarmerProfileId(farmer.getId());
        contract.setAccepted(true);
        contract.setStatus("ACCEPTED");
        contract.setUpdatedAt(Instant.now());
        return contractRepository.save(contract);
    }

    @Transactional
    public CropContract addProgressMilestone(String farmerUserId, String contractId, MilestoneRequest request) {
        FarmerProfile farmer = farmerProfileRepository.findByUserId(farmerUserId)
                .orElseThrow(() -> new RuntimeException("Farmer Profile not found"));

        CropContract contract = contractRepository.findById(contractId)
                .orElseThrow(() -> new RuntimeException("Contract not found"));

        if (!farmer.getId().equals(contract.getFarmerProfileId())) {
            throw new RuntimeException("Unauthorized: You are not the assigned farmer for this contract");
        }

        CropContract.Milestone milestone = new CropContract.Milestone(
                request.description(),
                request.growthPercentage(),
                request.imageUrl(),
                Instant.now()
        );
        contract.getProgressMilestones().add(milestone);
        contract.setStatus(request.growthPercentage() >= 100.0 ? "HARVESTED" : "GROWING");
        contract.setUpdatedAt(Instant.now());
        
        return contractRepository.save(contract);
    }

    public List<CropContract> getBusinessContracts(String businessUserId) {
        BusinessProfile business = businessProfileRepository.findByUserId(businessUserId)
                .orElseThrow(() -> new RuntimeException("Business Profile not found"));
        return contractRepository.findByBusinessProfileId(business.getId());
    }

    public List<CropContract> getFarmerContracts(String farmerUserId) {
        FarmerProfile farmer = farmerProfileRepository.findByUserId(farmerUserId)
                .orElseThrow(() -> new RuntimeException("Farmer Profile not found"));
        return contractRepository.findByFarmerProfileId(farmer.getId());
    }

    public List<CropContract> getAvailableContracts() {
        return contractRepository.findByAccepted(false).stream()
                .filter(c -> c.getFarmerProfileId() == null)
                .toList();
    }
}
