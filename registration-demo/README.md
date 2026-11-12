# Registration Demo (Java / Spring Boot)

A sample registration form application.

**Stack:** Java 17+, Spring Boot 3.3, Thymeleaf, Bean Validation, Spring Data JPA, H2 (in-memory), BCrypt.

## Run

```bash
mvn spring-boot:run
```

Then open http://localhost:8080 (redirects to the form).

| URL | Purpose |
|---|---|
| `/register` | Registration form |
| `/users` | List of registered users |
| `/h2-console` | Database console (JDBC URL `jdbc:h2:mem:registrationdb`, user `sa`, empty password) |

## Test / package

```bash
mvn test
mvn package && java -jar target/registration-demo-1.0.0.jar
```

## Features
- Fields: name, email, phone, date of birth, gender, country, password, confirm password, terms checkbox
- Server-side validation with inline error messages
- Duplicate-email check and password-match check
- Passwords stored as BCrypt hashes
- Data is in memory and resets on restart (switch `application.properties` to a file/MySQL URL to persist)

## Structure
```
src/main/java/com/example/registration
  RegistrationApplication.java
  controller/RegistrationController.java
  model/RegistrationForm.java   (form + validation rules)
  model/User.java               (JPA entity)
  repository/UserRepository.java
src/main/resources
  application.properties
  templates/ register.html, success.html, users.html
```
