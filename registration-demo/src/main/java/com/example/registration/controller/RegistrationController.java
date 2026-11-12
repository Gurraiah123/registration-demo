package com.example.registration.controller;

import com.example.registration.model.RegistrationForm;
import com.example.registration.model.User;
import com.example.registration.repository.UserRepository;
import jakarta.validation.Valid;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.validation.BindingResult;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import java.util.List;

@Controller
public class RegistrationController {

    private static final List<String> COUNTRIES =
            List.of("India", "United States", "United Kingdom", "Canada", "Australia", "Germany", "Singapore");

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;

    public RegistrationController(UserRepository userRepository, PasswordEncoder passwordEncoder) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
    }

    @ModelAttribute("countries")
    public List<String> countries() {
        return COUNTRIES;
    }

    @GetMapping("/")
    public String home() {
        return "redirect:/register";
    }

    @GetMapping("/register")
    public String showForm(Model model) {
        model.addAttribute("form", new RegistrationForm());
        return "register";
    }

    @PostMapping("/register")
    public String submit(@Valid @ModelAttribute("form") RegistrationForm form,
                         BindingResult result,
                         RedirectAttributes redirect) {

        if (form.getPassword() != null && !form.getPassword().equals(form.getConfirmPassword())) {
            result.rejectValue("confirmPassword", "mismatch", "Passwords do not match");
        }
        if (form.getEmail() != null && userRepository.existsByEmail(form.getEmail().trim().toLowerCase())) {
            result.rejectValue("email", "duplicate", "This email is already registered");
        }
        if (result.hasErrors()) {
            return "register";
        }

        User user = new User();
        user.setFullName(form.getFullName().trim());
        user.setEmail(form.getEmail().trim().toLowerCase());
        user.setPhone(form.getPhone());
        user.setDateOfBirth(form.getDateOfBirth());
        user.setGender(form.getGender());
        user.setCountry(form.getCountry());
        user.setPasswordHash(passwordEncoder.encode(form.getPassword()));
        userRepository.save(user);

        redirect.addFlashAttribute("name", user.getFullName());
        return "redirect:/success";
    }

    @GetMapping("/success")
    public String success() {
        return "success";
    }

    @GetMapping("/users")
    public String users(Model model) {
        model.addAttribute("users", userRepository.findAll());
        return "users";
    }
}
