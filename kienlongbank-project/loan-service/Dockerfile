# Stage 1: Build the application
FROM maven:3.8.5-openjdk-17 AS build

# Thiết lập thư mục làm việc
WORKDIR /app

# First, build and install common-api dependency
# Copy common-api module
COPY common-api/pom.xml ./common-api/pom.xml
COPY common-api/src ./common-api/src

# Build and install common-api to local repository
WORKDIR /app/common-api
RUN mvn clean install -DskipTests

# Now build loan-service
WORKDIR /app/loan-service

# Copy loan-service pom.xml và các dependency trước
COPY loan-service/pom.xml .

# Download dependencies (bây giờ có thể tìm thấy common-api)
RUN mvn dependency:go-offline -B

# Copy source code
COPY loan-service/src src

# Build ứng dụng
RUN mvn clean package -DskipTests

# Stage 2: Create the runtime image
FROM eclipse-temurin:17-jre
WORKDIR /app
COPY --from=build /app/loan-service/target/loan-service-*.jar app.jar
ENTRYPOINT ["java", "-jar", "app.jar"]