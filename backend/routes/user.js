const express = require('express');
const multer = require('multer');
const authMiddleware = require('../middleware/auth');
const elevenLabsService = require('../services/elevenLabsService');
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
    const User = require('../models/User');
    
    // Check if user exists in MongoDB
    let user = await User.findByUid(req.user.uid);
    
    if (!user) {
      console.log('⚠️ User not found in MongoDB, creating from Firebase data:', req.user.uid);
      
      try {
        // Get complete user data from Firebase
        const admin = require('firebase-admin');
        const firebaseUser = await admin.auth().getUser(req.user.uid);
        
        console.log('📝 Creating user from Firebase data:', {
          uid: firebaseUser.uid,
          email: firebaseUser.email,
          displayName: firebaseUser.displayName
        });
        
        // Create new user with complete Firebase data (matching User model schema)
        user = new User({
          uid: firebaseUser.uid,
          email: firebaseUser.email || 'unknown@example.com',
          name: firebaseUser.displayName || firebaseUser.email?.split('@')[0] || 'User', // Fixed: use 'name' not 'displayName'
          photoURL: firebaseUser.photoURL || null,
          phoneNumber: firebaseUser.phoneNumber || null,
          
          // Credit system setup (matching User model fields)
          plan: 'free',
          availableCredits: 0,
          credits: 0,
          totalPurchased: 0,
          totalUsed: 0,
          totalSpent: 0,
          
          // Profile fields that exist in model
          profession: null,
          bio: null,
          country: null,
          
          // Timestamps
          createdAt: new Date(),
          updatedAt: new Date()
        });
        
        await user.save();
        console.log('✅ User created successfully from Firebase data');
        
      } catch (createError) {
        console.error('❌ Error creating user from Firebase:', createError);
        return res.status(500).json({
          error: 'Failed to create user profile',
          details: createError.message
        });
      }
    }
    
    // Update timestamp
    user.updatedAt = new Date();
    await user.save();
    
    res.json({
      success: true,
      user: {
        uid: user.uid,
        email: user.email,
        name: user.name, // Fixed: use 'name' field from model
        photoURL: user.photoURL,
        availableCredits: user.availableCredits || 0,
        credits: user.credits || 0,
        totalPurchased: user.totalPurchased || 0,
        totalUsed: user.totalUsed || 0,
        totalSpent: user.totalSpent || 0,
        plan: user.plan || 'free',
        profession: user.profession,
        bio: user.bio,
        country: user.country,
        createdAt: user.createdAt,
        updatedAt: user.updatedAt
      }
    });
    
  } catch (error) {
    console.error('❌ Error fetching/creating user profile:', error);
    res.status(500).json({
      error: 'Failed to fetch user profile',
      details: error.message
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

// Get user's credit balance
router.get('/credits', authMiddleware, async (req, res) => {
  try {
    const User = require('../models/User');
    const user = await User.findByUid(req.user.uid);
    
    if (!user) {
      return res.status(404).json({
        error: 'User not found'
      });
    }

    res.json({
      credits: user.availableCredits || user.credits || 0,
      totalPurchased: user.totalPurchased || 0,
      totalUsed: user.totalUsed || 0
    });

  } catch (error) {
    console.error('Get user credits error:', error);
    res.status(500).json({
      error: 'Failed to fetch user credits'
    });
  }
});

// Add credits to user account (after successful purchase)
router.post('/add-credits', authMiddleware, async (req, res) => {
  try {
    const { credits, planId, transactionId } = req.body;
    
    if (!credits || !planId || !transactionId) {
      return res.status(400).json({
        error: 'Missing required fields: credits, planId, transactionId'
      });
    }

    const User = require('../models/User');
    const Transaction = require('../models/Transaction');
    
    let user = await User.findByUid(req.user.uid);
    if (!user) {
      return res.status(404).json({
        error: 'User not found'
      });
    }

    // Check if transaction already exists to prevent duplicate credits
    const existingTransaction = await Transaction.findOne({ 
      transactionId: transactionId,
      userId: req.user.uid 
    });
    
    if (existingTransaction) {
      return res.status(400).json({
        error: 'Transaction already processed'
      });
    }

    // Add credits to user
    user.availableCredits = (user.availableCredits || user.credits || 0) + credits;
    user.credits = user.availableCredits; // Keep legacy field in sync
    user.totalPurchased = (user.totalPurchased || 0) + credits;
    
    // Create transaction record
    const transaction = new Transaction({
      userId: req.user.uid,
      transactionId: transactionId,
      type: 'purchase',
      amount: credits,
      creditsPurchased: credits,
      planId: planId,
      status: 'completed',
      paymentMethod: 'google_play',
      metadata: {
        purchaseType: 'in_app_purchase',
        platform: 'android'
      }
    });

    // Save both in a transaction-like operation
    await Promise.all([
      user.save(),
      transaction.save()
    ]);

    res.json({
      success: true,
      newBalance: user.availableCredits,
      creditsAdded: credits,
      transactionId: transactionId
    });

  } catch (error) {
    console.error('Add credits error:', error);
    res.status(500).json({
      error: 'Failed to add credits'
    });
  }
});

// Reserve credits for video generation (NEW FLOW)
router.post('/reserve-credits', authMiddleware, async (req, res) => {
  try {
    const { credits, videoType, durationMinutes, projectId } = req.body;
    
    if (!credits || !videoType || !projectId) {
      return res.status(400).json({
        error: 'Missing required fields: credits, videoType, projectId'
      });
    }

    const User = require('../models/User');
    let user = await User.findByUid(req.user.uid);
    
    if (!user) {
      return res.status(404).json({
        error: 'User not found'
      });
    }

    const currentCredits = user.availableCredits || user.credits || 0;
    
    if (currentCredits < credits) {
      return res.status(400).json({
        error: 'Insufficient credits',
        required: credits,
        available: currentCredits
      });
    }

    // Reserve credits (DON'T subtract from available yet - only mark as reserved)
    // Credits are only subtracted when confirmed, not during reservation
    
    // Initialize reservedCredits if not exists
    if (!user.reservedCredits) {
      user.reservedCredits = new Map();
    }
    
    // Store reservation
    user.reservedCredits.set(projectId, {
      credits: credits,
      videoType: videoType,
      durationMinutes: durationMinutes,
      reservedAt: new Date(),
      status: 'reserved'
    });
    
    console.log(`💰 Reserved ${credits} credits for project ${projectId} (NOT deducted yet)`);
    console.log(`📊 User ${user.name} still has ${currentCredits} available credits`);

    user.lastActiveAt = new Date();
    await user.save();

    console.log(`💰 Reserved ${credits} credits for project ${projectId}`);

    res.json({
      success: true,
      newBalance: currentCredits, // Balance unchanged during reservation
      reservedCredits: credits,
      reservationId: projectId
    });

  } catch (error) {
    console.error('Reserve credits error:', error);
    res.status(500).json({
      error: 'Failed to reserve credits'
    });
  }
});

// Confirm credit usage (called when video generation succeeds)
router.post('/confirm-credits', authMiddleware, async (req, res) => {
  try {
    const { projectId } = req.body;
    
    if (!projectId) {
      return res.status(400).json({
        error: 'Missing projectId'
      });
    }

    const User = require('../models/User');
    let user = await User.findByUid(req.user.uid);
    
    if (!user || !user.reservedCredits || !user.reservedCredits[projectId]) {
      return res.status(404).json({
        error: 'No credit reservation found for this project'
      });
    }

    const reservation = user.reservedCredits.get ? user.reservedCredits.get(projectId) : user.reservedCredits[projectId];
    
    if (!reservation) {
      return res.status(404).json({
        error: 'Credit reservation not found'
      });
    }
    
    // NOW subtract credits from available balance
    const currentCredits = user.availableCredits || user.credits || 0;
    user.availableCredits = currentCredits - reservation.credits;
    user.credits = user.availableCredits;
    
    // Mark credits as used
    user.totalUsed = (user.totalUsed || 0) + reservation.credits;
    user.usage.totalCreditsUsed = (user.usage.totalCreditsUsed || 0) + reservation.credits;
    
    // Remove reservation (handle both Map and object formats)
    if (user.reservedCredits.delete) {
      user.reservedCredits.delete(projectId);
    } else {
      delete user.reservedCredits[projectId];
    }
    
    user.lastActiveAt = new Date();
    await user.save();

    console.log(`✅ Confirmed ${reservation.credits} credits usage for project ${projectId}`);

    res.json({
      success: true,
      creditsUsed: reservation.credits,
      newBalance: user.availableCredits
    });

  } catch (error) {
    console.error('Confirm credits error:', error);
    res.status(500).json({
      error: 'Failed to confirm credits'
    });
  }
});

// Refund reserved credits (called when video generation fails)
router.post('/refund-credits', authMiddleware, async (req, res) => {
  try {
    const { projectId } = req.body;
    
    if (!projectId) {
      return res.status(400).json({
        error: 'Missing projectId'
      });
    }

    const User = require('../models/User');
    let user = await User.findByUid(req.user.uid);
    
    if (!user || !user.reservedCredits) {
      return res.status(404).json({
        error: 'User or reservedCredits not found'
      });
    }

    // Handle both Map and object formats for reservedCredits
    const reservation = user.reservedCredits.get ? user.reservedCredits.get(projectId) : user.reservedCredits[projectId];
    
    if (!reservation) {
      return res.status(404).json({
        error: 'No credit reservation found for this project'
      });
    }
    
    // Refund credits (since credits were never subtracted during reservation, just remove the reservation)
    // No need to add credits back - they were never taken away
    
    // Remove reservation (handle both Map and object formats)
    if (user.reservedCredits.delete) {
      user.reservedCredits.delete(projectId);
    } else {
      delete user.reservedCredits[projectId];
    }
    
    user.lastActiveAt = new Date();
    await user.save();

    console.log(`🔄 Released ${reservation.credits} credits reservation for failed project ${projectId} (credits never deducted)`);

    res.json({
      success: true,
      creditsReleased: reservation.credits,
      newBalance: user.availableCredits || user.credits || 0
    });

  } catch (error) {
    console.error('Refund credits error:', error);
    res.status(500).json({
      error: 'Failed to refund credits'
    });
  }
});

// Legacy consume credits endpoint (for backward compatibility)
router.post('/consume-credits', authMiddleware, async (req, res) => {
  try {
    const { credits, videoType, durationMinutes, projectId } = req.body;
    
    if (!credits || !videoType) {
      return res.status(400).json({
        error: 'Missing required fields: credits, videoType'
      });
    }

    const User = require('../models/User');
    let user = await User.findByUid(req.user.uid);
    
    if (!user) {
      return res.status(404).json({
        error: 'User not found'
      });
    }

    const currentCredits = user.availableCredits || user.credits || 0;
    
    if (currentCredits < credits) {
      return res.status(400).json({
        error: 'Insufficient credits',
        required: credits,
        available: currentCredits
      });
    }

    // Deduct credits
    user.availableCredits = currentCredits - credits;
    user.credits = user.availableCredits; // Keep legacy field in sync
    user.totalUsed = (user.totalUsed || 0) + credits;
    
    // Update usage stats
    user.usage.totalCreditsUsed = (user.usage.totalCreditsUsed || 0) + credits;
    user.lastActiveAt = new Date();

    await user.save();

    res.json({
      success: true,
      newBalance: user.availableCredits,
      creditsConsumed: credits
    });

  } catch (error) {
    console.error('Consume credits error:', error);
    res.status(500).json({
      error: 'Failed to consume credits'
    });
  }
});

// Get user's credit history
router.get('/credit-history', authMiddleware, async (req, res) => {
  try {
    const Transaction = require('../models/Transaction');
    
    const transactions = await Transaction.find({ 
      userId: req.user.uid 
    })
    .sort({ createdAt: -1 })
    .limit(50)
    .select('transactionId type amount creditsPurchased planId status createdAt paymentMethod metadata');

    const history = transactions.map(transaction => ({
      id: transaction._id.toString(),
      transactionId: transaction.transactionId,
      type: transaction.type,
      amount: transaction.amount,
      credits: transaction.creditsPurchased || transaction.amount,
      planId: transaction.planId,
      status: transaction.status,
      date: transaction.createdAt,
      paymentMethod: transaction.paymentMethod,
      platform: transaction.metadata?.platform || 'unknown'
    }));

    res.json({
      history: history
    });

  } catch (error) {
    console.error('Get credit history error:', error);
    res.status(500).json({
      error: 'Failed to fetch credit history'
    });
  }
});

// Get API credits and usage (legacy endpoint)
router.get('/api-credits', authMiddleware, async (req, res) => {
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

    // D-ID service removed - only using RunwayML and ElevenLabs
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
      cloudinary: 'unknown',
    };

    // Test ElevenLabs
    try {
      await elevenLabsService.getVoices();
      status.elevenLabs = 'connected';
    } catch (error) {
      status.elevenLabs = 'error';
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