package com.example.registration;

import com.example.registration.repository.UserRepository;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.web.servlet.MockMvc;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotEquals;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
class RegistrationControllerTest {

    @Autowired MockMvc mvc;
    @Autowired UserRepository repo;

    @Test
    void formPageLoads() throws Exception {
        mvc.perform(get("/register")).andExpect(status().isOk()).andExpect(view().name("register"));
    }

    @Test
    void invalidInputShowsErrorsAndSavesNothing() throws Exception {
        long before = repo.count();
        mvc.perform(post("/register").param("fullName", "").param("email", "bad"))
           .andExpect(status().isOk())
           .andExpect(view().name("register"))
           .andExpect(model().attributeHasFieldErrors("form", "fullName", "email", "phone", "password", "acceptTerms"));
        assertEquals(before, repo.count());
    }

    @Test
    void validRegistrationSavesUserWithHashedPassword() throws Exception {
        mvc.perform(post("/register")
                .param("fullName", "Test User")
                .param("email", "Test@Example.com")
                .param("phone", "9876543210")
                .param("dateOfBirth", "1995-05-20")
                .param("gender", "Male")
                .param("country", "India")
                .param("password", "Secret123")
                .param("confirmPassword", "Secret123")
                .param("acceptTerms", "true"))
           .andExpect(status().is3xxRedirection())
           .andExpect(redirectedUrl("/success"));

        var user = repo.findAll().stream().filter(u -> u.getEmail().equals("test@example.com")).findFirst().orElseThrow();
        assertNotEquals("Secret123", user.getPasswordHash());
    }

    @Test
    void passwordMismatchIsRejected() throws Exception {
        mvc.perform(post("/register")
                .param("fullName", "Mismatch User")
                .param("email", "mismatch@example.com")
                .param("phone", "9876543210")
                .param("dateOfBirth", "1995-05-20")
                .param("gender", "Female")
                .param("country", "India")
                .param("password", "Secret123")
                .param("confirmPassword", "Different1")
                .param("acceptTerms", "true"))
           .andExpect(status().isOk())
           .andExpect(model().attributeHasFieldErrors("form", "confirmPassword"));
    }
}
