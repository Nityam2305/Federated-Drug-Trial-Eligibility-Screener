# Vercel Deployment Guide

## ✅ Pre-Deployment Verification

Your Vite React app is ready for Vercel deployment with the following configurations:

### ✓ Build Script
- **Command**: `vite build` (in package.json)
- **Output Directory**: `frontend/dist`
- **Framework**: Vite

### ✓ Environment Variables
- **VITE_API_URL**: Uses environment variable with localhost fallback
- **VITE_BLOCKCHAIN_RPC_URL**: Optional, uses env var with Ganache fallback
- **VITE_CONTRACT_ADDRESS**: Optional, for blockchain features

### ✓ No Hardcoded URLs
- All API calls use `import.meta.env.VITE_API_URL`
- Blockchain service uses `import.meta.env.VITE_BLOCKCHAIN_RPC_URL`
- Localhost URLs only exist as development fallbacks

---

## 🚀 Deployment Steps

### 1. Push Code to GitHub

```bash
git add .
git commit -m "Prepare for Vercel deployment"
git push origin main
```

### 2. Deploy to Vercel

#### Option A: Using Vercel Dashboard (Recommended)

1. Go to [vercel.com](https://vercel.com)
2. Click **"Add New..."** → **"Project"**
3. Import your GitHub repository
4. Configure project:
   - **Framework Preset**: Vite
   - **Root Directory**: `./` (project root)
   - **Build Command**: `cd frontend && npm install && npm run build`
   - **Output Directory**: `frontend/dist`
   - **Install Command**: `npm install`

5. Add Environment Variables:
   ```
   VITE_API_URL = https://your-backend-url.onrender.com
   ```

6. Click **"Deploy"**

#### Option B: Using Vercel CLI

```bash
# Install Vercel CLI globally
npm install -g vercel

# Navigate to your project
cd /path/to/Federated-Drug-Trial-Eligibility-Screener-main

# Login to Vercel
vercel login

# Deploy
vercel

# Follow the prompts:
# Set up and deploy? Yes
# Which scope? Your account
# Link to existing project? No
# What's your project's name? federated-screener
# In which directory is your code located? ./
# Want to override settings? Yes
# Build Command? cd frontend && npm install && npm run build
# Output Directory? frontend/dist
# Development Command? cd frontend && npm run dev
```

---

## 🔧 Environment Variables Configuration

### Required Variables

Set these in Vercel Dashboard → Your Project → Settings → Environment Variables:

| Variable | Value | Environment |
|----------|-------|-------------|
| `VITE_API_URL` | `https://federated-screener-api.onrender.com` | Production |
| `VITE_API_URL` | `http://localhost:8002` | Development |

### Optional Variables (for blockchain features)

| Variable | Value | When to Use |
|----------|-------|-------------|
| `VITE_BLOCKCHAIN_RPC_URL` | Your Infura/Alchemy URL | Production with blockchain |
| `VITE_CONTRACT_ADDRESS` | Deployed contract address | After contract deployment |

**Note**: If blockchain variables are not set, the app will gracefully disable blockchain features and use the backend API for audit logs.

---

## 📝 vercel.json Configuration

The included `vercel.json` file provides:

- ✅ SPA routing (all routes go to index.html)
- ✅ Security headers (XSS protection, frame options, etc.)
- ✅ Asset caching (1 year cache for static assets)
- ✅ Build configuration
- ✅ Node.js version specification

---

## 🧪 Testing Your Deployment

After deployment, Vercel provides a URL like: `https://federated-screener-abc123.vercel.app`

### 1. Basic Functionality Test
```bash
# Open the URL in your browser
https://your-app.vercel.app

# Check that:
✓ Login page loads
✓ No console errors (F12 → Console)
✓ All assets load correctly
```

### 2. API Connection Test
```bash
# Try logging in with test credentials:
Username: SaiPrasad24S
Password: 2724

# OR
Username: apollo
Password: apollo@123

# Check that:
✓ Login request goes to your backend URL
✓ Dashboard loads after login
✓ Patient data displays correctly
```

### 3. Check Environment Variables
```javascript
// Open browser console (F12) and run:
console.log('API URL:', import.meta.env.VITE_API_URL);

// Should show your production backend URL, not localhost
```

---

## 🔄 Continuous Deployment

### Auto-Deploy from GitHub

By default, Vercel automatically deploys:
- **Production**: Pushes to `main` branch → Production URL
- **Preview**: Pull requests → Unique preview URL
- **Development**: Pushes to other branches → Development preview URL

### Manual Deployment

```bash
# Deploy to production
vercel --prod

# Deploy preview
vercel
```

---

## 🌐 Custom Domain (Optional)

1. Go to Vercel Dashboard → Your Project → Settings → Domains
2. Add your custom domain (e.g., `app.yourdomain.com`)
3. Update DNS records as instructed by Vercel
4. SSL certificate is automatically provisioned (free)

---

## ⚙️ Advanced Configuration

### Build Performance

For faster builds, cache dependencies:

```json
// vercel.json
{
  "github": {
    "silent": true
  },
  "installCommand": "npm ci --legacy-peer-deps"
}
```

### Environment-Specific Builds

```bash
# In Vercel dashboard, you can set different variables for:
- Production
- Preview
- Development
```

### Build Hooks

Set up build hooks in Vercel to trigger deployments:
- Settings → Git → Deploy Hooks
- Use webhook URL in CI/CD or external services

---

## 🐛 Troubleshooting

### Build Fails

**Check build logs in Vercel dashboard**

Common issues:
```bash
# Missing dependencies
Solution: Ensure all deps in frontend/package.json

# Build command fails
Solution: Test locally: cd frontend && npm run build

# Output directory not found
Solution: Verify "frontend/dist" exists after build
```

### API Connection Issues

**Symptoms**: Login fails, data doesn't load

```bash
# Check environment variables
Vercel Dashboard → Settings → Environment Variables
Ensure VITE_API_URL is set correctly

# Verify CORS on backend
Backend must allow requests from your Vercel domain
```

### Routing Issues (404 on refresh)

**Symptoms**: Works on homepage but 404 on other routes

```bash
# Ensure vercel.json has rewrite rules:
{
  "rewrites": [
    { "source": "/(.*)", "destination": "/index.html" }
  ]
}
```

### Environment Variables Not Working

```bash
# Vite requires VITE_ prefix
✓ VITE_API_URL
✗ API_URL (won't work)

# Redeploy after adding variables
Variables only apply to new builds
```

---

## 📊 Monitoring & Analytics

### Vercel Analytics (Optional - Paid)

Enable in Vercel Dashboard → Your Project → Analytics

Provides:
- Page views
- Unique visitors
- Performance metrics
- Web Vitals

### Custom Analytics

Add to `frontend/src/main.jsx`:
```javascript
// Google Analytics, Mixpanel, etc.
```

---

## 💰 Pricing

### Free Tier (Hobby)
- ✅ Unlimited deployments
- ✅ Automatic HTTPS
- ✅ 100 GB bandwidth/month
- ✅ Automatic preview deployments
- ✅ Perfect for this project

### Pro Tier ($20/month)
- 1 TB bandwidth
- Faster builds
- Password protection
- Analytics

---

## 🔒 Security Best Practices

### 1. Environment Variables
```bash
# Never commit .env files
# Always use Vercel dashboard for secrets
```

### 2. API Security
```bash
# Backend should implement rate limiting
# Use CORS to restrict allowed origins
```

### 3. Content Security Policy
Add to vercel.json:
```json
{
  "headers": [{
    "source": "/(.*)",
    "headers": [{
      "key": "Content-Security-Policy",
      "value": "default-src 'self'; script-src 'self' 'unsafe-inline'"
    }]
  }]
}
```

---

## 📦 Deployment Checklist

- [ ] Code pushed to GitHub
- [ ] Vercel account created
- [ ] Project imported to Vercel
- [ ] Environment variables configured
- [ ] Build command set correctly
- [ ] Output directory set to `frontend/dist`
- [ ] Deployment successful
- [ ] Login page loads
- [ ] API connection works
- [ ] No console errors
- [ ] All routes work (test refresh on different pages)
- [ ] Mobile responsive (test on phone)
- [ ] Custom domain configured (optional)

---

## 🎯 Quick Reference

```bash
# Deploy to production
vercel --prod

# Check deployment status
vercel ls

# View deployment logs
vercel logs [deployment-url]

# List environment variables
vercel env ls

# Add environment variable
vercel env add VITE_API_URL

# Remove deployment
vercel remove [deployment-name]
```

---

## 📞 Support Resources

- **Vercel Documentation**: https://vercel.com/docs
- **Vercel Community**: https://github.com/vercel/vercel/discussions
- **Vite Documentation**: https://vitejs.dev/guide/
- **Project Docs**: See `PROJECT_DOCUMENTATION.txt`

---

## ✨ Post-Deployment

### 1. Share Your App
Your frontend is now live at: `https://your-app.vercel.app`

### 2. Monitor Performance
- Check Vercel Dashboard for build times
- Monitor bandwidth usage
- Review error logs if any

### 3. Iterate
- Make changes to code
- Push to GitHub
- Vercel auto-deploys
- Check preview URL before merging to main

---

**Deployment Date**: _________________
**Production URL**: _________________
**Backend URL**: _________________
**Status**: _________________
