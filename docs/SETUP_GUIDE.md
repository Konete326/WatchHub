# WatchHub Setup Guide

Complete setup instructions for the WatchHub application.

## Table of Contents
1. [System Requirements](#system-requirements)
2. [Database Setup](#database-setup)
3. [Backend Setup](#backend-setup)
4. [Flutter App Setup](#flutter-app-setup)
5. [Stripe Configuration](#stripe-configuration)
6. [Troubleshooting](#troubleshooting)

## System Requirements

### Required Software
- **Node.js**: v16.0.0 or higher
- **npm**: v8.0.0 or higher
- **PostgreSQL**: v13.0 or higher
- **Flutter SDK**: v3.0.0 or higher
- **Android Studio** (for Android development)
- **Xcode** (for iOS development, macOS only)

### Recommended IDEs
- Visual Studio Code (with Flutter & Dart extensions)
- Android Studio
- Xcode (macOS)

## Database Setup

### 1. Install PostgreSQL

**Windows:**
```bash
# Download from https://www.postgresql.org/download/windows/
# Run the installer and follow the prompts
```

**macOS:**
```bash
brew install postgresql
brew services start postgresql
```

**Linux:**
```bash
sudo apt update
sudo apt install postgresql postgresql-contrib
sudo systemctl start postgresql
```

### 2. Create Database

```bash
# Access PostgreSQL
psql -U postgres

# Create database
CREATE DATABASE watchhub;

# Create user (optional)
CREATE USER watchhub_user WITH PASSWORD 'your_password';
GRANT ALL PRIVILEGES ON DATABASE watchhub TO watchhub_user;

# Exit
\q
```

### 3. Verify Connection

```bash
psql -U postgres -d watchhub -c "SELECT version();"
```

## Backend Setup

### 1. Install Dependencies

```bash
cd backend
npm install
```

### 2. Configure Environment Variables

Create `.env` file in the `backend` directory:

```env
# Database
DATABASE_URL="postgresql://postgres:password@localhost:5432/watchhub?schema=public"

# JWT
JWT_SECRET="your-super-secret-jwt-key-change-this-in-production"
JWT_EXPIRES_IN="7d"

# Stripe
STRIPE_SECRET_KEY="sk_test_your_stripe_secret_key"
STRIPE_PUBLISHABLE_KEY="pk_test_your_stripe_publishable_key"
STRIPE_WEBHOOK_SECRET="whsec_your_webhook_secret"

# Server
PORT=3000
NODE_ENV="development"

# CORS
ALLOWED_ORIGINS="http://localhost:3000,http://localhost:8080,http://10.0.2.2:3000"

# Image Upload
UPLOAD_DIR="./uploads"
MAX_FILE_SIZE=5242880
```

### 3. Run Database Migrations

```bash
npm run migrate
```

### 4. Seed Database (Optional)

```bash
npm run seed
```

This will create:
- Admin user: admin@watchhub.com / admin123
- Test user: user@watchhub.com / user123
- Sample watches and brands
- Sample FAQs

### 5. Start Backend Server

**Development mode:**
```bash
npm run dev
```

**Production mode:**
```bash
npm start
```

Verify backend is running:
```bash
curl http://localhost:3000/health
```

## Flutter App Setup

### 1. Install Flutter

Follow official guide: https://docs.flutter.dev/get-started/install

Verify installation:
```bash
flutter doctor
```

### 2. Install Dependencies

```bash
# From project root
flutter pub get
```

### 3. Configure Constants

Edit `lib/utils/constants.dart`:

```dart
class Constants {
  // For Android Emulator, use 10.0.2.2
  // For iOS Simulator, use localhost
  // For physical device, use your computer's IP address
  static const String baseUrl = 'http://10.0.2.2:3000/api';
  
  // Add your Stripe publishable key
  static const String stripePublishableKey = 'pk_test_your_key_here';
  
  // ... rest of constants
}
```

### 4. Find Your Computer's IP Address

**Windows:**
```bash
ipconfig
# Look for IPv4 Address
```

**macOS/Linux:**
```bash
ifconfig
# Look for inet address
```

### 5. Run the App

**For Android Emulator:**
```bash
flutter run
```

**For iOS Simulator:**
```bash
flutter run -d ios
```

**For Physical Device:**
- Enable USB Debugging (Android) or Developer Mode (iOS)
- Connect device via USB
```bash
flutter run
```

## Stripe Configuration

### 1. Create Stripe Account

Sign up at https://dashboard.stripe.com/register

### 2. Get API Keys

1. Go to Dashboard → Developers → API keys
2. Copy "Publishable key" and "Secret key"
3. Use test keys (starting with `pk_test_` and `sk_test_`)

### 3. Update Configuration

**Backend (.env):**
```env
STRIPE_SECRET_KEY="sk_test_your_key"
STRIPE_PUBLISHABLE_KEY="pk_test_your_key"
```

**Flutter (lib/utils/constants.dart):**
```dart
static const String stripePublishableKey = 'pk_test_your_key';
```

### 4. Test Cards

Use these test cards in development:

| Card Number | CVC | Date | Result |
|-------------|-----|------|--------|
| 4242 4242 4242 4242 | Any 3 digits | Any future date | Success |
| 4000 0000 0000 0002 | Any 3 digits | Any future date | Card Declined |

## Troubleshooting

### Backend Issues

**Port already in use:**
```bash
# Find process using port 3000
lsof -i :3000  # macOS/Linux
netstat -ano | findstr :3000  # Windows

# Kill the process
kill -9 <PID>  # macOS/Linux
taskkill /PID <PID> /F  # Windows
```

**Database connection error:**
- Verify PostgreSQL is running
- Check DATABASE_URL in .env
- Ensure database exists

**Module not found:**
```bash
rm -rf node_modules package-lock.json
npm install
```

### Flutter Issues

**Gradle build failed:**
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
```

**iOS build failed:**
```bash
cd ios
pod deintegrate
pod install
cd ..
flutter clean
flutter pub get
```

**Hot reload not working:**
```bash
flutter clean
flutter pub get
flutter run
```

**Can't connect to backend:**
- Use `10.0.2.2` for Android emulator
- Use your computer's IP for physical devices
- Ensure firewall allows connections on port 3000
- Verify backend is running

### Common Errors

**JWT Token Error:**
- Clear app data or reinstall app
- Check JWT_SECRET in backend .env

**Stripe Error:**
- Verify API keys are correct
- Use test keys in development
- Check Stripe dashboard for errors

**Image Upload Error:**
- Create `uploads` directory in backend
- Check folder permissions
- Verify MAX_FILE_SIZE in .env

## Next Steps

1. Test the application thoroughly
2. Add your own watches and products
3. Customize the theme and branding
4. Deploy to production (see DEPLOYMENT_GUIDE.md)
5. Set up monitoring and analytics

## Getting Help

- Check the [README.md](../README.md) for general information
- Review the [API documentation](../backend/README.md)
- Create an issue on GitHub
- Contact support team

---

Happy coding! 🚀

