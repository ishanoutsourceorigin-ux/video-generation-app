# AI Avatar Video Generation App

A complete Flutter app with Node.js backend for creating AI avatars and generating lip-synced videos using ElevenLabs and Runway APIs.

## Features

- 🎭 **AI Avatar Creation**: Upload photos and voice samples to create personalized AI avatars
- 🎤 **Voice Cloning**: Clone user voices using ElevenLabs API
- 🎥 **Video Generation**: Generate lip-synced videos using Runway API
- 🔐 **Firebase Authentication**: Secure user authentication with Google Sign-In
- ☁️ **Cloudinary Storage**: Cloud storage for images, audio, and videos
- 📱 **Responsive Design**: Works on mobile and tablet devices

## Architecture

- **Frontend**: Flutter with Firebase Auth
- **Backend**: Node.js with Express
- **Database**: MongoDB Atlas
- **Storage**: Cloudinary
- **AI Services**: ElevenLabs (voice cloning) + Runway (video generation)

## Setup Instructions

### Prerequisites

- Flutter SDK (3.8.1+)
- Node.js (16+)
- MongoDB Atlas account
- Cloudinary account
- ElevenLabs API account
- Runway API account
- Firebase project

### Backend Setup

1. **Navigate to backend directory:**
   ```bash
   cd backend
   ```

2. **Install dependencies:**
   ```bash
   npm install
   ```

3. **Configure environment variables:**
   Copy `.env.example` to `.env` and update with your credentials:
   ```env
   # Server Configuration
   PORT=3000
   NODE_ENV=development
   BACKEND_URL=http://localhost:3000

   # Cloudinary Configuration
   CLOUDINARY_CLOUD_NAME=your_cloud_name
   CLOUDINARY_API_KEY=your_api_key
   CLOUDINARY_API_SECRET=your_api_secret

   # Database
   MONGODB_URI=mongodb+srv://username:password@cluster.mongodb.net/database

   # API Keys
   ELEVENLABS_API_KEY=your_elevenlabs_api_key
   RUNWAY_API_KEY=your_runway_api_key

   # Firebase Admin SDK
   FIREBASE_PROJECT_ID=your_project_id
   FIREBASE_PRIVATE_KEY_ID=your_private_key_id
   FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\\nyour_private_key\\n-----END PRIVATE KEY-----\\n"
   FIREBASE_CLIENT_EMAIL=firebase-adminsdk-xxx@your-project.iam.gserviceaccount.com
   FIREBASE_CLIENT_ID=your_client_id
   FIREBASE_AUTH_URI=https://accounts.google.com/o/oauth2/auth
   FIREBASE_TOKEN_URI=https://oauth2.googleapis.com/token
   ```

4. **Create uploads directory:**
   ```bash
   mkdir uploads
   ```

5. **Start the server:**
   ```bash
   npm run dev
   ```

### Flutter Setup

1. **Install dependencies:**
   ```bash
   flutter pub get
   ```

2. **Update API base URL:**
   Edit `lib/Services/Api/api_service.dart` and replace `your-backend-url` with your actual backend URL.

3. **Configure Firebase:**
   - Add your `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
   - Update Firebase configuration in the app

4. **Run the app:**
   ```bash
   flutter run
   ```

### Firebase Configuration

1. **Create a Firebase project**
2. **Enable Authentication with Google Sign-In**
3. **Generate service account key:**
   - Go to Project Settings > Service Accounts
   - Generate new private key
   - Use the credentials in your `.env` file

### API Keys Setup

#### ElevenLabs API
1. Sign up at [ElevenLabs](https://elevenlabs.io/)
2. Get your API key from the dashboard
3. Add to `.env` file

#### Runway API
1. Sign up at [Runway](https://runway.ml/)
2. Get your API key from the dashboard
3. Add to `.env` file

#### Cloudinary
1. Sign up at [Cloudinary](https://cloudinary.com/)
2. Get cloud name, API key, and API secret
3. Add to `.env` file

## API Endpoints

### Avatars
- `POST /api/avatars/create` - Create new avatar
- `GET /api/avatars` - Get user's avatars
- `GET /api/avatars/:id` - Get specific avatar
- `DELETE /api/avatars/:id` - Delete avatar

### Videos
- `POST /api/videos/create` - Create new video
- `GET /api/videos` - Get user's videos
- `GET /api/videos/:id` - Get specific video
- `DELETE /api/videos/:id` - Delete video
- `POST /api/videos/runway-callback` - Runway completion webhook

## Database Schema

### Avatar Collection
```javascript
{
  userId: String,           // Firebase UID
  name: String,            // Avatar name
  profession: String,       // Avatar profession
  gender: String,          // Male/Female/Other
  style: String,           // Professional/Casual/Formal/Creative
  imageUrl: String,        // Cloudinary image URL
  voiceUrl: String,        // Cloudinary voice URL
  voiceId: String,         // ElevenLabs voice ID
  status: String,          // processing/active/failed
  createdAt: Date,
  updatedAt: Date
}
```

### Video Collection
```javascript
{
  userId: String,           // Firebase UID
  avatarId: ObjectId,       // Reference to Avatar
  title: String,           // Video title
  script: String,          // Text script
  videoUrl: String,        // Cloudinary video URL
  status: String,          // queued/processing/completed/failed
  runwayTaskId: String,    // Runway API task ID
  createdAt: Date,
  updatedAt: Date
}
```

## Development Workflow

1. **Create Avatar Flow:**
   - User uploads photo and voice sample
   - Files uploaded to Cloudinary
   - Voice cloned with ElevenLabs
   - Avatar saved to database

2. **Generate Video Flow:**
   - User selects avatar and enters script
   - Text converted to speech with ElevenLabs
   - Lip-sync video generated with Runway
   - Final video uploaded to Cloudinary
   - User notified when ready

## Environment Variables Reference

```env
# Required for basic functionality
PORT=3000
MONGODB_URI=your_mongodb_connection_string
CLOUDINARY_CLOUD_NAME=your_cloudinary_cloud_name
CLOUDINARY_API_KEY=your_cloudinary_api_key
CLOUDINARY_API_SECRET=your_cloudinary_api_secret
ELEVENLABS_API_KEY=your_elevenlabs_api_key
RUNWAY_API_KEY=your_runway_api_key

# Required for authentication
FIREBASE_PROJECT_ID=your_firebase_project_id
FIREBASE_PRIVATE_KEY=your_firebase_private_key
FIREBASE_CLIENT_EMAIL=your_firebase_client_email
```

## Troubleshooting

### Common Issues

1. **Firebase Auth Issues:**
   - Ensure service account key is properly formatted
   - Check Firebase project ID matches

2. **File Upload Issues:**
   - Verify Cloudinary credentials
   - Check file size limits (10MB max)

3. **API Integration Issues:**
   - Verify ElevenLabs and Runway API keys
   - Check API rate limits

4. **Flutter Build Issues:**
   - Run `flutter clean` and `flutter pub get`
   - Check dependency versions

## Production Deployment

### Backend (Node.js)
- Deploy to services like Heroku, Railway, or DigitalOcean
- Set environment variables in production
- Configure CORS for your domain
- Set up SSL certificate

### Flutter App
- Build for release: `flutter build apk` or `flutter build ios`
- Update API base URL to production backend
- Configure app signing

## Security Considerations

- Never commit API keys to version control
- Use HTTPS in production
- Implement rate limiting
- Validate file uploads
- Sanitize user inputs

## License

This project is licensed under the MIT License.