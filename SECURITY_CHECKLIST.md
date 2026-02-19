================================================================================
SECURITY CHECKLIST - BEFORE EXPOSING VIA CLOUDFLARE TUNNEL
================================================================================

Complete this checklist before making your application publicly accessible.

================================================================================
CATEGORY 1: CODE & SECRETS
================================================================================

Secrets Management:
  [ ] .env file created and NOT committed to Git
  [ ] .gitignore includes: .env, .env.local, *.key, *.pem
  [ ] No hardcoded passwords in any source code
  [ ] No hardcoded API keys in any source code
  [ ] No hardcoded MongoDB credentials in code
  [ ] All secrets loaded from environment variables

Sensitive Data:
  [ ] No JWT tokens in source code
  [ ] No private keys in source code
  [ ] No credentials in config files (unless .env which is ignored)
  [ ] No passwords in comments
  [ ] Logs don't contain sensitive information

Validation:
  [ ] Grep for "password" - should find none (except in function names)
  [ ] Grep for "secret" - should find none (except in env references)
  [ ] Grep for "mongodb+srv://" - should find NONE (only in .env or env vars)
  [ ] Grep for "apiKey" - should find NONE (except as env references)

Search commands:
    grep -r "password=" .
    grep -r "MONGO_URI=" .
    grep -r "secret_key=" .
    grep -ri "hardcoded" .

✅ Action: If found, move to .env immediately!

================================================================================
CATEGORY 2: FASTAPI BACKEND SECURITY
================================================================================

Application Configuration:
  [ ] DEBUG=false (not debug mode)
  [ ] FASTAPI_ENV=production (or similar)
  [ ] Binding to 0.0.0.0:8002 (via environment variables)
  [ ] PORT comes from environment, not hardcoded

CORS Configuration:
  [ ] CORS middleware configured
  [ ] allow_origins: specific domain (NOT ["*"])
  [ ] FRONTEND_URL set from environment
  [ ] No unnecessary HTTP methods allowed
  [ ] Credentials properly configured

Rate Limiting:
  [ ] Rate limiting middleware added
  [ ] Login endpoint: max 5 attempts/minute
  [ ] Predict endpoint: max 30 requests/minute
  [ ] General endpoints: max 100 requests/minute

Security Headers:
  [ ] X-Content-Type-Options: nosniff
  [ ] X-Frame-Options: DENY
  [ ] X-XSS-Protection: 1; mode=block
  [ ] Strict-Transport-Security: max-age=31536000
  [ ] Content-Security-Policy (if needed)

Authentication:
  [ ] /hospital_login returns JWT token
  [ ] JWT tokens have expiry (not infinite)
  [ ] /predict and other endpoints check token
  [ ] No admin endpoints exposed publicly
  [ ] No debug endpoints exposed

Input Validation:
  [ ] All endpoints use Pydantic models
  [ ] Request body validated before processing
  [ ] File uploads validated (size, type)
  [ ] Query parameters validated
  [ ] Numbers checked for reasonable ranges
  [ ] Strings checked for injection attacks

Database Security:
  [ ] MongoDB credentials in .env, not code
  [ ] TLS/SSL enabled (MongoDB Atlas)
  [ ] IP whitelist configured (if possible)
  [ ] Database user has limited permissions (read-only where needed)
  [ ] No master SQL/MongoDB credentials used

Error Handling:
  [ ] Generic error messages returned (not detailed stack traces)
  [ ] Stack traces never sent to client
  [ ] Database connection errors don't leak URLs
  [ ] Error logs contain details, API responses don't

Logging:
  [ ] Sensitive data not logged (passwords, tokens)
  [ ] Logs stored securely (not in code)
  [ ] Check logs/api.log content for secrets
  [ ] Logs rotated (don't grow infinitely)

================================================================================
CATEGORY 3: MONGODB ATLAS SECURITY
================================================================================

Database Configuration:
  [ ] MongoDB Atlas account secured
  [ ] 2FA enabled on MongoDB Atlas account
  [ ] Strong password (20+ characters, mixed case, numbers, symbols)

Network Access:
  [ ] IP Whitelist configured
      Option A: Specific IPs (most secure)
      Option B: 0.0.0.0/0 (temporary, then restrict)
  [ ] Cluster protected from public internet access
  [ ] VPN/Proxy enabled if available

Database Users:
  [ ] Created database user with strong password
  [ ] User has only necessary permissions
  [ ] Separate users for different applications (if applicable)
  [ ] Unused users deleted
  [ ] Regular password rotation considered

Encryption:
  [ ] TLS/SSL enabled (MongoDB Atlas default: yes)
  [ ] Certificate validation enabled
  [ ] At-rest encryption enabled (MongoDB Atlas default: yes)

Backup & Disaster Recovery:
  [ ] Backups enabled
  [ ] Backup retention configured (at least 7 days)
  [ ] Can restore from backup (tested)
  [ ] Backup credentials secure

Monitoring:
  [ ] MongoDB Atlas alerts configured
  [ ] Alerts for unusual access patterns
  [ ] Alerts for failed authentication
  [ ] Alerts for traffic spikes

Auditing:
  [ ] Audit logs enabled (if available)
  [ ] Admin actions logged

✅ Action: Document MongoDB Atlas setup in team wiki

================================================================================
CATEGORY 4: CLOUDFLARE TUNNEL SECURITY
================================================================================

Tunnel Configuration:
  [ ] Named tunnel created (not Quick Tunnels)
  [ ] Tunnel credentials file stored securely
  [ ] Credentials file NOT committed to Git
  [ ] config.yml properly configured
  [ ] Only necessary ports exposed (8002 for API)

DNS & Domain:
  [ ] Domain name secured
  [ ] Cloudflare nameservers configured
  [ ] CNAME record created correctly
  [ ] DNS properly propagated (nslookup verified)
  [ ] No subdomain hijacking possible

Tunnels & Routing:
  [ ] Tunnel routes only to localhost:8002
  [ ] 404 fallback configured (no directory listing)
  [ ] No unnecessary routes
  [ ] Traffic encrypted: Cloudflare ↔ Your computer

Firewall Rules:
  [ ] Windows Firewall checked (port 8002 local only)
  [ ] Port 8002 not accessible from internet (only localhost)
  [ ] Cloudflare handles incoming traffic
  [ ] Outbound: Only to Cloudflare servers

Service Installation:
  [ ] cloudflared installed as Windows service (or manual start)
  [ ] Service runs as limited user (not admin)
  [ ] Service logs monitored
  [ ] Service auto-restarts on failure

Monitoring:
  [ ] Tunnel status checked regularly
  [ ] "Connected" status verified
  [ ] Requests logged

================================================================================
CATEGORY 5: FRONTEND SECURITY
================================================================================

Environment Configuration:
  [ ] VITE_API_URL set correctly in .env.production
  [ ] No hardcoded localhost URLs in production
  [ ] Environment variables used throughout
  [ ] .env files NOT committed to Git

Build Security:
  [ ] npm audit run (check for vulnerable packages)
  [ ] npm audit fix (fix vulnerabilities)
  [ ] Source maps disabled in production build
  [ ] Console.error/log removed or minimized in production
  [ ] Build process documented

Content Security:
  [ ] Content-Security-Policy header set (if applicable)
  [ ] XSS protection enabled
  [ ] Sensitive data not stored in localStorage
  [ ] Session tokens stored securely
  [ ] Third-party scripts minimized

Client-Side Validation:
  [ ] Form inputs validated before sending
  [ ] File uploads checked (size, type)
  [ ] User input sanitized
  [ ] No SQL/NoSQL injection possible

API Communication:
  [ ] CORS headers correctly set
  [ ] HTTPS used (not HTTP)
  [ ] Credentials: true configured (if needed)
  [ ] Authorization headers sent with requests

================================================================================
CATEGORY 6: OPERATING SYSTEM & NETWORK
================================================================================

Windows System:
  [ ] Windows updates installed
  [ ] Windows Defender enabled and updated
  [ ] Unnecessary services disabled
  [ ] Firewall enabled
  [ ] Administrator account secured with strong password

Network:
  [ ] WiFi WPA2/WPA3 encryption enabled
  [ ] WiFi password strong (20+ characters)
  [ ] VPN considered for additional security
  [ ] Router firewall enabled
  [ ] Port forwarding NOT set up (Cloudflare handles this)

Port Security:
  [ ] Port 8002 only listens on localhost (127.0.0.1)
  [ ] Verification: netstat -ano | findstr :8002
      Should show: 127.0.0.1:8002 or 0.0.0.0:8002 (but no external access)
  [ ] No other services on 8002
  [ ] Other ports (3000, 8265) similarly protected

Internet Connection:
  [ ] Stable internet (or Tunnel will disconnect)
  [ ] Bandwidth sufficient for API traffic
  [ ] Data plan allows unlimited traffic (if on mobile/limited plan)
  [ ] Consider dedicated internet line for production

================================================================================
CATEGORY 7: MONITORING & INCIDENT RESPONSE
================================================================================

Logging & Monitoring:
  [ ] API logs being written to logs/api.log
  [ ] Logs reviewed regularly
  [ ] Logs contain timestamps
  [ ] Logs contain request paths (not full URLs with tokens)
  [ ] Error logs examined for security issues

Alerting:
  [ ] Alerts set up for critical errors
  [ ] Alerts for MongoDB connection failures
  [ ] Alerts for Cloudflare Tunnel disconnection
  [ ] Alert channels configured (email, Slack, etc.)

Incident Response:
  [ ] Incident response plan documented
  [ ] Know how to quickly disable Cloudflare Tunnel
  [ ] Know how to revoke compromised credentials
  [ ] Know how to change MongoDB password
  [ ] Have rollback plan

Backups:
  [ ] MongoDB data backed up
  [ ] Source code backed up (Git repository)
  [ ] Configuration backed up (.env backed up securely)
  [ ] Backup tested (can restore from backup)

================================================================================
CATEGORY 8: ACCESS CONTROL & PERMISSIONS
================================================================================

Team Access:
  [ ] Only authorized people have:
      - MongoDB Atlas login
      - Cloudflare account access
      - Source code repository access
      - .env file access
  [ ] 2FA enabled for all team accounts
  [ ] Access logs reviewed
  [ ] Unnecessary access revoked

Source Code:
  [ ] Repository private (not public)
  [ ] Only team members can access
  [ ] Commits reviewed before merging (if team)
  [ ] No credentials in commit messages

Credentials Distribution:
  [ ] .env file NOT shared via email/Slack
  [ ] Credentials shared securely (if needed at all)
  [ ] Not committed to Git (double-check)
  [ ] Rotated regularly

Admin Endpoints:
  [ ] No /admin endpoints exposed
  [ ] No /debug endpoints in production
  [ ] SQL query endpoints protected
  [ ] Database management endpoints protected

================================================================================
CATEGORY 9: RATE LIMITING & DDoS PROTECTION
================================================================================

Rate Limiting Implementation:
  [ ] /hospital_login: 5 attempts/minute
  [ ] /predict: 30 requests/minute
  [ ] Other endpoints: 100 requests/minute
  [ ] Returns 429 when rate limited

Cloudflare Protection:
  [ ] DDoS protection enabled (Cloudflare default)
  [ ] Bot Management considered
  [ ] Rate Limiting rules configured
  [ ] Security level set appropriately

Testing Rate Limits:
  [ ] Test with: for i in {1..6}; do curl http://localhost:8002/health; done
  [ ] Verify 6th request returns 429 (if using 5/min limit)
  [ ] Adjust limits based on expected load

================================================================================
CATEGORY 10: COMPLIANCE & DOCUMENTATION
================================================================================

Documentation:
  [ ] Security measures documented
  [ ] Disaster recovery plan documented
  [ ] Incident response plan documented
  [ ] Setup instructions saved (for team)
  [ ] Access credentials stored securely (1Password, LastPass, etc.)

Testing:
  [ ] Security test checklist completed
  [ ] All endpoints tested
  [ ] Error cases tested
  [ ] Rate limiting tested
  [ ] Backend/frontend communication tested

Data Privacy:
  [ ] Patient data encryption considered
  [ ] GDPR compliance checked (if applicable)
  [ ] Data retention policy defined
  [ ] Data deletion policy implemented

Compliance:
  [ ] Healthcare regulations checked (if HIPAA applicable)
  [ ] Student project restrictions understood
  [ ] Institutional guidelines followed
  [ ] Privacy policy created (if needed)

================================================================================
SECURITY SIGN-OFF CHECKLIST
================================================================================

Before making application live, FINAL checks:

Authorization:
  [ ] I have permission to expose this application publicly
  [ ] I have informed my advisors/stakeholders
  [ ] I understand the security implications

Testing:
  [ ] I have tested from external device/network
  [ ] I have verified HTTPS is enforced
  [ ] I have checked all endpoints work correctly
  [ ] I have verified CORS works as expected

Security:
  [ ] I have reviewed all items in this checklist
  [ ] I have fixed or documented all issues
  [ ] I have secured all credentials
  [ ] I have set up monitoring

Incident Response:
  [ ] I know how to quickly disable access if needed
  [ ] I have emergency contact info saved
  [ ] I understand my responsibilities
  [ ] I will monitor the application regularly

Production Readiness:
  [ ] All code is committed to Git
  [ ] No uncommitted changes
  [ ] Deploy scripts are tested
  [ ] Rollback plan documented

════════════════════════════════════════════════════════════════════════════════

SIGN-OFF:

I have reviewed all security items and confirm this application is ready
for public exposure via Cloudflare Tunnel.

Name: ________________________
Date: ________________________
Project: _____________________

════════════════════════════════════════════════════════════════════════════════

================================================================================
SECURITY INCIDENT RESPONSE
================================================================================

If you suspect a security breach:

IMMEDIATE ACTIONS (First 5 minutes):
  1. Disable Cloudflare Tunnel: cloudflared tunnel delete federated-backend
  2. Stop FastAPI: Ctrl+C in terminal or taskkill /F /IM python.exe
  3. Isolate your computer from network if critical
  4. Document what happened (screenshots, logs)
  5. Do NOT delete evidence/logs

ASSESSMENT (Next 30 minutes):
  1. Check logs for suspicious activity
  2. Review database access logs
  3. Check if credentials were exposed
  4. Review Cloudflare access logs
  5. Check if data was accessed/modified

REMEDIATION:
  1. Change MongoDB password immediately
  2. regenerate API keys/tokens
  3. Rotate all credentials
  4. Update backend code if exploit found
  5. Retest security

RE-ENABLEMENT:
  1. After fixes, recreate Cloudflare Tunnel
  2. Generate new tunnel credentials
  3. Update DNS records
  4. Configure firewall properly
  5. Restart services
  6. Test thoroughly before going live

REPORTING:
  1. Inform stakeholders immediately
  2. If student project: inform advisor
  3. If data breach: follow GDPR/privacy regulations
  4. Document incident for learning

================================================================================
RESOURCES
================================================================================

Security Guidelines:
  - OWASP Top 10: https://owasp.org/www-project-top-ten/
  - FastAPI Security: https://fastapi.tiangolo.com/tutorial/security/
  - MongoDB Security: https://docs.mongodb.com/manual/security/

Tools:
  - npm audit: Check JavaScript vulnerabilities
  - OWASP ZAP: Security testing tool
  - Burp Suite: Web app security scanner

Regular Learning:
  - Follow security best practices regularly
  - Update dependencies monthly
  - Review OWASP guidelines quarterly
  - Subscribe to security newsletters

================================================================================
FINAL THOUGHTS
================================================================================

Security is ongoing, not a one-time checklist.

Regular maintenance required:
  - Monthly: Review logs and dependencies
  - Quarterly: Update all software
  - Bi-annually: Rotate credentials
  - Annually: Security audit

Remember: A compromised student project can still:
  - Leak personal data
  - Be used to attack other systems
  - Get your institution in legal trouble
  - Damage your professional reputation

Security matters! ✅

================================================================================
