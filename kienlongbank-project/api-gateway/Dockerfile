# Build stage
FROM maven:3.9.4-eclipse-temurin-17 AS build

# Thiết lập thư mục làm việc
WORKDIR /app

# Copy file pom.xml và các dependency trước (để tận dụng Docker layer caching)
COPY pom.xml .

# Download dependencies (sẽ được cache nếu pom.xml không thay đổi)
RUN mvn dependency:go-offline -B

# Copy source code
COPY src src

# Build ứng dụng
RUN mvn clean package -DskipTests

# Runtime stage
FROM openjdk:17-jdk-slim
WORKDIR /app
COPY --from=build /app/target/api-gateway-0.0.1-SNAPSHOT.jar app.jar

# Expose port 8080 (port của api-gateway)
EXPOSE 8080

# Chạy ứng dụng
CMD ["java", "-jar", "app.jar"]



