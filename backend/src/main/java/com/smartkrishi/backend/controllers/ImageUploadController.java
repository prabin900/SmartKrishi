package com.smartkrishi.backend.controllers;

import com.smartkrishi.backend.services.CloudinaryService;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api")
@Tag(name = "Image Upload", description = "Endpoints for uploading images to Cloudinary storage")
public class ImageUploadController {

    @Autowired
    private CloudinaryService cloudinaryService;

    @PostMapping(value = "/public/upload", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<Map<String, String>> uploadImage(@RequestParam("file") MultipartFile file) {
        if (file.isEmpty()) {
            throw new RuntimeException("Cannot upload an empty file");
        }
        String url = cloudinaryService.uploadFile(file);
        Map<String, String> response = new HashMap<>();
        response.put("url", url);
        return ResponseEntity.ok(response);
    }
}
