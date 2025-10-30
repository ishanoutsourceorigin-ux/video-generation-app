const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const dotenv = require('dotenv');
const multer = require('multer');
const helmet = require('helmet');
const compression = require('compression');
const rateLimit = require('express-rate-limit');
const cookieParser = require('cookie-parser');

// Load environment variables
dotenv.config();

// Import routes
const avatarRoutes = require('./routes/avatars');
const avatarVideoRoutes = require('./routes/avatar-videos');
const videoRoutes = require('./routes/videos');
const projectRoutes = require('./routes/projects');
const paymentRoutes = require('./routes/payments');
const userRoutes = require('./routes/user');
const adminRoutes = require('./routes/admin');
const authMiddleware = require('./middleware/auth');

// Import A2E completion service
const Project = require('./models/Project');
const A2ECompletionService = require('./services/a2eCompletionService');

// Initialize Express app
const app = express();
const PORT = process.env.PORT || 5000;

// A2E Auto-Completion Service Class
class A2EAutoCompletion {
  constructor(checkInterval = 30000) {
    this.checkInterval = checkInterval;
    this.intervalId = null;
    this.isRunning = false;
    this.lastLogTime = null;
    this.projectLastLogTime = new Map(); // Track per-project logging
    console.log('🤖 A2E auto-completion service initialized');
  }

  async start() {
    if (this.isRunning) {
      console.log('⚠️ Auto-completion service is already running');
      return;
    }

    console.log('🚀 Starting A2E auto-completion service...');
    console.log(`⏱️ Check interval: ${this.checkInterval / 1000} seconds`);
    
    this.isRunning = true;
    this.intervalId = setInterval(() => {
      this.checkAndCompleteVideos();
    }, this.checkInterval);

    // Initial check
    setTimeout(() => {
      this.checkAndCompleteVideos();
    }, 2000);
  }

  async checkAndCompleteVideos() {
    try {
      const processingProjects = await Project.find({
        status: 'processing',
        taskId: { $exists: true, $ne: null },
        provider: 'elevenlabs-a2e'
      }).sort({ createdAt: -1 });

      if (processingProjects.length === 0) {
        console.log('📋 No A2E videos currently in processing');
        return;
      }

      console.log(`🔍 Found ${processingProjects.length} A2E video(s) in processing status`);

      for (const project of processingProjects) {
        try {
          // Skip if already has video URL (already completed but status not updated)
          if (project.videoUrl && project.videoUrl.includes('cloudinary')) {
            console.log(`⏭️ Skipping already completed video: ${project._id}`);
            
            // Update status to completed if not already
            if (project.status !== 'completed') {
              await Project.findByIdAndUpdate(project._id, { 
                status: 'completed',
                processingCompletedAt: new Date()
              });
              console.log(`✅ Updated status to completed: ${project._id}`);
            }
            continue;
          }
          
          // Check if video has been processing for too long (over 2 hours)
          const processingTime = Date.now() - new Date(project.createdAt).getTime();
          const twoHours = 2 * 60 * 60 * 1000;
          
          if (processingTime > twoHours) {
            console.log(`⚠️ Video has been processing for ${Math.round(processingTime / (60 * 1000))} minutes`);
            console.log(`🔍 Project: ${project._id}, Task: ${project.taskId}`);
          }

          const result = await a2eCompletionService.completeA2EVideo(project.taskId, project._id);
          
          if (result.success) {
            console.log(`✅ Video completed: ${project._id}`);
            console.log(`🎥 Video URL: ${result.videoUrl}`);
            
            // Update project in database to prevent re-processing
            await Project.findByIdAndUpdate(project._id, {
              status: 'completed',
              videoUrl: result.videoUrl,
              thumbnailUrl: result.thumbnailUrl,
              processingCompletedAt: new Date(),
              actualDuration: result.actualDuration,
              errorMessage: null
            });
            console.log(`💾 Project ${project._id} updated in database`);
            
          } else if (result.message?.includes('still processing') || result.message?.includes('Status: sent')) {
            // Only log per project every 5 minutes to reduce noise
            const now = Date.now();
            const projectId = project._id.toString();
            const lastLog = this.projectLastLogTime.get(projectId) || 0;
            
            if ((now - lastLog) > 300000) { // Log every 5 minutes per project
              console.log(`⏳ Video still processing: ${project._id} (Status: ${result.status || 'sent'})`);
              console.log(`📅 Created: ${project.createdAt}`);
              this.projectLastLogTime.set(projectId, now);
            }
          } else {
            console.log(`❌ Error completing video: ${result.message}`);
          }
        } catch (error) {
          console.error(`❌ Error processing project ${project._id}:`, error.message);
        }
      }
    } catch (error) {
      console.error('❌ Error in auto-completion check:', error.message);
    }
  }

  stop() {
    if (this.intervalId) {
      clearInterval(this.intervalId);
      this.intervalId = null;
    }
    this.isRunning = false;
    console.log('🛑 A2E auto-completion service stopped');
  }
}

// Initialize services
const a2eCompletionService = new A2ECompletionService();
const autoCompletion = new A2EAutoCompletion(30000); // 30 seconds

// Configure trust proxy for deployment platforms (Render, Heroku, etc.)
app.set('trust proxy', 1);

// Security middleware
app.use(helmet({
  crossOriginEmbedderPolicy: false,
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'"],
      scriptSrc: ["'self'"],
      imgSrc: ["'self'", "data:", "https:"],
    },
  },
}));

// Rate limiting
const limiter = rateLimit({
  windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 15 * 60 * 1000, // 15 minutes
  max: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS) || 100, // limit each IP to 100 requests per windowMs
  message: {
    error: 'Too many requests from this IP, please try again later.',
  },
  standardHeaders: true,
  legacyHeaders: false,
});

app.use('/api/', limiter);

// CORS configuration
const corsOptions = {
  origin: function (origin, callback) {
    const allowedOrigins = [
      process.env.FRONTEND_URL,
      process.env.CORS_ORIGIN,
      'http://localhost:3000',
      'http://localhost:3001', // Admin panel on port 3001
      'http://localhost:5000',
      'http://localhost:8080',
      'https://video-generation-app-dar3.onrender.com',
      'https://video-generation-app-seven.vercel.app',
      // Admin panel domains
      'https://videogen-admin.vercel.app',
      'https://clonex-adminpanel.vercel.app',
      'https://videogen-admin-panel.vercel.app', 
      // Flutter app CORS access
      'http://localhost:8080', // Flutter web dev
      'http://10.0.2.2:5000', // Android emulator access to host
    ].filter(Boolean);
    
    // Allow all origins for mobile app development
    if (!origin) {
      // This allows mobile apps and other non-browser clients
      callback(null, true);
      return;
    }
    
    // console.log('🌐 CORS Request Origin:', origin);
    // console.log('✅ Allowed Origins:', allowedOrigins);
    
    if (allowedOrigins.includes(origin)) {
      // console.log('✅ CORS: Origin allowed');
      callback(null, true);
    } else {
      console.log('❌ CORS: Origin not allowed');
      callback(new Error('Not allowed by CORS'));
    }
  },
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With'],
};

app.use(cors(corsOptions));

// Middleware
app.use(compression());
app.use(cookieParser());
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ extended: true, limit: '50mb' }));

// Configure multer for file uploads
const upload = multer({
  dest: process.env.UPLOAD_DIR || 'uploads/',
  limits: {
    fileSize: parseInt(process.env.MAX_FILE_SIZE) || 50 * 1024 * 1024, // 50MB limit
  },
});

// MongoDB Connection
mongoose.connect(process.env.MONGODB_URI, {
  useNewUrlParser: true,
  useUnifiedTopology: true,
})
.then(() => {
  console.log('Connected to MongoDB Atlas');
  
  // Start A2E auto-completion service after database connection
  setTimeout(() => {
    autoCompletion.start();
  }, 3000); // Wait 3 seconds to ensure everything is initialized
})
.catch((error) => {
  console.error('MongoDB connection error:', error);
  process.exit(1);
});

// Routes
app.get('/', (req, res) => {
  res.json({ 
    message: 'AI Avatar Video Generation Backend',
    version: '1.0.0',
    status: 'running',
    environment: process.env.NODE_ENV,
    timestamp: new Date().toISOString()
  });
});

// API Routes
app.use('/api/avatars', authMiddleware, avatarRoutes);
app.use('/api/avatar-videos', authMiddleware, avatarVideoRoutes); // New avatar video generation
app.use('/api/videos', authMiddleware, videoRoutes);
app.use('/api/projects', authMiddleware, projectRoutes);
app.use('/api/payments', paymentRoutes); // Some payment routes may not need auth
app.use('/api/user', userRoutes); // User routes include auth middleware where needed
app.use('/api/admin', adminRoutes); // Admin routes with built-in auth

// Health check endpoint
app.get('/health', (req, res) => {
  const admin = require('firebase-admin');
  
  res.json({ 
    status: 'OK', 
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    memory: process.memoryUsage(),
    environment: process.env.NODE_ENV,
    configuration: {
      developmentMode: process.env.DEVELOPMENT_MODE === 'true',
      firebaseConfigured: admin.apps.length > 0,
      cloudinaryConfigured: !!(process.env.CLOUDINARY_CLOUD_NAME && process.env.CLOUDINARY_API_KEY),
      elevenLabsConfigured: !!process.env.ELEVENLABS_API_KEY,
      didConfigured: !!process.env.DID_API_KEY,
      port: process.env.PORT || 5000,
    }
  });
});

// API health endpoint for admin
app.get('/api/health', (req, res) => {
  res.json({
    status: 'online',
    message: 'API is running',
    timestamp: new Date().toISOString(),
    version: '1.0.0'
  });
});

// API info endpoint
app.get('/api', (req, res) => {
  res.json({
    name: 'Video Generation API',
    version: '1.0.0',
    endpoints: {
      avatars: '/api/avatars',
      videos: '/api/videos',
      projects: '/api/projects',
      payments: '/api/payments',
      health: '/health'
    },
    documentation: 'See README.md for API documentation'
  });
});

// Error handling middleware
app.use((error, req, res, next) => {
  console.error('Error:', error);
  res.status(error.status || 500).json({
    error: error.message || 'Internal Server Error',
    ...(process.env.NODE_ENV === 'development' && { stack: error.stack })
  });
});

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({ error: 'Route not found' });
});

// Start server
const server = app.listen(PORT, () => {
  console.log(`🚀 Server running on port ${PORT}`);
  console.log(`📱 Environment: ${process.env.NODE_ENV}`);
  console.log(`🔗 Health check: http://localhost:${PORT}/health`);
});

// Graceful shutdown handling
process.on('SIGINT', () => {
  console.log('\n🛑 Received SIGINT, shutting down gracefully...');
  autoCompletion.stop();
  server.close(() => {
    console.log('✅ Server closed');
    mongoose.connection.close(false, () => {
      console.log('✅ MongoDB connection closed');
      process.exit(0);
    });
  });
});

process.on('SIGTERM', () => {
  console.log('🛑 Received SIGTERM, shutting down gracefully...');
  autoCompletion.stop();
  server.close(() => {
    console.log('✅ Server closed');
    mongoose.connection.close(false, () => {
      console.log('✅ MongoDB connection closed');
      process.exit(0);
    });
  });
});

module.exports = app;