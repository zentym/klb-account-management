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

# Now build main-app
WORKDIR /app/main-app

# Copy file pom.xml và các dependency trước (để tận dụng Docker layer caching)
COPY main-app/pom.xml .

# Download dependencies (sẽ được cache nếu pom.xml không thay đổi)
RUN mvn dependency:go-offline -B

# Copy source code
COPY main-app/src src

# Build ứng dụng
RUN mvn clean package -DskipTests

# Runtime stage
FROM openjdk:17-jdk-slim
WORKDIR /app
COPY --from=build /app/main-app/target/klb-account-management-0.0.1-SNAPSHOT.jar app.jar

# Expose port 8080 (port của main service)
EXPOSE 8080

# Chạy ứng dụng
CMD ["java", "-jar", "app.jar"]
