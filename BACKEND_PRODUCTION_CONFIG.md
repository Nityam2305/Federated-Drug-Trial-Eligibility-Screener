================================================================================
BACKEND PRODUCTION HARDENING FOR CLOUDFLARE TUNNEL
================================================================================

This guide shows how to harden your FastAPI backend for production exposure
via Cloudflare Tunnel.

================================================================================
PART 1: PRODUCTION ENVIRONMENT VARIABLES
================================================================================

Create or update .env file:

────────────────────────────────────────────────────────────────────────────
# .env (NEVER commit this file!)

# Server Configuration
PORT=8002
HOST=0.0.0.0
DEBUG=false

# Database
MONGO_URI=mongodb+srv://user:password@cluster.mongodb.net/
MONGO_DB_NAME=federated_screener

# CORS - IMPORTANT: Restrict to your frontend URL only
FRONTEND_URL=https://frontend.YOUR_DOMAIN.com

# Blockchain
BLOCKCHAIN_LOCAL=false
PRIVATE_KEY=your_ethereum_private_key_here
CONTRACT_ADDRESS=0x...
INFURA_PROJECT_ID=your_infura_id_here

# Rate Limiting
RATE_LIMIT_REQUESTS=100
RATE_LIMIT_PERIOD=60

# Security
SECRET_KEY=your_secret_key_for_jwt_tokens_change_this_value

────────────────────────────────────────────────────────────────────────────

IMPORTANT:
  ✓ Never commit .env to Git
  ✓ Use strong SECRET_KEY (e.g., python -c "import secrets; print(secrets.token_urlsafe(32))")
  ✓ Change default values for production
  ✓ Use separate credentials for production vs development

================================================================================
PART 2: UPDATED api/main.py - PRODUCTION VERSION
================================================================================

Key changes needed:

1. Import os for environment variables
2. Bind to 0.0.0.0 (all interfaces)
3. Use PORT from environment
4. Disable debug mode
5. Add CORS middleware with restricted origins
6. Add rate limiting middleware
7. Add /health endpoint (already exists, ensure it's public)
8. Remove hardcoded credentials
9. Lazy-load TensorFlow model

────────────────────────────────────────────────────────────────────────────
# At top of api/main.py - add imports:

import os
from dotenv import load_dotenv
from slowapi import Limiter
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded

# Load environment variables
load_dotenv()

# Production hardening
HOST = "0.0.0.0"
PORT = int(os.getenv("PORT", 8002))
DEBUG = os.getenv("DEBUG", "false").lower() == "true"
FRONTEND_URL = os.getenv("FRONTEND_URL", "http://localhost:3000")

# Initialize rate limiter
limiter = Limiter(key_func=get_remote_address)

────────────────────────────────────────────────────────────────────────────

2. Update FastAPI app initialization:

────────────────────────────────────────────────────────────────────────────
# Create app
app = FastAPI(
    title="Federated Drug Trial Eligibility Screener",
    description="API for federated learning drug trial eligibility screening",
    version="1.0.0",
    debug=DEBUG,  # Disable debug in production
)

# Add rate limiting
app.state.limiter = limiter

# Add CORS middleware with restricted origins
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        FRONTEND_URL,
        "http://localhost:3000",  # Local development
        "http://localhost:3001",  # Vite dev server alternative port
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
    max_age=600,  # Cache preflight requests for 10 min
)

# Add security headers middleware
@app.middleware("http")
async def add_security_headers(request, call_next):
    response = await call_next(request)
    response.headers["X-Content-Type-Options"] = "nosniff"
    response.headers["X-Frame-Options"] = "DENY"
    response.headers["X-XSS-Protection"] = "1; mode=block"
    response.headers["Strict-Transport-Security"] = "max-age=31536000; includeSubDomains"
    return response

────────────────────────────────────────────────────────────────────────────

3. Add rate limiting to key endpoints:

────────────────────────────────────────────────────────────────────────────
# Example: Rate limit login endpoint
@app.post("/hospital_login")
@limiter.limit("5/minute")  # Max 5 attempts per minute
async def hospital_login(request: Request, credentials: HospitalLoginRequest):
    # Your existing login code
    pass

# Rate limit predict endpoint
@app.post("/predict")
@limiter.limit("30/minute")  # Max 30 predictions per minute
async def predict(request: Request, data: PredictionRequest):
    # Your existing prediction code
    pass

────────────────────────────────────────────────────────────────────────────

4. Ensure /health endpoint exists and is unrestricted:

────────────────────────────────────────────────────────────────────────────
@app.get("/health")
async def health_check():
    """Health check endpoint - used by Cloudflare and monitoring."""
    try:
        # Check MongoDB
        db_client = db.get_sync_client()
        db_client.admin.command("ping")
        mongodb_connected = True
    except:
        mongodb_connected = False
    
    return {
        "status": "healthy" if mongodb_connected else "degraded",
        "mongodb_connected": mongodb_connected,
        "blockchain_connected": False,  # Update if you use blockchain
        "training_active": False,  # Update if training is running
    }

────────────────────────────────────────────────────────────────────────────

5. Remove hardcoded credentials:

✓ Replace all hardcoded URLs, keys, passwords with environment variables
✓ Use os.getenv("VARIABLE_NAME") for everything secret
✓ Remove print statements with sensitive info
✓ Use logging module instead of print()

================================================================================
PART 3: TensorFlow MODEL LAZY LOADING
================================================================================

Problem: TensorFlow loads at startup, slowing down cold starts
Solution: Load model only on first /predict call

────────────────────────────────────────────────────────────────────────────
# Add to api/main.py

# Lazy-load TensorFlow model
_model = None
_model_lock = threading.Lock()

def get_model():
    """Lazy load TensorFlow model on first use."""
    global _model
    
    if _model is None:
        with _model_lock:  # Prevent race conditions
            if _model is None:
                try:
                    print("[MODEL] Loading TensorFlow model...")
                    import tensorflow as tf
                    _model = tf.keras.models.load_model("path/to/your/model.h5")
                    print("[MODEL] ✅ Model loaded successfully")
                except Exception as e:
                    print(f"[MODEL] ❌ Failed to load model: {e}")
                    return None
    return _model

# Use in your endpoints:
@app.post("/predict")
@limiter.limit("30/minute")
async def predict(request: Request, data: PredictionRequest):
    model = get_model()
    if model is None:
        raise HTTPException(status_code=500, detail="Model not available")
    
    # Use model for predictions
    # ... your code ...

────────────────────────────────────────────────────────────────────────────

================================================================================
PART 4: LOGGING CONFIGURATION
================================================================================

Configure proper logging instead of print():

────────────────────────────────────────────────────────────────────────────
# Add to api/main.py

import logging

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('logs/api.log'),
        logging.StreamHandler()
    ]
)

logger = logging.getLogger(__name__)

# Use logging in your code instead of print():
logger.info("API started on port 8002")
logger.warning("MongoDB connection timeout")
logger.error(f"Prediction failed: {error}")

────────────────────────────────────────────────────────────────────────────

================================================================================
PART 5: ENVIRONMENT VARIABLES IN CLUSTER DEPLOYMENT
================================================================================

FOR CLOUDFLARE TUNNEL:
  - Create .env file in project root
  - Start FastAPI with: python start_production.py
  - FastAPI reads FRONTEND_URL from .env

FOR LATER (Azure/Render):
  - Set environment variables in web service settings
  - Don't use .env file (set in dashboard)
  - Same code, different configuration

================================================================================
PART 6: VALIDATION & SECURITY CHECKS
================================================================================

Before deploying:

────────────────────────────────────────────────────────────────────────────
# api/main.py startup validation

if not DEBUG:  # Production mode
    # Validate required environment variables
    required_vars = ["MONGO_URI", "MONGO_DB_NAME"]
    for var in required_vars:
        if not os.getenv(var):
            logger.error(f"Missing required environment variable: {var}")
            sys.exit(1)
    
    # Validate frontend URL
    if not FRONTEND_URL:
        logger.warning("FRONTEND_URL not set, using localhost for development")
    
    # Ensure secret key is strong
    if os.getenv("SECRET_KEY") == "your_secret_key_for_jwt_tokens_change_this_value":
        logger.error("⚠️  CRITICAL: Change SECRET_KEY in .env before production!")
        sys.exit(1)
    
    logger.info("✅ All production security checks passed")

────────────────────────────────────────────────────────────────────────────

================================================================================
PART 7: STARTUP RUNNER SCRIPT
================================================================================

Create file: start_production.py

────────────────────────────────────────────────────────────────────────────
#!/usr/bin/env python3
"""
Production startup script for FastAPI backend.
Runs after environment validation.
"""

import os
import sys
import uvicorn
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Get configuration from environment
HOST = os.getenv("HOST", "0.0.0.0")
PORT = int(os.getenv("PORT", 8002))
DEBUG = os.getenv("DEBUG", "false").lower() == "true"

if __name__ == "__main__":
    print(f"Starting FastAPI production server")
    print(f"  Host: {HOST}")
    print(f"  Port: {PORT}")
    print(f"  Debug: {DEBUG}")
    print()
    
    uvicorn.run(
        "api.main:app",
        host=HOST,
        port=PORT,
        debug=DEBUG,
        reload=DEBUG,  # Only reload in development
        log_level="info",
        access_log=True,
    )

────────────────────────────────────────────────────────────────────────────

Run with:
    .\.venv311\Scripts\python.exe start_production.py

Or with custom port:
    $env:PORT=8002; .\.venv311\Scripts\python.exe start_production.py

================================================================================
PART 8: ADDITIONAL SECURITY MEASURES
================================================================================

1. Rate Limiting (done above)
   - Prevent brute force attacks
   - Prevent DoS attacks

2. CORS (done above)
   - Restrict to your frontend domain only
   - Don't use allow_origins=["*"] in production

3. Security Headers (done above)
   - Prevent clickjacking
   - Prevent MIME sniffing
   - Enforce HTTPS

4. Input Validation
   - Use Pydantic models for request validation
   - Validate all user inputs
   - Never trust user input

5. Authentication
   - Use JWT tokens with short expiry
   - Store secrets in .env, not in code
   - Refresh tokens periodically

6. HTTPS / TLS
   - Cloudflare handles this automatically
   - Your local -> Cloudflare is encrypted
   - Cloudflare -> users is encrypted

Example - Pydantic validation:
    from pydantic import BaseModel, validator
    
    class PredictionRequest(BaseModel):
        patient_age: int
        medical_history: str
        
        @validator('patient_age')
        def age_must_be_valid(cls, v):
            if v < 0 or v > 150:
                raise ValueError('Age must be between 0 and 150')
            return v

================================================================================
PART 9: DEPLOYMENT CHECKLIST
================================================================================

Before exposing via Cloudflare Tunnel:

Environment Variables:
  [ ] .env file created with all required variables
  [ ] MONGO_URI is not committed to Git
  [ ] FRONTEND_URL is correct (your domain)
  [ ] SECRET_KEY is changed from default
  [ ] DEBUG is set to false

Code Changes:
  [ ] CORS middleware configured with FRONTEND_URL
  [ ] Rate limiting added to sensitive endpoints
  [ ] Security headers middleware added
  [ ] /health endpoint working
  [ ] No hardcoded credentials in code
  [ ] TensorFlow lazy-loading implemented

Startup:
  [ ] start_production.py works correctly
  [ ] START_PRODUCTION.bat tested
  [ ] Logs are being written to logs/ directory
  [ ] All services start without errors

Testing:
  [ ] curl http://localhost:8002/health returns 200
  [ ] curl http://localhost:8002/docs loads API docs
  [ ] Login endpoint works
  [ ] Prediction endpoint works
  [ ] Rate limiting triggers correctly

Cloudflare:
  [ ] Tunnel created and named
  [ ] DNS CNAME record created
  [ ] config.yml configured correctly
  [ ] Tunnel running and connected
  [ ] https://api.YOUR_DOMAIN.com/health accessible

================================================================================
SUMMARY
================================================================================

Your FastAPI backend is now:
  ✅ Production-ready
  ✅ Secured with rate limiting
  ✅ CORS restricted to your domain
  ✅ Lazy-loads models for fast startup
  ✅ Uses environment variables for secrets
  ✅ Accessible globally via Cloudflare Tunnel

Next steps:
  1. Update api/main.py with security middleware
  2. Create/update .env file
  3. Test locally: python start_production.py
  4. Set up Cloudflare Tunnel (see CLOUDFLARE_TUNNEL_SETUP.md)
  5. Test public access: https://api.YOUR_DOMAIN.com/health

================================================================================
