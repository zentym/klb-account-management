# API Gateway Configuration

## Overview
The React frontend has been configured to use the API Gateway as a single entry point for all backend services.

## Configuration Changes

### 1. Environment Variables
All API requests now route through the API Gateway:

```bash
# .env.local
REACT_APP_API_BASE_URL=http://localhost:8080
```

### 2. API Configuration
- **Base URL**: `http://localhost:8080` (API Gateway)
- **All service routes**: Now prefixed with `/api/` and routed through gateway

### 3. Service Routing
| Service | Old Direct Access | New Gateway Route |
|---------|------------------|-------------------|
| Customer Service | `localhost:8082/api/customers/...` | `localhost:8080/api/customers/...` |
| Account Management | `localhost:8080/api/accounts/...` | `localhost:8080/api/accounts/...` |
| Loan Service | `localhost:8083/api/loans/...` | `localhost:8080/api/loans/...` |
| Notification Service | `localhost:8084/api/notifications/...` | `localhost:8080/api/notifications/...` |

## How to Use

### Development Mode
```bash
cd klb-frontend
npm start
```

### Production Mode with Docker
```bash
cd kienlongbank-project
docker-compose up -d --build
```

## Benefits
1. **Single Entry Point**: All API requests go through one port (8080)
2. **Security**: JWT validation happens at the gateway level
3. **Load Balancing**: Gateway can distribute requests
4. **Monitoring**: Centralized logging and metrics
5. **CORS**: Simplified CORS configuration

## Environment Variables

### Local Development
```bash
REACT_APP_API_BASE_URL=http://localhost:8080
```

### Docker Production
```bash
REACT_APP_API_BASE_URL=http://klb-api-gateway:8080
```

### With External Load Balancer
```bash
REACT_APP_API_BASE_URL=https://your-domain.com
```

## Troubleshooting

### If you see connection errors:
1. Make sure API Gateway is running: `docker-compose up api-gateway`
2. Check if all backend services are running
3. Verify the gateway routing configuration
4. Check browser network tab for 502/503 errors

### For development:
1. Ensure `docker-compose up -d --build` completed successfully
2. All services should be accessible through `http://localhost:8080/api/...`
3. Frontend should be on `http://localhost:3000`
