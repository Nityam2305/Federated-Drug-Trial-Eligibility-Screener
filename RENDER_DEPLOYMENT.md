# Render Deployment Guide

## Quick Start

### Prerequisites
- GitHub account
- Render account (free tier available at [render.com](https://render.com))
- MongoDB Atlas account (free tier)
- Environment variables configured

### Deployment Steps

#### Option 1: Using render.yaml (Recommended)

1. **Push code to GitHub**
   ```bash
   git init
   git add .
   git commit -m "Initial commit"
   git remote add origin https://github.com/yourusername/federated-screener.git
   git push -u origin main
   ```

2. **Connect to Render**
   - Go to [Render Dashboard](https://dashboard.render.com)
   - Click "New" → "Blueprint"
   - Connect your GitHub repository
   - Render will automatically detect `render.yaml` and create both services

3. **Configure Environment Variables**
   
   In Render Dashboard, set these for the **backend service**:
   
   Required:
   - `MONGO_URI`: Your MongoDB Atlas connection string
   - `MONGO_DB_NAME`: `federated_screener`
   
   Optional (for blockchain):
   - `BLOCKCHAIN_LOCAL`: `false` (for production)
   - `PRIVATE_KEY`: Your Ethereum private key (for Sepolia testnet)
   - `CONTRACT_ADDRESS`: Deployed smart contract address
   - `INFURA_PROJECT_ID`: Your Infura project ID

4. **Deploy**
   - Render will automatically build and deploy
   - Backend URL: `https://federated-screener-api.onrender.com`
   - Frontend URL: `https://federated-screener-frontend.onrender.com`

#### Option 2: Manual Deployment

**Backend:**

1. Go to Render Dashboard → "New" → "Web Service"
2. Connect GitHub repository
3. Configure:
   - **Name**: `federated-screener-api`
   - **Region**: Oregon (or nearest)
   - **Branch**: `main`
   - **Runtime**: Python 3
   - **Build Command**: `pip install -r requirements.txt`
   - **Start Command**: `python start_production.py`
   - **Plan**: Free
4. Add environment variables (see above)
5. Create Web Service

**Frontend:**

1. Go to Render Dashboard → "New" → "Static Site"
2. Connect GitHub repository
3. Configure:
   - **Name**: `federated-screener-frontend`
   - **Branch**: `main`
   - **Build Command**: `cd frontend && npm install && npm run build`
   - **Publish Directory**: `frontend/dist`
4. Add environment variable:
   - `VITE_API_URL`: `https://federated-screener-api.onrender.com`
5. Create Static Site

### Important Notes

#### Free Tier Limitations
- Backend service sleeps after 15 minutes of inactivity
- First request after sleep takes ~30 seconds to wake up
- 750 hours/month of runtime
- Solution: Use a service like [UptimeRobot](https://uptimerobot.com) to ping every 14 minutes

#### CORS Configuration
The backend is already configured to allow all origins for development:
```python
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
```

For production, update in `api/main.py`:
```python
allow_origins=[
    "https://federated-screener-frontend.onrender.com",
    "http://localhost:3000",
]
```

#### Frontend API URL
Update `frontend/src/services/apiService.js`:
```javascript
const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8002';
```

Build will use the environment variable `VITE_API_URL` from Render.

### Environment Variables Reference

| Variable | Required | Description | Example |
|----------|----------|-------------|---------|
| `PORT` | Auto | Set by Render | 10000 |
| `MONGO_URI` | Yes | MongoDB connection | mongodb+srv://... |
| `MONGO_DB_NAME` | Yes | Database name | federated_screener |
| `BLOCKCHAIN_LOCAL` | No | Use local blockchain | false |
| `PRIVATE_KEY` | No | Ethereum private key | 0x... |
| `CONTRACT_ADDRESS` | No | Smart contract address | 0x... |
| `INFURA_PROJECT_ID` | No | Infura project ID | abc123... |

### Health Check
The backend includes a health check endpoint at `/health`:
```bash
curl https://federated-screener-api.onrender.com/health
```

Response:
```json
{
  "status": "healthy",
  "blockchain_connected": false,
  "mongodb_connected": true,
  "training_active": false
}
```

### Troubleshooting

**Build Fails:**
- Check `requirements.txt` has all dependencies
- Verify Python version in `runtime.txt` is supported
- Check build logs in Render Dashboard

**Service Won't Start:**
- Verify `start_production.py` has execute permissions
- Check environment variables are set correctly
- Review deployment logs for errors

**MongoDB Connection Fails:**
- Verify `MONGO_URI` is correct
- Check MongoDB Atlas allows connections from anywhere (0.0.0.0/0)
- Ensure database user has read/write permissions

**Frontend Can't Connect to Backend:**
- Verify `VITE_API_URL` is set during build
- Check CORS settings in backend
- Confirm backend service is running

**Slow First Request (Cold Start):**
- Normal for free tier (service sleeps after 15 min)
- Use UptimeRobot to keep service warm
- Consider upgrading to paid plan for always-on service

### Monitoring

**View Logs:**
- Render Dashboard → Your Service → Logs tab
- Real-time log streaming available

**Metrics:**
- Render Dashboard → Your Service → Metrics tab
- CPU, Memory, Bandwidth usage

### Updating Deployment

**Automatic:**
- Push to GitHub `main` branch
- Render auto-deploys if `autoDeploy: true` in `render.yaml`

**Manual:**
- Render Dashboard → Your Service → Manual Deploy → Deploy latest commit

### Custom Domain (Optional)

1. Go to Service → Settings → Custom Domain
2. Add your domain (e.g., `api.yourdomain.com`)
3. Update DNS records as instructed
4. Render provides free SSL certificate

### Scaling

**Horizontal Scaling:**
- Not available on free tier
- Upgrade to paid plan for multiple instances

**Vertical Scaling:**
- Free tier: 512 MB RAM, 0.1 CPU
- Paid plans: Up to 32 GB RAM, 8 CPU

### Cost Optimization

**Free Tier Strategy:**
- Use MongoDB Atlas free tier (512 MB)
- Use Render free tier for both services
- Use UptimeRobot free tier to keep services warm
- Total cost: $0/month

**If You Need Always-On:**
- Backend: $7/month (Starter plan)
- Frontend: Free (static sites always on)
- MongoDB Atlas: Free tier sufficient
- Total: $7/month

### Support & Resources

- [Render Documentation](https://render.com/docs)
- [Render Community](https://community.render.com)
- [MongoDB Atlas Documentation](https://docs.atlas.mongodb.com)
- [FastAPI Deployment Guide](https://fastapi.tiangolo.com/deployment/)

### Security Best Practices

1. **Never commit secrets:**
   - Add `.env` to `.gitignore`
   - Use Render's environment variables

2. **Use HTTPS:**
   - Render provides free SSL
   - Force HTTPS in production

3. **Restrict CORS:**
   - Update `allow_origins` to specific domains
   - Remove wildcard `"*"` in production

4. **Environment Variables:**
   - Store all secrets in Render dashboard
   - Never hardcode credentials

5. **MongoDB Security:**
   - Use strong passwords
   - Enable IP whitelist (0.0.0.0/0 for Render)
   - Regularly rotate credentials

### Next Steps

1. ✓ Deploy to Render
2. ✓ Configure environment variables
3. ✓ Test health endpoint
4. ✓ Test login functionality
5. Optional: Deploy smart contracts to Sepolia testnet
6. Optional: Set up custom domain
7. Optional: Configure monitoring/alerts
