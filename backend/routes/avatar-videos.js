const express = require('express');
const cloudinary = require('cloudinary').v2;
const Project = require('../models/Project');
const Avatar = require('../models/Avatar');
const elevenLabsService = require('../services/elevenLabsService');
const RunwayService = require('../services/runwayService');
const didService = require('../services/didService');

const router = express.Router();

// Create RunwayService instance
const runwayService = new RunwayService();

// Helper function to get user ID
const getUserId = (req) => {
  try {
    return req.user ? req.user.uid : `dev-user-${Date.now()}`;
  } catch (error) {
    return `dev-user-${Date.now()}`;
  }
};

// POST /api/avatar-videos/create - Create avatar-based video project
router.post('/create', async (req, res) => {
  try {
    console.log('🎭 === STARTING AVATAR VIDEO PROJECT CREATION ===');
    console.log('📥 Request body:', JSON.stringify(req.body, null, 2)); 
    
    const { avatarId, title, script, aspectRatio = '9:16', expression = 'neutral' } = req.body; // Defaults
    const userId = getUserId(req);
    
    // Validation
    if (!avatarId || !title || !script) {
      return res.status(400).json({
        error: 'Missing required fields: avatarId, title, script'
      });
    }

    // Validate aspect ratio for D-ID
    const supportedRatios = ['9:16', '16:9', '1:1'];
    if (!supportedRatios.includes(aspectRatio)) {
      return res.status(400).json({
        error: 'Aspect ratio must be 9:16, 16:9, or 1:1 for D-ID'
      });
    }

    if (script.length > 2000) {
      return res.status(400).json({
        error: 'Script too long. Maximum 2000 characters allowed.'
      });
    }

    // CREDIT CHECK: Calculate required credits and validate user balance
    const estimatedMinutes = Math.ceil(script.length / 150); // ~150 chars per minute
    const requiredCredits = estimatedMinutes * 40; // 40 credits per minute for avatar videos
    
    console.log('💰 Credit calculation:');
    console.log(`📝 Script length: ${script.length} characters`);
    console.log(`⏱️ Estimated duration: ${estimatedMinutes} minutes`);
    console.log(`💳 Required credits: ${requiredCredits}`);

    // Get user model and check credits
    const User = require('../models/User');
    const user = await User.findOne({ uid: userId });
    
    if (!user) {
      return res.status(404).json({
        error: 'User not found'
      });
    }

    if (user.credits < requiredCredits) {
      console.log(`❌ Insufficient credits: User has ${user.credits}, needs ${requiredCredits}`);
      return res.status(400).json({
        error: 'Insufficient credits',
        required: requiredCredits,
        current: user.credits,
        estimatedMinutes: estimatedMinutes,
        creditsPerMinute: 40
      });
    }

    console.log(`✅ Credit check passed: User has ${user.credits} credits, needs ${requiredCredits}`);

    console.log('👤 User ID:', userId);
    console.log('🎭 Avatar ID:', avatarId);

    // 1. Verify avatar exists and belongs to user
    const avatar = await Avatar.findOne({ _id: avatarId, userId });
    if (!avatar) {
      return res.status(404).json({
        error: 'Avatar not found or does not belong to user'
      });
    }

    if (avatar.status !== 'active') {
      return res.status(400).json({
        error: 'Avatar is not ready for video generation'
      });
    }

    console.log('✅ Avatar verified:', avatar.name);

    // 2. Create project record
    const project = new Project({
      userId,
      title,
      description: script,
      type: 'avatar-based',
      status: 'pending',
      avatarId: avatar._id,
      script,
      provider: 'elevenlabs-runway',
      configuration: {
        aspectRatio: '720:1280', // Default to vertical for talking heads
        resolution: 720,
        duration: 8, // Will be determined by audio length
        style: 'realistic',
        voice: avatar.voiceId,
        features: {
          withAudio: true,
          withSubtitles: false,
          withLipSync: true,
        },
      },
    });

    await project.save();
    console.log('✅ Project created:', project._id);

    // 3. Credits should already be consumed by frontend CreditSystemService
    // This is just a backup check to ensure credits are deducted
    console.log(`💳 Credits should already be consumed by frontend for ${requiredCredits} credits`);
    console.log(`📊 Avatar video generation: ${estimatedMinutes} minutes estimated`);

    // 4. Start async video generation
    processAvatarVideoGeneration(project._id, avatar, script, aspectRatio, expression)
      .catch(error => {
        console.error('❌ Avatar video generation error:', error);
      });

    // 5. Return immediate response
    res.status(201).json({
      message: 'Avatar video generation started',
      project: {
        id: project._id,
        title: project.title,
        status: project.status,
        type: project.type,
        avatarId: project.avatarId,
        estimatedTime: '60-90 seconds',
        createdAt: project.createdAt
      },
      creditsInfo: {
        consumed: requiredCredits,
        estimatedMinutes: estimatedMinutes,
        remaining: user.credits - requiredCredits
      }
    });

  } catch (error) {
    console.error('❌ Avatar video creation error:', error);
    res.status(500).json({
      error: 'Failed to create avatar video project',
      details: error.message
    });
  }
});

// Async function to process avatar video generation
async function processAvatarVideoGeneration(projectId, avatar, script, aspectRatio = '9:16', expression = 'neutral') {
  try {
    console.log('🎬 Starting avatar video processing for project:', projectId);

    // Update project status
    await Project.findByIdAndUpdate(projectId, { 
      status: 'processing',
      processingStartedAt: new Date()
    });

    // Step 1: Generate speech using ElevenLabs
    console.log('🎙️ Step 1: Generating speech with ElevenLabs...');
    const audioResult = await elevenLabsService.generateSpeech(script, avatar.voiceId);
    
    if (!audioResult.success) {
      throw new Error(`ElevenLabs generation failed: ${audioResult.error}`);
    }

    console.log('✅ Speech generated successfully');

    // Step 2: Create talking head video using D-ID
    console.log('🎥 Step 2: Creating talking head video with D-ID...');
    const videoResult = await generateTalkingHeadVideo(
      avatar.imageUrl,
      audioResult.audioUrl,
      projectId,
      aspectRatio,
      expression
    );

    if (!videoResult.success) {
      throw new Error(`D-ID talking head generation failed: ${videoResult.error}`);
    }

    console.log('✅ Avatar video generated successfully');

    // Step 3: Update project with final video
    await Project.findByIdAndUpdate(projectId, {
      status: 'completed',
      provider: 'elevenlabs-did', // D-ID + ElevenLabs combination
      taskId: videoResult.talkId, // D-ID talk ID
      videoUrl: videoResult.videoUrl,
      thumbnailUrl: videoResult.thumbnailUrl,
      processingCompletedAt: new Date(),
      actualDuration: videoResult.duration,
      fileSize: videoResult.fileSize,
      dimensions: {
        width: videoResult.width,
        height: videoResult.height
      }
    });

    console.log('🎉 Avatar video project completed:', projectId);

  } catch (error) {
    console.error('❌ Avatar video processing failed:', error);
    
    // Update project with error
    await Project.findByIdAndUpdate(projectId, {
      status: 'failed',
      errorMessage: error.message,
      processingCompletedAt: new Date()
    });
  }
}

// Helper function to generate talking head video using D-ID
async function generateTalkingHeadVideo(imageUrl, audioUrl, projectId, aspectRatio = '9:16', expression = 'neutral') {
  try {
    console.log('🎭 Generating talking head video with D-ID...');
    console.log('📸 Image URL:', imageUrl);
    console.log('🎵 Audio URL:', audioUrl);
    console.log('⏱️ Duration: Auto-detected from audio by D-ID');
    console.log('📐 Aspect Ratio:', aspectRatio);
    console.log('😊 Expression:', expression);

    // Use D-ID's talking head generation with perfect lip-sync
    const didResult = await didService.generateTalkingHead({
      imageUrl,
      audioUrl,
      aspectRatio: aspectRatio, // User-selected aspect ratio (duration auto-detected)
      expression: expression // User-selected expression
    });

    if (!didResult.success) {
      return { success: false, error: didResult.error };
    }

    // Download from D-ID and upload to Cloudinary
    console.log('☁️ Downloading from D-ID and uploading to Cloudinary...');
    const cloudinaryResult = await didService.downloadAndUploadVideo(didResult.videoUrl, projectId);

    // Generate thumbnail from the video
    const thumbnailResult = await cloudinary.uploader.upload(cloudinaryResult.secure_url, {
      resource_type: 'video',
      folder: 'avatar-thumbnails',
      public_id: `avatar_thumb_${projectId}_${Date.now()}`,
      transformation: [
        { width: 400, height: 600, crop: 'fill' },
        { quality: 'auto:good' },
        { format: 'jpg' },
        { flags: 'attachment' }
      ]
    });

    return {
      success: true,
      videoUrl: cloudinaryResult.secure_url,
      thumbnailUrl: thumbnailResult.secure_url,
      duration: didResult.duration || cloudinaryResult.duration || 8,
      fileSize: cloudinaryResult.bytes,
      width: cloudinaryResult.width,
      height: cloudinaryResult.height,
      provider: 'did', // Indicate this was generated with D-ID
      talkId: didResult.talkId // D-ID talk ID for reference
    };

  } catch (error) {
    console.error('❌ Talking head video generation error:', error);
    return { success: false, error: error.message };
  }
}

// GET /api/avatar-videos/credits - Check D-ID credits
router.get('/credits', async (req, res) => {
  try {
    const credits = await didService.getCredits();
    res.json(credits);
  } catch (error) {
    console.error('❌ Error checking D-ID credits:', error);
    res.status(500).json({ error: 'Failed to check credits' });
  }
});

// GET /api/avatar-videos/user-avatars - Get user's avatars for selection
router.get('/user-avatars', async (req, res) => {
  try {
    const userId = getUserId(req);
    
    const avatars = await Avatar.find({ 
      userId, 
      status: 'active',
      isActive: true 
    }).select('name profession gender style imageUrl voiceId createdAt');

    res.json({
      avatars,
      total: avatars.length
    });

  } catch (error) {
    console.error('❌ Error fetching user avatars:', error);
    res.status(500).json({
      error: 'Failed to fetch avatars'
    });
  }
});

// GET /api/avatar-videos/project/:id - Get avatar video project details
router.get('/project/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const userId = getUserId(req);

    const project = await Project.findOne({ _id: id, userId, type: 'avatar-based' })
      .populate('avatarId', 'name profession imageUrl voiceId');

    if (!project) {
      return res.status(404).json({
        error: 'Avatar video project not found'
      });
    }

    res.json({ project });

  } catch (error) {
    console.error('❌ Error fetching avatar video project:', error);
    res.status(500).json({
      error: 'Failed to fetch project'
    });
  }
});

module.exports = router;