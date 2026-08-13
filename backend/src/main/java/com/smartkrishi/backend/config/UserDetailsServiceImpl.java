package com.smartkrishi.backend.config;

import com.smartkrishi.backend.models.User;
import com.smartkrishi.backend.repositories.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
public class UserDetailsServiceImpl implements UserDetailsService {

    @Autowired
    private UserRepository userRepository;

    @Override
    @Transactional
    public UserDetails loadUserByUsername(String email) throws UsernameNotFoundException {
        List<User> users = userRepository.findAllByEmail(email);
        if (users.isEmpty()) {
            throw new UsernameNotFoundException("User not found with email: " + email);
        }
        User user = users.get(0);

        return UserDetailsImpl.build(user);
    }
}
