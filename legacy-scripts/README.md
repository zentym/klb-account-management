# Legacy Scripts & Documentation

This directory contains legacy testing scripts and documentation from the original project structure.

## 📁 Contents

### Testing Scripts
- `test-*.ps1` - PowerShell API testing scripts
- `test-*.sh` - Shell script alternatives
- `*.java` - Java test files

### Management Scripts  
- `start-all.*` - Scripts to start all services
- `stop-all.*` - Scripts to stop all services
- `start-databases.*` - Database-only startup scripts
- `check-system.ps1` - System health check

### Documentation
- `ADMIN_*.md` - Admin-related documentation
- `LOMBOK_*.md` - Lombok integration notes
- `MIGRATION_*.md` - Migration documentation
- `MANAGER_*.md` - Manager role documentation

### Test Files
- `test-frontend.html` - Frontend testing page
- `working-frontend.html` - Working frontend example

## � Migration Notes

**These scripts were designed for the legacy structure:**
```
klb-account-management/
├── klb-account-management/  # Old backend location
├── customer-service/        # Old customer service location  
└── klb-frontend/           # Frontend (still used)
```

**For new development, use:**
```
kienlongbank-project/
├── main-app/              # New backend location
├── customer-service/      # New customer service location
└── docker-compose.yml     # Orchestration
```

## ⚠️ Usage Warning

Some scripts may need path adjustments to work with the new structure. Use them as reference for creating new testing scripts for the `kienlongbank-project/` structure.

## 🔧 Adapting Scripts

To use these scripts with the new structure:

1. **Update paths**: Change references from `klb-account-management/` to `kienlongbank-project/main-app/`
2. **Update Docker commands**: Use `docker-compose` from `kienlongbank-project/` directory
3. **Update service URLs**: Services now run in Docker containers with container networking

## 📝 Recommended Approach

Instead of modifying these legacy scripts, consider:
1. Using the new Docker-based approach in `kienlongbank-project/`
2. Creating new testing scripts specific to the microservices architecture
3. Using Postman collections for API testing
