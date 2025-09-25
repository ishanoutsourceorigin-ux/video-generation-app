# 🔥 Firebase Backend Setup Guide

## Current Status
Your backend is running in **Development Mode** without Firebase credentials.

## 🚀 Quick Development Setup (Current)

Your backend will work without Firebase for testing:
- ✅ All API endpoints accessible
- ✅ Mock authentication enabled
- ✅ Profile uploads working
- ⚠️ No real user authentication (development only)

## 🔧 Production Setup (Firebase Required)

To enable real Firebase authentication:

### Step 1: Get Firebase Service Account Key

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: `video-generator-app-dc8ee`
3. Go to **Project Settings** → **Service Accounts**
4. Click **Generate New Private Key**
5. Download the JSON file

### Step 2: Extract Credentials

From the downloaded JSON file, copy these values:

```json
{
  "project_id": "video-generator-app-dc8ee",
  "private_key_id": "abc123...",
  "private_key": "-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n",
  "client_email": "firebase-adminsdk-xxx@video-generator-app-dc8ee.iam.gserviceaccount.com",
  "client_id": "123456789..."
}
```

### Step 3: Update .env File

Replace the placeholder values in `backend/.env`:

```env
FIREBASE_PROJECT_ID=video-generator-app-dc8ee
FIREBASE_PRIVATE_KEY_ID=abc123def456...
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQC...\n-----END PRIVATE KEY-----\n"
FIREBASE_CLIENT_EMAIL=firebase-adminsdk-abc123@video-generator-app-dc8ee.iam.gserviceaccount.com
FIREBASE_CLIENT_ID=123456789012345678901
```

### Step 4: Restart Backend

```bash
cd backend
npm run dev
```

## 🛡️ Security Notes

- **Development**: Mock auth allows all requests
- **Production**: Real Firebase auth required
- Keep service account keys secure
- Never commit credentials to git

## 🧪 Testing

### Development Mode (Current):
```bash
# All requests work without auth
curl http://localhost:5000/api/user/profile
```

### Production Mode (With Firebase):
```bash
# Requires valid Firebase ID token
curl -H "Authorization: Bearer <firebase-id-token>" http://localhost:5000/api/user/profile
```

## 📱 Flutter Integration

Your Flutter app will work in both modes:
- **Development**: Backend accepts all requests
- **Production**: Backend validates Firebase tokens from Flutter

No changes needed in Flutter app - it automatically sends Firebase tokens when available.