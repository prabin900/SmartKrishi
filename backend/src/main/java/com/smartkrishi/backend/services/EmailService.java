package com.smartkrishi.backend.services;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.stereotype.Service;

import jakarta.mail.internet.MimeMessage;

@Service
public class EmailService {

    private static final Logger logger = LoggerFactory.getLogger(EmailService.class);

    @Autowired(required = false)
    private JavaMailSender mailSender;

    public void sendRegistrationConfirmationEmail(String toEmail, String fullName, String verificationCode) {
        String subject = "SmartKrishi Nepal - Confirm Your Registration";
        String htmlContent = String.format("""
            <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #e0e0e0; border-radius: 10px;">
                <div style="background-color: #0D631B; padding: 15px; text-align: center; border-radius: 8px 8px 0 0;">
                    <h1 style="color: #ffffff; margin: 0; font-size: 24px;">SmartKrishi Nepal 🌱</h1>
                </div>
                <div style="padding: 20px; color: #333333;">
                    <h2>Namaste, %s!</h2>
                    <p>Thank you for registering with SmartKrishi. Please confirm your registration by entering the 6-digit confirmation code below:</p>
                    <div style="background-color: #f4fbf4; border: 1px dashed #0D631B; padding: 15px; text-align: center; border-radius: 8px; margin: 20px 0;">
                        <span style="font-size: 32px; font-weight: bold; letter-spacing: 6px; color: #0D631B;">%s</span>
                    </div>
                    <p>Enter this code in your SmartKrishi app to verify your email and activate your account.</p>
                    <p style="color: #777777; font-size: 12px; margin-top: 30px;">If you did not initiate this request, please ignore this email.</p>
                </div>
                <div style="background-color: #f9f9f9; padding: 10px; text-align: center; border-radius: 0 0 8px 8px; font-size: 11px; color: #888888;">
                    &copy; 2026 SmartKrishi Nepal. Connecting Farmers Directly to Homes & Businesses.
                </div>
            </div>
            """, fullName != null ? fullName : "Farmer/Customer", verificationCode);

        logger.info("=================================================");
        logger.info("REGISTRATION CONFIRMATION EMAIL SENT TO: {}", toEmail);
        logger.info("CONFIRMATION VERIFICATION CODE: {}", verificationCode);
        logger.info("=================================================");

        if (mailSender != null) {
            try {
                MimeMessage message = mailSender.createMimeMessage();
                MimeMessageHelper helper = new MimeMessageHelper(message, true, "UTF-8");
                helper.setTo(toEmail);
                helper.setSubject(subject);
                helper.setText(htmlContent, true);
                helper.setFrom("prabinsingh9844@gmail.com", "SmartKrishi Nepal");
                mailSender.send(message);
                logger.info("Successfully dispatched email via JavaMailSender to {}", toEmail);
            } catch (Exception e) {
                logger.warn("Could not dispatch email via SMTP (using fallback log): {}", e.getMessage());
            }
        }
    }

    public void sendPasswordResetEmail(String toEmail, String fullName, String resetCode) {
        String subject = "SmartKrishi Nepal - Reset Your Password";
        String htmlContent = String.format("""
            <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #e0e0e0; border-radius: 10px;">
                <div style="background-color: #D32F2F; padding: 15px; text-align: center; border-radius: 8px 8px 0 0;">
                    <h1 style="color: #ffffff; margin: 0; font-size: 24px;">SmartKrishi Password Reset 🔒</h1>
                </div>
                <div style="padding: 20px; color: #333333;">
                    <h2>Namaste, %s!</h2>
                    <p>We received a request to reset your password for your SmartKrishi account. Use the 6-digit password reset PIN below:</p>
                    <div style="background-color: #FFEBEE; border: 1px dashed #D32F2F; padding: 15px; text-align: center; border-radius: 8px; margin: 20px 0;">
                        <span style="font-size: 32px; font-weight: bold; letter-spacing: 6px; color: #D32F2F;">%s</span>
                    </div>
                    <p>Enter this PIN in your app along with your new password to reset your account credentials.</p>
                    <p style="color: #777777; font-size: 12px; margin-top: 30px;">If you did not request a password reset, please secure your account immediately or ignore this email.</p>
                </div>
                <div style="background-color: #f9f9f9; padding: 10px; text-align: center; border-radius: 0 0 8px 8px; font-size: 11px; color: #888888;">
                    &copy; 2026 SmartKrishi Nepal. Connecting Farmers Directly to Homes & Businesses.
                </div>
            </div>
            """, fullName != null ? fullName : "SmartKrishi User", resetCode);

        logger.info("=================================================");
        logger.info("PASSWORD RESET EMAIL SENT TO: {}", toEmail);
        logger.info("PASSWORD RESET CODE: {}", resetCode);
        logger.info("=================================================");

        if (mailSender != null) {
            try {
                MimeMessage message = mailSender.createMimeMessage();
                MimeMessageHelper helper = new MimeMessageHelper(message, true, "UTF-8");
                helper.setTo(toEmail);
                helper.setSubject(subject);
                helper.setText(htmlContent, true);
                helper.setFrom("prabinsingh9844@gmail.com", "SmartKrishi Nepal");
                mailSender.send(message);
                logger.info("Successfully dispatched password reset email via JavaMailSender to {}", toEmail);
            } catch (Exception e) {
                logger.warn("Could not dispatch password reset email via SMTP (using fallback log): {}", e.getMessage());
            }
        }
    }
}
