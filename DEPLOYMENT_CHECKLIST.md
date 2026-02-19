# Render Deployment Checklist

Use this checklist to ensure successful deployment to Render.

## Pre-Deployment

### 1. Code Preparation
- [ ] All code committed to Git
- [ ] `.env` file is in `.gitignore` (never commit secrets!)
- [ ] `requirements.txt` includes all Python dependencies
- [ ] `frontend/package.json` includes all Node dependencies
- [ ] Production startup script (`start_production.py`) is present
- [ ] `render.yaml` configuration is present

### 2. GitHub Setup
- [ ] Code pushed to GitHub repository
- [ ] Repository is public (or Render has access if private)
- [ ] Main branch is named `main` (not `master`)

### 3. MongoDB Atlas Setup
- [ ] MongoDB Atlas account created (free tier)
- [ ] Cluster created
- [ ] Database user created with read/write permissions
- [ ] Network Access allows connections from anywhere (0.0.0.0/0)
- [ ] Connection string copied (username and password included)
- [ ] Test connection from local environment

### 4. Environment Variables Ready
- [ ] `MONGO_URI` - MongoDB connection string
- [ ] `MONGO_DB_NAME` - Database name (federated_screener)
- [ ] `BLOCKCHAIN_LOCAL` - Set to "false" for production
- [ ] (Optional) `PRIVATE_KEY` - Ethereum private key
- [ ] (Optional) `CONTRACT_ADDRESS` - Smart contract address
- [ ] (Optional) `INFURA_PROJECT_ID` - Infura project ID

## Deployment

### 5. Render Account Setup
- [ ] Render account created at [render.com](https://render.com)
- [ ] Email verified
- [ ] GitHub account connected to Render

### 6. Backend Service Deployment
- [ ] New Blueprint or Web Service created
- [ ] GitHub repository connected
- [ ] Service name set: `federated-screener-api`
- [ ] Region selected (e.g., Oregon)
- [ ] Free plan selected
- [ ] Build command: `pip install -r requirements.txt`
- [ ] Start command: `python start_production.py`
- [ ] Environment variables added:
  - [ ] `MONGO_URI`
  - [ ] `MONGO_DB_NAME`
  - [ ] `BLOCKCHAIN_LOCAL`
  - [ ] Other optional blockchain variables
- [ ] Health check path set: `/health`
- [ ] Service deployed successfully

### 7. Frontend Service Deployment
- [ ] New Static Site created
- [ ] Same GitHub repository connected
- [ ] Service name set: `federated-screener-frontend`
- [ ] Region selected (same as backend)
- [ ] Free plan selected
- [ ] Build command: `cd frontend && npm install && npm run build`
- [ ] Publish directory: `frontend/dist`
- [ ] Environment variable added:
  - [ ] `VITE_API_URL` = `https://federated-screener-api.onrender.com`
- [ ] Service deployed successfully

## Post-Deployment Testing

### 8. Backend Health Check
- [ ] Visit: `https://federated-screener-api.onrender.com/health`
- [ ] Response shows:
  ```json
  {
    "status": "healthy",
    "mongodb_connected": true
  }
  ```

### 9. API Documentation
- [ ] Visit: `https://federated-screener-api.onrender.com/docs`
- [ ] Swagger UI loads successfully
- [ ] Can see all endpoints

### 10. Frontend Testing
- [ ] Visit: `https://federated-screener-frontend.onrender.com`
- [ ] Login page loads
- [ ] Try logging in with credentials:
  - [ ] Username: `SaiPrasad24S`, Password: `2724`
  - [ ] Or: Username: `apollo`, Password: `apollo@123`
- [ ] Dashboard loads after login
- [ ] Check browser console for errors (F12 → Console tab)

### 11. Functionality Testing
- [ ] Login/Logout works
- [ ] Patient data loads
- [ ] Trials page shows trials
- [ ] Upload functionality (if tested)
- [ ] All navigation works
- [ ] No critical errors in console

## Optional Enhancements

### 12. Keep Service Warm (Free Tier)
- [ ] Sign up for [UptimeRobot](https://uptimerobot.com) (free)
- [ ] Add monitor for: `https://federated-screener-api.onrender.com/health`
- [ ] Set interval to 14 minutes (keeps service awake)

### 13. Custom Domain (Optional)
- [ ] Domain purchased
- [ ] DNS records configured in domain registrar
- [ ] Custom domain added in Render dashboard
- [ ] SSL certificate issued (automatic)
- [ ] frontend/backend both accessible via custom domain

### 14. Monitoring & Alerts
- [ ] Review logs in Render dashboard
- [ ] Set up email notifications for deploy failures
- [ ] Monitor MongoDB Atlas metrics

### 15. Security Hardening
- [ ] Update CORS in `api/main.py` to specific origins:
  ```python
  allow_origins=[
      "https://federated-screener-frontend.onrender.com",
      "https://yourdomain.com",  # if using custom domain
  ]
  ```
- [ ] Review and rotate MongoDB credentials periodically
- [ ] Ensure no secrets in code or logs
- [ ] Enable MongoDB Atlas audit logs (paid feature)

## Troubleshooting

### Common Issues

**Build Fails:**
- [ ] Check build logs in Render dashboard
- [ ] Verify all dependencies in `requirements.txt`
- [ ] Ensure Python version matches `runtime.txt`

**Service Won't Start:**
- [ ] Check deploy logs
- [ ] Verify `start_production.py` exists and is executable
- [ ] Test startup command locally first

**MongoDB Connection Issues:**
- [ ] Verify `MONGO_URI` is correct
- [ ] Check MongoDB Atlas network access (0.0.0.0/0)
- [ ] Ensure database user has correct permissions
- [ ] Test connection string locally

**Frontend Shows Errors:**
- [ ] Check browser console (F12)
- [ ] Verify `VITE_API_URL` is set correctly
- [ ] Check CORS settings in backend
- [ ] Ensure backend is running

**Slow Performance:**
- [ ] Normal for free tier (sleeps after 15 min)
- [ ] Set up UptimeRobot to keep warm
- [ ] Consider upgrading to paid plan

## Success Criteria

Your deployment is successful when:

✓ Health endpoint returns "healthy"
✓ Login page loads without errors
✓ Can log in with test credentials
✓ Dashboard shows patient/trial data
✓ No critical errors in browser console
✓ Backend logs show successful requests
✓ MongoDB connection is stable

## Next Steps After Deployment

1. Share URLs with stakeholders
2. Monitor usage and performance
3. Plan for scaling if needed
4. Regular security updates
5. Backup MongoDB data regularly

## Support Resources

- **Render Docs**: https://render.com/docs
- **Render Community**: https://community.render.com
- **MongoDB Atlas Docs**: https://docs.atlas.mongodb.com
- **Project Documentation**: See `PROJECT_DOCUMENTATION.txt`

---

**Deployment Date**: _________________
**Deployed By**: _________________
**Backend URL**: _________________
**Frontend URL**: _________________
**Notes**: _________________
