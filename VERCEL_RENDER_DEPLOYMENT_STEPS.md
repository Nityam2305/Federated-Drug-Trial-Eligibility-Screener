# Complete Deployment Guide: Vercel + Render

Deploy your Federated Drug Trial Eligibility Screener to production:
- **Backend (FastAPI)** → Render
- **Frontend (React + Vite)** → Vercel
- **Database** → MongoDB Atlas (already configured ✅)

---

## 📋 Prerequisites (5 minutes)

### 1. Create Accounts
- [ ] **GitHub account** (if not already have one)
- [ ] **Render account** at [render.com](https://render.com) - Sign up with GitHub
- [ ] **Vercel account** at [vercel.com](https://vercel.com) - Sign up with GitHub
- [ ] **MongoDB Atlas** - Already configured ✅

### 2. Prepare Repository
```powershell
# Initialize Git if not already done
git init

# Add all files except .env
git add .

# Commit
git commit -m "Initial commit - ready for deployment"

# Create GitHub repository (via GitHub website)
# Then push:
git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO_NAME.git
git branch -M main
git push -u origin main
```

**⚠️ IMPORTANT**: Ensure `.env` is in `.gitignore` (never commit secrets!)

---

## 🎯 Step-by-Step Deployment

### STEP 1: Deploy Backend to Render (15 minutes)

#### 1.1 Go to Render Dashboard
1. Visit [render.com/dashboard](https://render.com/dashboard)
2. Click **"New +"** → **"Web Service"**

#### 1.2 Connect Repository
1. Click **"Connect account"** → Select GitHub
2. Grant Render access to your repository
3. Select your repository: `YOUR_USERNAME/YOUR_REPO_NAME`

#### 1.3 Configure Service
Fill in these settings:

| Setting | Value |
|---------|-------|
| **Name** | `federated-screener-api` (or your choice) |
| **Region** | Oregon (US West) or closest to you |
| **Branch** | `main` |
| **Root Directory** | Leave empty (uses project root) |
| **Runtime** | Python 3 |
| **Build Command** | `pip install -r requirements.txt` |
| **Start Command** | `python start_production.py` |
| **Instance Type** | Free |

#### 1.4 Add Environment Variables
Click **"Advanced"** → **"Add Environment Variable"**

Add these variables (copy from your local `.env` file):

```
MONGO_URI = mongodb+srv://yb15313037_db_user:D09J5gp...@cluster0.oxujjgd.mongodb.net/
MONGO_DB_NAME = federated_screener
BLOCKCHAIN_LOCAL = false
```

**Important**: Use your actual MongoDB connection string!

#### 1.5 Configure Health Check (Optional but Recommended)
- **Health Check Path**: `/health`

#### 1.6 Deploy
1. Click **"Create Web Service"**
2. Wait for deployment (5-10 minutes)
3. Watch logs for "MongoDB initialized successfully"

#### 1.7 Verify Backend
Your backend URL will be: `https://federated-screener-api.onrender.com`

Test it:
```
Visit: https://federated-screener-api.onrender.com/health

Should return:
{
  "status": "healthy",
  "mongodb_connected": true,
  ...
}
```

✅ **Backend deployed!** Copy your backend URL for the next step.

---

### STEP 2: Deploy Frontend to Vercel (10 minutes)

#### 2.1 Go to Vercel Dashboard
1. Visit [vercel.com/dashboard](https://vercel.com/dashboard)
2. Click **"Add New..."** → **"Project"**

#### 2.2 Import Repository
1. Click **"Import Git Repository"**
2. Select **"Continue with GitHub"** if needed
3. Find and select your repository
4. Click **"Import"**

#### 2.3 Configure Project

| Setting | Value |
|---------|-------|
| **Project Name** | `federated-screener` (or your choice) |
| **Framework Preset** | Vite |
| **Root Directory** | `./` (project root) |
| **Build Command** | `cd frontend && npm install && npm run build` |
| **Output Directory** | `frontend/dist` |
| **Install Command** | `npm install` |
| **Node.js Version** | 18.x (default) |

#### 2.4 Add Environment Variables
Click **"Environment Variables"** section:

Add this variable:
```
Name: VITE_API_URL
Value: https://federated-screener-api.onrender.com
```

**Replace with your actual Render backend URL from Step 1!**

Optional blockchain variables (if you have them):
```
VITE_BLOCKCHAIN_RPC_URL = https://mainnet.infura.io/v3/YOUR_PROJECT_ID
VITE_CONTRACT_ADDRESS = 0x...
```

#### 2.5 Deploy
1. Click **"Deploy"**
2. Wait for build and deployment (3-5 minutes)
3. Watch build logs for success

#### 2.6 Verify Frontend
Your frontend URL will be: `https://federated-screener.vercel.app`

Test it:
1. Visit your Vercel URL
2. You should see the login page
3. Try logging in with credentials:
   - Username: `SaiPrasad24S`
   - Password: `2724`
4. Dashboard should load with patient data

#### 2.7 Check Browser Console
1. Press F12 to open Developer Tools
2. Go to Console tab
3. Should see no errors (warnings are okay)

✅ **Frontend deployed!**

---

## 🔧 Post-Deployment Configuration

### Update Backend CORS (Important!)
After frontend is deployed, update CORS in your backend to restrict origins:

1. In your code, edit `api/main.py`:
```python
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:3000",  # Local development
        "https://federated-screener.vercel.app",  # Your Vercel URL
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
```

2. Commit and push changes:
```powershell
git add api/main.py
git commit -m "Update CORS for production"
git push
```

3. Render will automatically redeploy (watch dashboard)

---

## ✅ Final Testing Checklist

Test all functionality in production:

- [ ] **Login Page**: Loads without errors
- [ ] **Login**: Can log in with test credentials
- [ ] **Dashboard**: Shows overview with stats
- [ ] **Patients**: Patient list loads
- [ ] **Trials**: Trials page shows data
- [ ] **Navigation**: All pages accessible
- [ ] **API Calls**: Check Network tab in browser (F12 → Network)
- [ ] **No Console Errors**: Check Console tab (F12 → Console)
- [ ] **Mobile**: Test on phone/tablet if needed

---

## 🎉 You're Live!

### Your URLs
- **Frontend**: `https://federated-screener.vercel.app`
- **Backend API**: `https://federated-screener-api.onrender.com`
- **API Docs**: `https://federated-screener-api.onrender.com/docs`
- **Health Check**: `https://federated-screener-api.onrender.com/health`

### Share with Stakeholders
Send them the frontend URL with login credentials:
```
URL: https://federated-screener.vercel.app

Test Credentials:
- Hospital 1: Username: SaiPrasad24S, Password: 2724
- Hospital 2: Username: apollo, Password: apollo@123
- Hospital 3: Username: medlife, Password: medlife@123
- Hospital 4: Username: omni, Password: omni@123
```

---

## ⚙️ Optional Enhancements

### Keep Backend Warm (Free Tier Limitation)
Render free tier sleeps after 15 minutes of inactivity. Use UptimeRobot to keep it alive:

1. Sign up at [uptimerobot.com](https://uptimerobot.com) (free)
2. Add New Monitor:
   - Type: HTTP(s)
   - URL: `https://federated-screener-api.onrender.com/health`
   - Interval: 14 minutes
3. Save - your backend will stay warm!

### Custom Domain
If you have a custom domain:

**Vercel (Frontend)**:
1. Go to Vercel project settings
2. Domains → Add Domain
3. Follow DNS configuration steps
4. SSL certificate auto-generated

**Render (Backend)**:
1. Go to Render service settings
2. Custom Domains → Add Domain
3. Configure DNS records
4. SSL certificate auto-generated

Then update environment variables:
- Update `VITE_API_URL` in Vercel to your custom backend domain
- Update CORS in backend to include custom frontend domain

### Environment-Specific Configurations
For development vs production:

**Vercel**: Deploy preview deployments for testing
- Every branch gets its own URL
- Main branch = production URL

**Render**: Create separate services for staging
- Clone service for staging environment
- Use different MongoDB database

---

## 🐛 Troubleshooting

### Backend Issues

**Problem**: Build fails
- Check Render logs (Dashboard → Service → Logs)
- Verify `requirements.txt` has all dependencies
- Ensure `runtime.txt` has Python 3.11

**Problem**: Service won't start
- Check deploy logs for Python errors
- Verify `MONGO_URI` is set correctly
- Test `start_production.py` locally first

**Problem**: MongoDB connection error
- Verify environment variable `MONGO_URI` in Render
- Check MongoDB Atlas → Network Access → Allow 0.0.0.0/0
- Verify database user has read/write permissions
- Test connection string locally

**Problem**: 503 Service Unavailable
- Wait 30-60 seconds (cold start on free tier)
- Check if service is sleeping (free tier sleeps after 15 min)
- Set up UptimeRobot to keep warm

### Frontend Issues

**Problem**: Build fails on Vercel
- Check build logs in Vercel dashboard
- Verify build command is correct
- Ensure `frontend/package.json` exists
- Try building locally first: `cd frontend && npm run build`

**Problem**: Blank page or white screen
- Check browser console (F12 → Console)
- Verify `VITE_API_URL` is set in Vercel environment variables
- Check if backend is running (visit health endpoint)
- Verify `frontend/dist/index.html` was built

**Problem**: Network errors / API calls fail
- Verify `VITE_API_URL` matches your Render backend URL
- Check CORS configuration in backend
- Verify backend is running (not asleep)
- Check browser Network tab (F12 → Network)

**Problem**: After redeployment, changes not visible
- Vercel: Wait 2-3 minutes for CDN cache to clear
- Hard refresh browser: Ctrl+Shift+R (Windows) or Cmd+Shift+R (Mac)
- Verify deployment completed successfully in Vercel dashboard

### MongoDB Issues

**Problem**: Authentication failed
- Verify username/password in connection string
- Check database user in MongoDB Atlas → Database Access
- Ensure user has read/write role

**Problem**: Connection timeout
- Check MongoDB Atlas → Network Access
- Add 0.0.0.0/0 to IP whitelist
- Verify cluster is not paused
- Check Atlas cluster status

---

## 📊 Monitoring & Maintenance

### Daily
- Check Render logs for errors
- Review Vercel analytics (if available)

### Weekly
- Test login and core features
- Review MongoDB Atlas metrics
- Check for security updates

### Monthly
- Review and rotate secrets (MongoDB password)
- Update dependencies (`npm update`, `pip list --outdated`)
- Review usage and costs
- Backup MongoDB data

---

## 📚 Additional Resources

- **Render Documentation**: https://render.com/docs
- **Vercel Documentation**: https://vercel.com/docs
- **MongoDB Atlas Docs**: https://docs.atlas.mongodb.com
- **Project Docs**: See `PROJECT_DOCUMENTATION.txt`
- **MongoDB Setup**: See `MONGODB_VERIFICATION.txt`
- **Render Details**: See `RENDER_DEPLOYMENT.md`
- **Vercel Details**: See `VERCEL_DEPLOYMENT.md`

---

## 🎓 What Just Happened?

You deployed a full-stack application:

1. **Backend (Render)**: Python FastAPI server running 24/7 (with free tier limitations)
2. **Frontend (Vercel)**: React app served globally via CDN
3. **Database (MongoDB Atlas)**: Cloud database accessible from anywhere
4. **CI/CD**: Automatic deployments on every `git push`

Every time you push to GitHub:
- Render rebuilds and redeploys backend
- Vercel rebuilds and redeploys frontend
- Both happen automatically within minutes

---

## 🚀 Next Steps

1. Share URLs with users/stakeholders
2. Set up UptimeRobot to keep backend warm
3. Monitor usage and performance
4. Plan for scaling if needed
5. Consider custom domain for professional appearance
6. Set up MongoDB backups
7. Review security settings

---

**Deployment Completed**: _________________
**Backend URL**: _________________
**Frontend URL**: _________________
**Notes**: _________________

🎉 **Congratulations! Your application is now live!** 🎉
