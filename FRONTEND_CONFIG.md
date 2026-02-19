================================================================================
FRONTEND CONFIGURATION FOR CLOUDFLARE TUNNEL BACKEND
================================================================================

Update your React Vite frontend to use the Cloudflare Tunnel backend URL.

================================================================================
PART 1: CREATE PRODUCTION ENV FILE
================================================================================

Create file: frontend/.env.production

────────────────────────────────────────────────────────────────────────────
# PRODUCTION ENVIRONMENT
# Used when: npm run build

# API URL - points to your Cloudflare Tunnel backend
VITE_API_URL=https://api.YOUR_DOMAIN.com

# Optional: Blockchain configuration
VITE_BLOCKCHAIN_RPC_URL=https://mainnet.infura.io/v3/YOUR_PROJECT_ID
VITE_CONTRACT_ADDRESS=0x...

# App mode
VITE_ENV=production

────────────────────────────────────────────────────────────────────────────

IMPORTANT:
  ✓ Replace YOUR_DOMAIN.com with your actual domain
  ✓ This file is used during `npm run build`
  ✓ Don't commit with secrets (but this file has no secrets)
  ✓ Create separate .env.development for local testing

================================================================================
PART 2: CREATE DEVELOPMENT ENV FILE
================================================================================

Create file: frontend/.env.development

────────────────────────────────────────────────────────────────────────────
# DEVELOPMENT ENVIRONMENT
# Used when: npm run dev (local development)

# API URL - points to local backend
VITE_API_URL=http://localhost:8002

# Optional: Local blockchain
VITE_BLOCKCHAIN_RPC_URL=http://localhost:8545
VITE_CONTRACT_ADDRESS=0x...

# App mode
VITE_ENV=development

────────────────────────────────────────────────────────────────────────────

================================================================================
PART 3: UPDATE API SERVICE
================================================================================

File: frontend/src/services/apiService.js

Make sure it uses import.meta.env.VITE_API_URL:

────────────────────────────────────────────────────────────────────────────
import axios from 'axios';

// Get API URL from environment, with fallback for development
const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8002';

console.log(`[API Service] Connecting to: ${API_BASE_URL}`);

// Create axios instance with base URL
const apiClient = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
  withCredentials: true,  // Send cookies with requests
});

// Request interceptor - add authentication token
apiClient.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('authToken');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => Promise.reject(error)
);

// Response interceptor - handle errors
apiClient.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      // Unauthorized - clear token and redirect to login
      localStorage.removeItem('authToken');
      window.location.href = '/login';
    }
    
    // Log network errors
    if (!error.response) {
      console.error('[API Service] Network error - backend unreachable:', error.message);
      console.error(`[API Service] Attempted to reach: ${API_BASE_URL}`);
    }
    
    return Promise.reject(error);
  }
);

// API endpoints
const apiService = {
  // Hospital login
  login: (username, password) =>
    apiClient.post('/hospital_login', { username, password }),
  
  // Get patients
  getPatients: () =>
    apiClient.get('/get_patients'),
  
  // Get trials
  getTrials: () =>
    apiClient.get('/get_trials'),
  
  // Health check
  health: () =>
    apiClient.get('/health'),
  
  // Predict eligibility
  predict: (data) =>
    apiClient.post('/predict', data),
};

export default apiService;

────────────────────────────────────────────────────────────────────────────

================================================================================
PART 4: UPDATE LOGIN COMPONENT
================================================================================

File: frontend/src/components/LoginPage.jsx

Add error handling for unreachable backend:

────────────────────────────────────────────────────────────────────────────
import { useState, useEffect } from 'react';
import apiService from '../services/apiService';

export default function LoginPage() {
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const [backendAvailable, setBackendAvailable] = useState(true);

  // Check backend availability on mount
  useEffect(() => {
    const checkBackend = async () => {
      try {
        await apiService.health();
        setBackendAvailable(true);
      } catch (err) {
        setBackendAvailable(false);
        console.error('Backend health check failed:', err);
      }
    };

    checkBackend();
    // Check every 30 seconds
    const interval = setInterval(checkBackend, 30000);
    return () => clearInterval(interval);
  }, []);

  const handleLogin = async (e) => {
    e.preventDefault();
    setError('');
    setLoading(true);

    try {
      if (!backendAvailable) {
        setError('Backend is not available. Please try again later.');
        return;
      }

      const response = await apiService.login(username, password);
      const { token } = response.data;

      // Store token
      localStorage.setItem('authToken', token);

      // Redirect to dashboard
      window.location.href = '/dashboard';
    } catch (err) {
      if (!err.response) {
        setError('Cannot connect to backend. Is it running?');
        setBackendAvailable(false);
      } else {
        setError(err.response.data?.detail || 'Login failed');
      }
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="login-container">
      <h1>Login</h1>

      {!backendAvailable && (
        <div className="alert alert-warning">
          ⚠️ Backend is currently unavailable.
          Please check:
          1. Is the backend running?
          2. Is Cloudflare Tunnel active?
          3. Check your internet connection
        </div>
      )}

      {error && <div className="alert alert-error">{error}</div>}

      <form onSubmit={handleLogin}>
        <input
          type="text"
          placeholder="Username"
          value={username}
          onChange={(e) => setUsername(e.target.value)}
          required
        />
        <input
          type="password"
          placeholder="Password"
          value={password}
          onChange={(e) => setPassword(e.target.value)}
          required
        />
        <button type="submit" disabled={loading || !backendAvailable}>
          {loading ? 'Logging in...' : 'Login'}
        </button>
      </form>
    </div>
  );
}

────────────────────────────────────────────────────────────────────────────

================================================================================
PART 5: VITE CONFIG FOR DIFFERENT ENVIRONMENTS
================================================================================

File: frontend/vite.config.js

Ensure it loads env files correctly:

────────────────────────────────────────────────────────────────────────────
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  
  server: {
    port: 3000,
    strictPort: false,  // If 3000 in use, try 3001, etc.
    proxy: {
      // This is optional - only if you want local dev server to proxy API
      '/api': {
        target: 'http://localhost:8002',
        changeOrigin: true,
        rewrite: (path) => path.replace(/^\/api/, ''),
      },
    },
  },

  build: {
    outDir: 'dist',
    sourcemap: false,  // Don't create source maps in production
    minify: 'terser',
    terserOptions: {
      compress: {
        drop_console: true,  // Remove console.log in production
      },
    },
  },

  // Load .env files based on MODE
  envPrefix: 'VITE_',
});

────────────────────────────────────────────────────────────────────────────

================================================================================
PART 6: PACKAGE.JSON BUILD COMMANDS
================================================================================

File: frontend/package.json

Make sure your build scripts exist:

────────────────────────────────────────────────────────────────────────────
{
  "scripts": {
    "dev": "vite",
    "build": "vite build",
    "build:prod": "vite build --mode production",
    "preview": "vite preview",
    "lint": "eslint src"
  }
}

────────────────────────────────────────────────────────────────────────────

Commands:
  - npm run dev               → Local development (uses .env.development)
  - npm run build             → Production build (uses .env.production)
  - npm run preview           → Preview production build locally

================================================================================
PART 7: BUILD STEPS FOR PRODUCTION
================================================================================

When deploying production build:

Step 1: Ensure .env.production is set correctly
    VITE_API_URL=https://api.YOUR_DOMAIN.com

Step 2: Build the project
    cd frontend
    npm run build

Step 3: Verify dist folder created
    ls dist/               (Linux/Mac)
    dir dist               (Windows)
    
    Should contain:
      - index.html
      - assets/
      - style.css

Step 4: Serve locally to test (optional)
    npm run preview
    
    Then open: http://localhost:4173
    Should connect to backend and allow login

Step 5: Deploy (if using Vercel, etc.)
    - dist/ folder gets deployed
    - Users access your domain
    - React loads and communicates with Cloudflare Tunnel backend

================================================================================
PART 8: TROUBLESHOOTING
================================================================================

Problem: "Cannot GET /api/hospital_login"
──────────────────────────────────────────

Solution:
  1. Check VITE_API_URL in .env.production
  2. Verify backend is running: curl https://api.YOUR_DOMAIN.com/health
  3. Check browser Network tab (F12 → Network)
  4. Verify CORS in backend allows your domain

Problem: "Backend connection refused"
──────────────────────────────────────

Solution:
  1. Is Cloudflare Tunnel running? (should see "Tunnel connected")
  2. Is FastAPI running? (check terminal/logs)
  3. Is your laptop's firewall blocking port 8002?
  4. Is internet connection stable?

Problem: "CORS error" in browser console
──────────────────────────────────────────

Solution:
  1. Check CORS in api/main.py - should include your frontend domain
  2. For development: FRONTEND_URL=http://localhost:3000
  3. For production: FRONTEND_URL=https://frontend.YOUR_DOMAIN.com
  4. Restart backend after changing CORS

Problem: "Environment variables not being used"
────────────────────────────────────────────────

Solution:
  1. .env file must be in frontend/ directory
  2. Variables must start with VITE_
  3. Frontend must be REBUILT after changing .env
  4. Vite dev server auto-detects .env changes, build doesn't

Problem: "Works in development, fails in production"
─────────────────────────────────────────────────────

Solution:
  1. npm run build creates optimized version
  2. Test production build locally: npm run preview
  3. Check that VITE_API_URL is correct in .env.production
  4. Console should show "[API Service] Connecting to: https://api.YOUR_DOMAIN.com"

================================================================================
QUICK REFERENCE
================================================================================

Local Development:
  1. VITE_API_URL=http://localhost:8002
  2. npm run dev
  3. Open http://localhost:3000

Production Build:
  1. VITE_API_URL=https://api.YOUR_DOMAIN.com
  2. npm run build
  3. Result in frontend/dist/

Environment Variables:
  - Development: frontend/.env.development
  - Production: frontend/.env.production
  - Both must have VITE_API_URL
  - All variables must start with VITE_

Accessing API:
  - In code: axios.get('/get_patients')
  - Full URL: https://api.YOUR_DOMAIN.com/get_patients (auto-prefixed)

================================================================================
SUMMARY
================================================================================

Your React frontend is now:
  ✅ Uses environment variables for API URL
  ✅ Works locally with port 8002
  ✅ Builds for production with Cloudflare Tunnel URL
  ✅ Has error handling for unavailable backend
  ✅ Automatically detects backend availability

Next:
  1. Create .env.production with your domain
  2. npm run build
  3. npm run preview to test production build locally
  4. Verify it connects to Cloudflare Tunnel backend
  5. Deploy!

================================================================================
