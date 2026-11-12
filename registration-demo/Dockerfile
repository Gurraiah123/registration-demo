
FROM eclipse-temurin:17-jre

WORKDIR /app

COPY target/registration-demo-1.0.0.jar app.jar

EXPOSE 9090

ENTRYPOINT ["java", "-jar", "app.jar"]
