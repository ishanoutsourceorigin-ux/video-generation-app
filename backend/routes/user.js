const express = require('express');
const multer = require('multer');
const authMiddleware = require('../middleware/auth');
const elevenLabsService = require('../services/elevenLabsService');
const didService = require('../services/didService');
const CloudinaryService = require('../services/cloudinaryService');

const router = express.Router();

// Configure multer for memory storage
const upload = multer({
  storage: multer.memoryStorage(),
  limits: {
    fileSize: 5 * 1024 * 1024, // 5MB limit for profile images
  },
  fileFilter: (req, file, cb) => {
    console.log('📁 File received:', {
      fieldname: file.fieldname,
      originalname: file.originalname,
      mimetype: file.mimetype,
      size: file.size
    });
    
    // Check file extension for image files
    const allowedExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp'];
    const fileExtension = file.originalname.toLowerCase().split('.').pop();
    const hasValidExtension = allowedExtensions.includes(`.${fileExtension}`);
    
    // Check if file is an image by mimetype OR extension
    const isImageMimetype = file.mimetype.startsWith('image/');
    const isImageFile = isImageMimetype || hasValidExtension;
    
    if (isImageFile) {
      console.log('✅ File accepted:', `mimetype: ${file.mimetype}, extension: .${fileExtension}`);
      cb(null, true);
    } else {
      console.log('❌ File rejected:', `mimetype: ${file.mimetype}, extension: .${fileExtension}`);
      cb(new Error('Only image files are allowed'), false);
    }
  },
});

// Get user account information
router.get('/profile', authMiddleware, async (req, res) => {
  try {
    const user = req.user;
    
    res.json({
      user: {
        uid: user.uid,
        email: user.email,
        name: user.name,
        picture: user.picture,
      }
    });

  } catch (error) {
    console.error('Get user profile error:', error);
    res.status(500).json({
      error: 'Failed to fetch user profile'
    });
  }
});

// Upload profile picture
router.post('/profile/upload-picture', authMiddleware, upload.single('image'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({
        error: 'No image file provided'
      });
    }

    const userId = req.user.uid;
    
    // Upload image to Cloudinary
    const imageUrl = await CloudinaryService.uploadImage(
      req.file.buffer,
      'profile_images',
      `profile_${userId}_${Date.now()}`
    );

    // Here you could save the image URL to the user's profile in your database
    // For now, just return the URL
    
    res.json({
      success: true,
      imageUrl: imageUrl,
      message: 'Profile picture uploaded successfully'
    });

  } catch (error) {
    console.error('Profile picture upload error:', error);
    
    if (error.message === 'Only image files are allowed') {
      return res.status(400).json({
        error: 'Only image files are allowed'
      });
    }
    
    if (error.message && error.message.includes('File too large')) {
      return res.status(400).json({
        error: 'File size too large. Maximum size is 5MB.'
      });
    }

    res.status(500).json({
      error: 'Failed to upload profile picture'
    });
  }
});

// Generate Cloudinary signature for frontend uploads (alternative approach)
router.get('/cloudinary/signature', authMiddleware, async (req, res) => {
  try {
    const { folder = 'profile_images' } = req.query;
    const signatureData = CloudinaryService.generateSignature({ folder });
    
    res.json({
      success: true,
      signatureData
    });

  } catch (error) {
    console.error('Cloudinary signature error:', error);
    res.status(500).json({
      error: 'Failed to generate Cloudinary signature'
    });
  }
});

// Get API credits and usage
router.get('/credits', authMiddleware, async (req, res) => {
  try {
    const credits = {};

    // Get ElevenLabs credits
    try {
      const elevenLabsData = await elevenLabsService.getUserSubscription();
      credits.elevenLabs = {
        characterCount: elevenLabsData.character_count,
        characterLimit: elevenLabsData.character_limit,
        charactersUsed: elevenLabsData.character_count,
        charactersRemaining: elevenLabsData.character_limit - elevenLabsData.character_count,
        resetDate: elevenLabsData.next_character_reset_unix,
        subscriptionStatus: elevenLabsData.status,
      };
    } catch (error) {
      console.warn('Failed to fetch ElevenLabs credits:', error.message);
      credits.elevenLabs = { error: 'Unable to fetch credits' };
    }

    // Get D-ID credits
    try {
      const didCredits = await didService.getCredits();
      credits.did = {
        remaining: didCredits.remaining,
        total: didCredits.total,
        used: didCredits.total - didCredits.remaining,
      };
    } catch (error) {
      console.warn('Failed to fetch D-ID credits:', error.message);
      credits.did = { error: 'Unable to fetch credits' };
    }

    res.json({ credits });

  } catch (error) {
    console.error('Get credits error:', error);
    res.status(500).json({
      error: 'Failed to fetch credits information'
    });
  }
});

// Get available voices from ElevenLabs
router.get('/voices', authMiddleware, async (req, res) => {
  try {
    const voicesData = await elevenLabsService.getVoices();
    
    const voices = voicesData.voices.map(voice => ({
      voiceId: voice.voice_id,
      name: voice.name,
      category: voice.category,
      description: voice.description,
      previewUrl: voice.preview_url,
      labels: voice.labels,
      settings: voice.settings,
    }));

    res.json({ voices });

  } catch (error) {
    console.error('Get voices error:', error);
    res.status(500).json({
      error: 'Failed to fetch available voices'
    });
  }
});

// Get usage statistics
router.get('/usage', authMiddleware, async (req, res) => {
  try {
    const userId = req.user.uid;
    
    // Get user's avatar and video counts from database
    const Avatar = require('../models/Avatar');
    const Video = require('../models/Video');
    
    const [avatarCount, videoCount, recentVideos] = await Promise.all([
      Avatar.countDocuments({ userId }),
      Video.countDocuments({ userId }),
      Video.find({ userId })
        .sort({ createdAt: -1 })
        .limit(5)
        .select('title status createdAt processingCompletedAt')
    ]);

    // Get completed videos count
    const completedVideos = await Video.countDocuments({ 
      userId, 
      status: 'completed' 
    });

    // Get processing videos count
    const processingVideos = await Video.countDocuments({ 
      userId, 
      status: { $in: ['queued', 'processing'] }
    });

    const usage = {
      avatars: {
        total: avatarCount,
      },
      videos: {
        total: videoCount,
        completed: completedVideos,
        processing: processingVideos,
        failed: videoCount - completedVideos - processingVideos,
      },
      recent: recentVideos.map(video => ({
        id: video._id,
        title: video.title,
        status: video.status,
        createdAt: video.createdAt,
        completedAt: video.processingCompletedAt,
      }))
    };

    res.json({ usage });

  } catch (error) {
    console.error('Get usage error:', error);
    res.status(500).json({
      error: 'Failed to fetch usage statistics'
    });
  }
});

// Update user preferences
router.put('/preferences', authMiddleware, async (req, res) => {
  try {
    const { preferences } = req.body;
    const userId = req.user.uid;

    // Here you could save user preferences to database
    // For now, just return success
    
    res.json({
      message: 'Preferences updated successfully',
      preferences
    });

  } catch (error) {
    console.error('Update preferences error:', error);
    res.status(500).json({
      error: 'Failed to update preferences'
    });
  }
});

// Test API connections
router.get('/api-status', authMiddleware, async (req, res) => {
  try {
    const status = {
      elevenLabs: 'unknown',
      did: 'unknown',
      cloudinary: 'unknown',
    };

    // Test ElevenLabs
    try {
      await elevenLabsService.getVoices();
      status.elevenLabs = 'connected';
    } catch (error) {
      status.elevenLabs = 'error';
    }

    // Test D-ID
    try {
      await didService.getCredits();
      status.did = 'connected';
    } catch (error) {
      status.did = 'error';
    }

    // Test Cloudinary (basic check)
    const cloudinary = require('cloudinary').v2;
    try {
      if (cloudinary.config().cloud_name) {
        status.cloudinary = 'connected';
      }
    } catch (error) {
      status.cloudinary = 'error';
    }

    res.json({ apiStatus: status });

  } catch (error) {
    console.error('API status check error:', error);
    res.status(500).json({
      error: 'Failed to check API status'
    });
  }
});

module.exports = router;