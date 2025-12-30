# WatchHub Deployment Guide

Complete guide for deploying WatchHub to production.

## Table of Contents
1. [Backend Deployment](#backend-deployment)
2. [Database Deployment](#database-deployment)
3. [Flutter App Deployment](#flutter-app-deployment)
4. [Environment Configuration](#environment-configuration)
5. [Post-Deployment](#post-deployment)

## Backend Deployment

### Option 1: Railway (Recommended for beginners)

1. **Create Railway Account**
   - Visit https://railway.app
   - Sign up with GitHub

2. **Create New Project**
   ```bash
   # Install Railway CLI
   npm i -g @railway/cli
   
   # Login
   railway login
   
   # Initialize project
   railway init
   ```

3. **Add PostgreSQL Database**
   - In Railway dashboard, click "New" → "Database" → "PostgreSQL"
   - Copy the DATABASE_URL

4. **Deploy Backend**
   ```bash
   cd backend
   railway up
   ```

5. **Set Environment Variables**
   - In Railway dashboard, go to Variables
   - Add all variables from `.env`

6. **Run Migrations**
   ```bash
   railway run npm run migrate:deploy
   railway run npm run seed
   ```

### Option 2: Heroku

1. **Install Heroku CLI**
   ```bash
   brew install heroku/brew/heroku  # macOS
   # Or download from https://devcenter.heroku.com/articles/heroku-cli
   ```

2. **Login and Create App**
   ```bash
   heroku login
   cd backend
   heroku create watchhub-api
   ```

3. **Add PostgreSQL**
   ```bash
   heroku addons:create heroku-postgresql:mini
   ```

4. **Set Environment Variables**
   ```bash
   heroku config:set JWT_SECRET="your-secret"
   heroku config:set STRIPE_SECRET_KEY="sk_live_xxx"
   heroku config:set STRIPE_PUBLISHABLE_KEY="pk_live_xxx"
   heroku config:set NODE_ENV="production"
   ```

5. **Deploy**
   ```bash
   git push heroku main
   
   # Run migrations
   heroku run npm run migrate:deploy
   heroku run npm run seed
   ```

### Option 3: DigitalOcean App Platform

1. **Create Account** at https://www.digitalocean.com

2. **Create New App**
   - Connect GitHub repository
   - Select backend folder

3. **Configure Build**
   ```yaml
   build_command: npm install && npm run prisma:generate
   run_command: npm start
   ```

4. **Add PostgreSQL Database**
   - In DigitalOcean, create managed PostgreSQL database
   - Connect to app

5. **Environment Variables**
   - Add all environment variables in App Platform settings

### Option 4: AWS (Advanced)

1. **EC2 Instance Setup**
   ```bash
   # SSH into EC2 instance
   ssh -i your-key.pem ubuntu@your-ip
   
   # Install Node.js
   curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
   sudo apt-get install -y nodejs
   
   # Install PostgreSQL
   sudo apt-get install postgresql postgresql-contrib
   
   # Clone repository
   git clone your-repo
   cd backend
   npm install
   ```

2. **Setup PM2 for Process Management**
   ```bash
   npm install -g pm2
   pm2 start npm --name "watchhub-api" -- start
   pm2 startup
   pm2 save
   ```

3. **Configure Nginx**
   ```bash
   sudo apt install nginx
   
   # Create config
   sudo nano /etc/nginx/sites-available/watchhub
   ```

   ```nginx
   server {
       listen 80;
       server_name api.watchhub.com;
       
       location / {
           proxy_pass http://localhost:3000;
           proxy_http_version 1.1;
           proxy_set_header Upgrade $http_upgrade;
           proxy_set_header Connection 'upgrade';
           proxy_set_header Host $host;
           proxy_cache_bypass $http_upgrade;
       }
   }
   ```

4. **Enable Site**
   ```bash
   sudo ln -s /etc/nginx/sites-available/watchhub /etc/nginx/sites-enabled/
   sudo nginx -t
   sudo systemctl restart nginx
   ```

5. **SSL Certificate**
   ```bash
   sudo apt install certbot python3-certbot-nginx
   sudo certbot --nginx -d api.watchhub.com
   ```

## Database Deployment

### Production Database Setup

1. **Managed PostgreSQL** (Recommended)
   - **Railway**: Automatic with deployment
   - **Heroku**: Use Heroku Postgres
   - **DigitalOcean**: Managed Database
   - **AWS**: RDS PostgreSQL
   - **Google Cloud**: Cloud SQL

2. **Backup Strategy**
   ```bash
   # Automated daily backups
   pg_dump $DATABASE_URL > backup-$(date +%Y%m%d).sql
   
   # Upload to cloud storage
   aws s3 cp backup-*.sql s3://your-bucket/backups/
   ```

3. **Connection Pooling**
   - Use PgBouncer for connection pooling
   - Configure in DATABASE_URL: `?pgbouncer=true`

## Flutter App Deployment

### Android Deployment

1. **Generate Keystore**
   ```bash
   keytool -genkey -v -keystore watchhub-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias watchhub
   ```

2. **Configure Signing**
   Create `android/key.properties`:
   ```properties
   storePassword=your_store_password
   keyPassword=your_key_password
   keyAlias=watchhub
   storeFile=../watchhub-key.jks
   ```

3. **Update android/app/build.gradle**
   ```gradle
   android {
       ...
       signingConfigs {
           release {
               keyAlias keystoreProperties['keyAlias']
               keyPassword keystoreProperties['keyPassword']
               storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
               storePassword keystoreProperties['storePassword']
           }
       }
       buildTypes {
           release {
               signingConfig signingConfigs.release
           }
       }
   }
   ```

4. **Build Release**
   ```bash
   # Build APK
   flutter build apk --release
   
   # Build App Bundle (for Google Play)
   flutter build appbundle --release
   ```

5. **Google Play Store**
   - Create developer account ($25 one-time fee)
   - Upload AAB file
   - Fill in store listing
   - Set pricing and distribution
   - Submit for review

### iOS Deployment

1. **Apple Developer Account**
   - Enroll at https://developer.apple.com ($99/year)

2. **Configure Xcode**
   ```bash
   open ios/Runner.xcworkspace
   ```
   - Set Team in Signing & Capabilities
   - Update Bundle Identifier

3. **Build Release**
   ```bash
   flutter build ios --release
   ```

4. **Archive and Upload**
   - In Xcode: Product → Archive
   - Distribute App → App Store Connect
   - Upload

5. **App Store Connect**
   - Create app listing
   - Upload screenshots
   - Fill in app information
   - Submit for review

### Web Deployment (Optional)

1. **Build Web Version**
   ```bash
   flutter build web --release
   ```

2. **Deploy to Hosting**
   
   **Firebase Hosting:**
   ```bash
   npm install -g firebase-tools
   firebase login
   firebase init hosting
   firebase deploy
   ```
   
   **Netlify:**
   - Drag and drop `build/web` folder
   - Or connect GitHub repository
   
   **Vercel:**
   ```bash
   npm i -g vercel
   vercel --prod
   ```

## Environment Configuration

### Production Environment Variables

**Backend (.env.production):**
```env
DATABASE_URL="postgresql://prod_user:prod_pass@prod_host:5432/watchhub"
JWT_SECRET="super-secret-production-key-256-bit"
JWT_EXPIRES_IN="7d"
STRIPE_SECRET_KEY="sk_live_your_live_key"
STRIPE_PUBLISHABLE_KEY="pk_live_your_live_key"
STRIPE_WEBHOOK_SECRET="whsec_your_webhook_secret"
PORT=3000
NODE_ENV="production"
ALLOWED_ORIGINS="https://watchhub.com,https://www.watchhub.com"
UPLOAD_DIR="./uploads"
MAX_FILE_SIZE=5242880
```

**Flutter (lib/utils/constants.dart):**
```dart
class Constants {
  static const String baseUrl = 'https://api.watchhub.com/api';
  static const String stripePublishableKey = 'pk_live_your_live_key';
  // ... rest of constants
}
```

## Post-Deployment

### 1. Testing

- [ ] Test all API endpoints
- [ ] Test authentication flow
- [ ] Test payment processing (use live test mode first)
- [ ] Test on real devices
- [ ] Test different network conditions

### 2. Monitoring

**Backend Monitoring:**
```bash
# Install monitoring tools
npm install --save winston
npm install --save @sentry/node

# Setup in server.js
const Sentry = require("@sentry/node");
Sentry.init({ dsn: "your-sentry-dsn" });
```

**Recommended Services:**
- **Sentry**: Error tracking
- **LogRocket**: Session replay
- **New Relic**: Performance monitoring
- **Datadog**: Infrastructure monitoring

### 3. Analytics

**Flutter:**
```yaml
dependencies:
  firebase_analytics: ^10.0.0
  firebase_crashlytics: ^3.0.0
```

**Setup:**
- Google Analytics
- Firebase Crashlytics
- Mixpanel (optional)

### 4. Performance Optimization

- [ ] Enable CDN for images
- [ ] Configure caching headers
- [ ] Implement rate limiting
- [ ] Setup Redis for sessions
- [ ] Optimize database queries
- [ ] Enable GZIP compression

### 5. Security

- [ ] Enable HTTPS
- [ ] Configure CORS properly
- [ ] Implement rate limiting
- [ ] Setup security headers
- [ ] Regular security audits
- [ ] Keep dependencies updated

### 6. Backup Strategy

```bash
# Automated PostgreSQL backup script
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
pg_dump $DATABASE_URL > backup_$DATE.sql
aws s3 cp backup_$DATE.sql s3://watchhub-backups/
rm backup_$DATE.sql
```

**Schedule with cron:**
```bash
0 2 * * * /path/to/backup-script.sh
```

### 7. Documentation

- [ ] API documentation (Swagger/Postman)
- [ ] Update README with production URLs
- [ ] Create runbook for common issues
- [ ] Document deployment process

### 8. Continuous Deployment

**GitHub Actions (.github/workflows/deploy.yml):**
```yaml
name: Deploy

on:
  push:
    branches: [ main ]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Deploy to Railway
        run: |
          npm i -g @railway/cli
          railway up
        env:
          RAILWAY_TOKEN: ${{ secrets.RAILWAY_TOKEN }}
```

## Deployment Checklist

### Pre-Deployment
- [ ] All tests passing
- [ ] Code reviewed
- [ ] Documentation updated
- [ ] Environment variables configured
- [ ] SSL certificates ready
- [ ] Domain DNS configured
- [ ] Stripe account in live mode

### During Deployment
- [ ] Backend deployed
- [ ] Database migrated
- [ ] Seed data added
- [ ] Flutter app built
- [ ] App submitted to stores
- [ ] Monitoring enabled

### Post-Deployment
- [ ] Smoke tests passed
- [ ] Payment flow tested
- [ ] Error tracking confirmed
- [ ] Performance baseline established
- [ ] Team notified
- [ ] Documentation updated

## Rollback Plan

If deployment fails:

1. **Backend Rollback**
   ```bash
   # Railway
   railway rollback
   
   # Heroku
   heroku releases:rollback
   ```

2. **Database Rollback**
   ```bash
   # Restore from backup
   psql $DATABASE_URL < backup.sql
   ```

3. **App Rollback**
   - Pull previous version from stores
   - Notify users of issue

## Support Resources

- [Railway Documentation](https://docs.railway.app)
- [Heroku Documentation](https://devcenter.heroku.com)
- [Flutter Deployment](https://docs.flutter.dev/deployment)
- [Stripe Production Checklist](https://stripe.com/docs/development/checklist)

---

**Note**: Always test thoroughly in a staging environment before deploying to production. Keep backups of everything!

