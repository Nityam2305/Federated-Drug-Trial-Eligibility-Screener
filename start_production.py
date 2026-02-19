#!/usr/bin/env python3
"""
Production-ready startup script for Render deployment.
Uses uvicorn with production settings.
"""

import sys
import os
from pathlib import Path

# Add current directory to path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

# Check if requirements are installed
def check_requirements():
    """Verify critical dependencies are installed."""
    required_packages = [
        'fastapi',
        'uvicorn',
        'motor',
        'pymongo',
        'web3',
        'tensorflow',
    ]
    
    missing = []
    for package in required_packages:
        try:
            __import__(package)
        except ImportError:
            missing.append(package)
    
    if missing:
        print(f"ERROR: Missing required packages: {', '.join(missing)}")
        print("Please run: pip install -r requirements.txt")
        sys.exit(1)
    
    print("✓ All required packages are installed")

# Check requirements before starting
check_requirements()

# Import after requirements check
from api.main import app
import uvicorn

if __name__ == "__main__":
    # Get port from environment variable (Render provides this)
    port = int(os.getenv("PORT", 8002))
    
    # Production settings
    uvicorn.run(
        app,
        host="0.0.0.0",
        port=port,
        log_level="info",
        access_log=True,
        workers=1,  # Use 1 worker for Render free tier
        timeout_keep_alive=30,
        limit_concurrency=100,  # Limit concurrent connections for free tier
        limit_max_requests=1000,  # Restart worker after 1000 requests to prevent memory leaks
    )
