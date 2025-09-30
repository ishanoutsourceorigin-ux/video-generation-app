# Complete Video Generation Setup Guide

## Overview
This guide will help you set up the complete AI video generation flow from text to video using RunwayML, with videos stored in Cloudinary and displayed in the Flutter app.

## Backend Setup

### 1. Install Dependencies
```bash
cd backend
npm run setup
```

### 2. Configure Environment Variables
Update `.env` file with your actual credentials:

```env
# Required for basic functionality
MONGODB_URI=your_mongodb_connection_string
CLOUDINARY_CLOUD_NAME=your_cloudinary_cloud_name
CLOUDINARY_API_KEY=your_cloudinary_api_key
CLOUDINARY_API_SECRET=your_cloudinary_api_secret

# Required for video generation
RUNWAY_API_KEY=your_runway_api_key

# Optional - for avatar videos
ELEVENLABS_API_KEY=your_elevenlabs_api_key
DID_API_KEY=your_did_api_key

# Firebase Admin SDK
FIREBASE_PROJECT_ID=your_project_id
FIREBASE_PRIVATE_KEY="your_private_key"
FIREBASE_CLIENT_EMAIL=your_client_email
```

### 3. Start Backend Server
```bash
npm run dev
```

The server will start on `http://localhost:5000`

## Flutter App Setup

### 1. Update API Base URL
In `lib/Services/Api/api_service.dart`, ensure the base URL points to your backend:
```dart
static const String baseUrl = 'http://10.0.2.2:5000/api'; // For Android emulator
// static const String baseUrl = 'http://localhost:5000/api'; // For web/desktop
// static const String baseUrl = 'http://YOUR_IP:5000/api'; // For physical device
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Run the App
```bash
flutter run
```

## Video Generation Flow

### Complete Process:
1. **User Input**: User creates text-based video with title, description, aspect ratio, resolution, duration
2. **API Call**: Flutter app calls `/api/projects/create-text-based`
3. **Project Creation**: Backend creates project record in MongoDB
4. **RunwayML Integration**: Backend calls RunwayML API to generate video
5. **Status Polling**: Backend polls RunwayML for completion status
6. **Cloudinary Upload**: When complete, video is uploaded to Cloudinary
7. **Database Update**: Project and Video records are updated with Cloudinary URL
8. **Frontend Display**: Flutter app shows completed video in "AI Generated Videos" screen

### API Endpoints:
- `POST /api/projects/create-text-based` - Create text-based video project
- `GET /api/projects` - Get user's projects (with filtering)
- `GET /api/projects/:id` - Get specific project details
- `DELETE /api/projects/:id` - Delete project and associated video

### Data Flow:
```
Flutter App → Backend API → RunwayML API → Video Generation
                    ↓
Database (Project) → Cloudinary Upload → Video Storage
                    ↓
Flutter App ← Backend API ← Updated Project Data
```

## Testing the Integration

### 1. Test Basic Backend
```bash
curl http://localhost:5000/health
```

### 2. Test Project Creation (with authentication)
```bash
curl -X POST http://localhost:5000/api/projects/create-text-based \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_FIREBASE_TOKEN" \
  -d '{
    "title": "Test Video",
    "description": "A beautiful sunset over mountains",
    "aspectRatio": "9:16",
    "resolution": 1080,
    "duration": 4
  }'
```

### 3. Monitor Processing
Check the backend logs to see:
- Project creation
- RunwayML API calls
- Status polling
- Cloudinary upload
- Database updates

## Development vs Production

### Development Mode
- If `RUNWAY_API_KEY` is not set, the system falls back to mock mode
- Mock videos are created with placeholder URLs
- Processing time is simulated (30 seconds max)

### Production Mode
- Real RunwayML integration
- Actual video generation (2-5 minutes)
- Videos uploaded to Cloudinary
- Full status tracking and error handling

## Error Handling

The system handles various error scenarios:
- **RunwayML API failures**: Falls back to development mode
- **Cloudinary upload failures**: Project marked as failed
- **Network timeouts**: Automatic retry with exponential backoff
- **Invalid configurations**: Validation errors returned immediately

## Database Schema

### Project Model
```javascript
{
  title: String,
  description: String,
  type: 'text-based',
  status: 'pending|processing|completed|failed',
  configuration: {
    aspectRatio: String,
    resolution: Number,
    duration: Number,
    style: String
  },
  videoUrl: String,        // Cloudinary URL
  thumbnailUrl: String,    // Generated thumbnail
  taskId: String,          // RunwayML task ID
  createdAt: Date,
  updatedAt: Date
}
```

### Video Model
```javascript
{
  title: String,
  script: String,          // Original description
  videoUrl: String,        // Cloudinary URL
  cloudinaryVideoId: String,
  status: 'completed',
  duration: Number,
  metadata: {
    type: 'text-based',
    provider: 'runway',
    aspectRatio: String,
    resolution: Number
  }
}
```

## Troubleshooting

### Common Issues:

1. **"Runway API key not configured"**
   - Add `RUNWAY_API_KEY` to your `.env` file
   - System will use mock mode if not set

2. **"Failed to upload to Cloudinary"**
   - Check Cloudinary credentials in `.env`
   - Verify account has sufficient storage quota

3. **"Video generation timed out"**
   - RunwayML can take 2-5 minutes for generation
   - Check RunwayML account credits and limits

4. **Database connection issues**
   - Verify `MONGODB_URI` is correct
   - Ensure MongoDB Atlas allows connections from your IP

5. **Firebase authentication errors**
   - Check Firebase Admin SDK configuration
   - Verify service account keys are properly formatted

## Features Implemented

✅ **Complete video generation pipeline**
✅ **Real RunwayML integration**
✅ **Cloudinary storage and CDN**
✅ **Real-time status tracking**
✅ **Error handling and retry logic**
✅ **Database persistence**
✅ **Flutter UI for video creation**
✅ **Video list and detail screens**
✅ **Project management**
✅ **Responsive design**

## Next Steps

1. **Add video download functionality**
2. **Implement video sharing features**
3. **Add payment integration for credits**
4. **Enhance video generation options**
5. **Add video editing capabilities**
6. **Implement user analytics dashboard**

This completes the full AI video generation pipeline with real RunwayML integration!