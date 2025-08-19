# Build stage
FROM maven:3.9.4-eclipse-temurin-17 AS build

# Thiết lập thư mục làm việc
WORKDIR /app

# First, build and install common-api dependency
# Copy common-api module
COPY common-api/pom.xml ./common-api/pom.xml
COPY common-api/src ./common-api/src

# Build and install common-api to local repository
WORKDIR /app/common-api
RUN mvn clean install -DskipTests

# Now build customer-service
WORKDIR /app/customer-service

# Copy customer-service pom.xml và các dependency trước (để tận dụng Docker layer caching)
COPY customer-service/pom.xml .

# Download dependencies (bây giờ có thể tìm thấy common-api)
RUN mvn dependency:go-offline -B

# Copy source code
COPY customer-service/src src

# Build ứng dụng
RUN mvn clean package -DskipTests

# Runtime stage
FROM openjdk:17-jdk-slim
WORKDIR /app
COPY --from=build /app/customer-service/target/customer-service-0.0.1-SNAPSHOT.jar app.jar

# Expose port 8082 (port của customer-service)
EXPOSE 8082

# Chạy ứng dụng
CMD ["java", "-jar", "app.jar"]
