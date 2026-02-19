================================================================================
CLOUDFLARE TUNNEL SETUP - COMPLETE GUIDE FOR WINDOWS
================================================================================

Expose your FastAPI backend publicly using Cloudflare Tunnel
No Azure/Render deployment needed. Runs from your laptop!

================================================================================
PART 1: INSTALL CLOUDFLARED ON WINDOWS
================================================================================

Step 1.1: Download Installer
─────────────────────────────

1. Go to: https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/downloads/
2. Download: "Cloudflared installer for Windows 64-bit"
3. File: cloudflared-windows-amd64.msi

Step 1.2: Install
─────────────────

1. Double-click cloudflared-windows-amd64.msi
2. Complete installation wizard
3. Default install location: C:\Program Files (x86)\Cloudflare\Cloudflared

Step 1.3: Verify Installation
──────────────────────────────

Open PowerShell and run:

    cloudflared --version

Should see: cloudflared version X.X.X

If "cloudflared not found", restart PowerShell after installation.

================================================================================
PART 2: AUTHENTICATE WITH CLOUDFLARE
================================================================================

Step 2.1: Get Your Cloudflare Account
──────────────────────────────────────

Prerequisites:
  ✓ Cloudflare account (free at https://dash.cloudflare.com/sign-up)
  ✓ Domain name (can use free domain via Cloudflare nameservers)
  ✓ Your domain must use Cloudflare nameservers

Step 2.2: Authenticate Cloudflared
───────────────────────────────────

Run in PowerShell (as Administrator):

    cloudflared login

This will:
  1. Open your browser
  2. Ask you to choose which domain to authenticate
  3. Generate credentials file

Credentials saved to:
    C:\Users\YOURUSERNAME\.cloudflared\cert.pem

✅ You're authenticated!

================================================================================
PART 3: CREATE NAMED TUNNEL
================================================================================

Step 3.1: Create Tunnel
───────────────────────

Run in PowerShell:

    cloudflared tunnel create federated-backend

Output example:
    Tunnel credentials written to: C:\Users\YOURUSERNAME\.cloudflared\TUNNEL_ID.json
    Tunnel ID: abc123def456ghi789
    Tunnel name: federated-backend

Save your Tunnel ID - you'll need it!

Step 3.2: Verify Tunnel Created
────────────────────────────────

List all tunnels:

    cloudflared tunnel list

Should show:
    ID                    NAME
    abc123def456ghi789    federated-backend


================================================================================
PART 4: CREATE TUNNEL CONFIGURATION
================================================================================

Step 4.1: Create config.yml
────────────────────────────

Create file: %USERPROFILE%\.cloudflared\config.yml

Content (update YOUR_TUNNEL_ID and YOUR_DOMAIN):

────────────────────────────────────────────────────────────
tunnel: YOUR_TUNNEL_ID
credentials-file: %USERPROFILE%\.cloudflared\YOUR_TUNNEL_ID.json

ingress:
  - hostname: api.YOUR_DOMAIN.com
    service: http://localhost:8002
    
  - service: http_status:404
────────────────────────────────────────────────────────────

Example (if your domain is "mylab.com" and tunnel ID is "abc123"):

────────────────────────────────────────────────────────────
tunnel: abc123def456ghi789
credentials-file: C:\Users\bhavi\.cloudflared\abc123def456ghi789.json

ingress:
  - hostname: api.mylab.com
    service: http://localhost:8002
    
  - service: http_status:404
────────────────────────────────────────────────────────────

Step 4.2: What Each Line Means
────────────────────────────────

tunnel: YOUR_TUNNEL_ID
  → Your tunnel's unique ID from step 3.1

credentials-file: C:\Users\...\.cloudflared\TUNNEL_ID.json
  → Path to your credentials file (auto-created during tunnel creation)

hostname: api.YOUR_DOMAIN.com
  → Public URL users will access your API on

service: http://localhost:8002
  → Where cloudflared forwards traffic (your local FastAPI)

service: http_status:404
  → Returns 404 for any other hostnames

================================================================================
PART 5: CONFIGURE CLOUDFLARE DNS
================================================================================

Step 5.1: Create CNAME Record
──────────────────────────────

1. Go to: https://dash.cloudflare.com
2. Select your domain
3. Go to DNS → Records
4. Click "Add record"
5. Fill in:

    Type: CNAME
    Name: api
    Content: YOUR_TUNNEL_ID.cfargotunnel.com
    TTL: Auto
    Proxy status: Proxied (orange cloud icon)

6. Click Save

Example:
    api    CNAME    abc123def456ghi789.cfargotunnel.com    Proxied

Step 5.2: Test DNS
──────────────────

Wait 1-2 minutes for DNS to propagate, then:

    nslookup api.YOUR_DOMAIN.com

Should resolve to 104.18.x.x (Cloudflare IP)

================================================================================
PART 6: RUN CLOUDFLARE TUNNEL
================================================================================

Step 6.1: Test the Tunnel
──────────────────────────

Run in PowerShell:

    cloudflared tunnel run federated-backend

Or with config file:

    cloudflared tunnel --config $env:USERPROFILE\.cloudflared\config.yml run federated-backend

Output example (you should see):

    2026-02-19 12:34:56 INF Tunnel registered with ID: abc123def456ghi789
    2026-02-19 12:34:57 INF Starting metrics server on: http://127.0.0.1:26786/metrics
    2026-02-19 12:34:57 INF START Constructing ingress rule
    2026-02-19 12:34:58 INF Tunnel running successfully

✅ Your tunnel is active!

Step 6.2: Test Access
─────────────────────

From another computer or phone, visit:

    https://api.YOUR_DOMAIN.com/health

Should return:

    {"status": "healthy", "mongodb_connected": true, ...}

✅ It's working!

Step 6.3: Stop the Tunnel
──────────────────────────

Press Ctrl+C in PowerShell

================================================================================
PART 7: MAKE TUNNEL PERSISTENT (AUTO-START)
================================================================================

Step 7.1: Install as Windows Service
─────────────────────────────────────

Run PowerShell as Administrator:

    cloudflared service install

Verifies and installs. Then:

    cloudflared service start

To check status:

    Get-Service cloudflared

Should show "Running"

Step 7.2: Verify Service Starts on Computer Reboot
────────────────────────────────────────────────────

1. Right-click "This PC" → Properties
2. Advanced system settings
3. Environment Variables
4. User variables → New
5. Variable name: CLOUDFLARED_CONFIG
   Variable value: C:\Users\YOURUSERNAME\.cloudflared\config.yml
6. OK → OK → Restart computer

Service will auto-start! ✅

Step 7.3: Check Service Logs
─────────────────────────────

PowerShell:

    Get-EventLog -LogName Application -Source cloudflared | Select-Object -Last 10

Or install and run custom script (see CLOUDFLARE_SERVICE_MONITOR.ps1)

================================================================================
PART 8: TROUBLESHOOTING
================================================================================

Error: "The specified tunnel does not exist"
───────────────────────────────────────────────

Solution:
  1. Verify tunnel ID in config.yml matches: cloudflared tunnel list
  2. Verify credentials file path exists
  3. Recreate tunnel:
     cloudflared tunnel delete federated-backend
     cloudflared tunnel create federated-backend

Error: "DNS CNAME record not propagating"
────────────────────────────────────────────

Solution:
  1. Wait 5 minutes
  2. Try: nslookup api.YOUR_DOMAIN.com 1.1.1.1
  3. Clear cache: ipconfig /flushdns
  4. Verify CNAME in Cloudflare dashboard
  5. Try accessing via https://api.YOUR_DOMAIN.com

Error: "Cannot access api.domain.com"
──────────────────────────────────────

Solution:
  1. Verify tunnel is running: cloudflared tunnel list
  2. Verify FastAPI backend is running on port 8002: curl http://localhost:8002/health
  3. Check firewall allows port 8002 (localhost only is fine)
  4. Check tunnel logs: cloudflared tunnel info federated-backend
  5. Look for errors in cloudflared terminal output

Error: "Tunnel keeps disconnecting"
───────────────────────────────────────

Solution:
  1. Check internet connection
  2. Update drivers, especially network
  3. Increase Tunnel timeout in config.yml:
     
     tunnel: YOUR_TUNNEL_ID
     credentials-file: ...
     ingress:
       - hostname: api.YOUR_DOMAIN.com
         service: http://localhost:8002
     
     # Add this:
     origin-request-ca-pool: /etc/ssl/certs/ca-certificates.crt
     transport:
       tcp:
         keepalives: 30s
         idle-timeout: 90s
     
  4. Run service instead of manual tunnel

Error: "502 Bad Gateway"
────────────────────────

Solution (FastAPI not responding):
  1. Verify FastAPI backend is running: curl http://localhost:8002
  2. Check if port changed from 8002
  3. Look at FastAPI terminal for errors
  4. Verify no firewall blocking localhost:8002
  5. Check using /health endpoint: curl http://localhost:8002/health

================================================================================
PART 9: FIREWALL CONFIGURATION
================================================================================

Windows Firewall Setup
──────────────────────

The tunnel only connects OUTBOUND from your laptop to Cloudflare servers.
No need to open inbound ports on your firewall!

However, if you want to be explicit:

Windows Defender Firewall:
  1. Search: Windows Defender Firewall with Advanced Security
  2. Inbound Rules → New Rule
  3. Port → TCP → Local port 8002
  4. Allow → All → Finish
  5. Create similar rules for:
     - Flower server port (8265)
     - Any other local services

Cloudflare Firewall Rules:
  1. Dashboard → Domain → Security → WAF → Firewall Rules
  2. Create rule: (cf.threat_score > 50)
     Action: Block
  3. Protects your API from basic attacks

================================================================================
PART 10: VERIFY TUNNEL IS ACTIVE
================================================================================

Method 1: Cloudflare Dashboard
──────────────────────────────

1. https://dash.cloudflare.com
2. Select domain
3. Caching → Purge Everything (optional)
4. DNS → Records → Check your CNAME is green (Proxied)
5. Status should show tunnel connected

Method 2: Command Line
──────────────────────

    cloudflared tunnel info federated-backend

Shows:
  - ID
  - Name
  - Status
  - Created date
  - Recently connected at: TIMESTAMP ✅ (means it's active)

Method 3: Test Access
──────────────────────

From any device with internet:

    curl https://api.YOUR_DOMAIN.com/health

Or visit in browser:

    https://api.YOUR_DOMAIN.com/health (in browser)
    https://api.YOUR_DOMAIN.com/docs (see API documentation!)

Should return 200 OK ✅

Method 4: Monitor Real-Time
─────────────────────────────

Running tunnel in terminal shows real-time requests:

    2026-02-19 12:45:30 INF 200 GET /health
    2026-02-19 12:45:35 INF 200 POST /hospital_login

================================================================================
SUMMARY - COMPLETE SETUP
================================================================================

✅ Installed cloudflared
✅ Authenticated with Cloudflare
✅ Created named tunnel: federated-backend
✅ Created config.yml
✅ Created DNS CNAME record
✅ Tunnel runs and exposes FastAPI publicly
✅ Accessible via: https://api.YOUR_DOMAIN.com
✅ Auto-starts as Windows service

Your laptop is now your server! 🚀

================================================================================
QUICK REFERENCE COMMANDS
================================================================================

# Install and authenticate
cloudflared login

# Create tunnel
cloudflared tunnel create federated-backend

# List tunnels
cloudflared tunnel list

# Run tunnel manually
cloudflared tunnel run federated-backend

# Install as Windows service
cloudflared service install
cloudflared service start

# Check service status
Get-Service cloudflared

# View tunnel info
cloudflared tunnel info federated-backend

# Stop service
cloudflared service stop

# Uninstall service
cloudflared service uninstall

# Delete tunnel
cloudflared tunnel delete federated-backend

# Update cloudflared
cloudflared update

================================================================================
NEXT STEPS
================================================================================

1. ✅ Complete setup (you are here)
2. See: CLOUDFLARE_TUNNEL_STARTUP.bat (auto-start script)
3. See: BACKEND_PRODUCTION_CONFIG.md (harden FastAPI)
4. See: FRONTEND_CONFIG.md (update React environment)
5. See: SECURITY_CHECKLIST.md (before exposing publicly!)

Your backend is now publicly accessible! 🎉
================================================================================
