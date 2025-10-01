const express = require('express');
const cloudinary = require('cloudinary').v2;
const Project = require('../models/Project');
const Avatar = require('../models/Avatar');
const elevenLabsService = require('../services/elevenLabsService');
const RunwayService = require('../services/runwayService');

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
    
    const { avatarId, title, script, duration = 5, aspectRatio = '9:16' } = req.body; // Defaults
    const userId = getUserId(req);
    
    // Validation
    if (!avatarId || !title || !script) {
      return res.status(400).json({
        error: 'Missing required fields: avatarId, title, script'
      });
    }

    // Validate duration for gen4_turbo
    if (duration !== 5 && duration !== 10) {
      return res.status(400).json({
        error: 'Duration must be 5 or 10 seconds for gen4_turbo model'
      });
    }

    if (script.length > 2000) {
      return res.status(400).json({
        error: 'Script too long. Maximum 2000 characters allowed.'
      });
    }

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

    // 3. Start async video generation
    processAvatarVideoGeneration(project._id, avatar, script, duration, aspectRatio)
      .catch(error => {
        console.error('❌ Avatar video generation error:', error);
      });

    // 4. Return immediate response
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
async function processAvatarVideoGeneration(projectId, avatar, script, duration = 5, aspectRatio = '9:16') {
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

    // Step 2: Create talking head video using RunwayML
    console.log('🎥 Step 2: Creating talking head video with RunwayML...');
    const videoResult = await generateTalkingHeadVideo(
      avatar.imageUrl,
      audioResult.audioUrl,
      projectId,
      duration,
      aspectRatio
    );

    if (!videoResult.success) {
      throw new Error(`RunwayML generation failed: ${videoResult.error}`);
    }

    console.log('✅ Avatar video generated successfully');

    // Step 3: Update project with final video
    await Project.findByIdAndUpdate(projectId, {
      status: 'completed',
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

// Helper function to generate talking head video using RunwayML
async function generateTalkingHeadVideo(imageUrl, audioUrl, projectId, duration = 5, aspectRatio = '9:16') {
  try {
    console.log('🎭 Generating talking head video...');
    console.log('📸 Image URL:', imageUrl);
    console.log('🎵 Audio URL:', audioUrl);
    console.log('⏱️ Duration:', duration, 'seconds');
    console.log('📐 Aspect Ratio:', aspectRatio);

    // Use RunwayML's image-to-video with audio
    const runwayResult = await runwayService.generateImageToVideoWithAudio({
      imageUrl,
      audioUrl,
      aspectRatio: aspectRatio, // User-selected aspect ratio
      model: 'gen4_turbo', // Official model for image-to-video
      duration: duration // Pass user-selected duration
    });

    if (!runwayResult.success) {
      return { success: false, error: runwayResult.error };
    }

    // Upload generated video to Cloudinary
    console.log('☁️ Uploading to Cloudinary...');
    const cloudinaryResult = await cloudinary.uploader.upload(runwayResult.videoUrl, {
      resource_type: 'video',
      folder: 'avatar-videos',
      public_id: `avatar_video_${projectId}_${Date.now()}`,
      overwrite: true,
      transformation: [
        { quality: 'auto:good' },
        { format: 'mp4' }
      ]
    });

    // Generate thumbnail
    const thumbnailResult = await cloudinary.uploader.upload(runwayResult.videoUrl, {
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
      duration: cloudinaryResult.duration || 8,
      fileSize: cloudinaryResult.bytes,
      width: cloudinaryResult.width,
      height: cloudinaryResult.height
    };

  } catch (error) {
    console.error('❌ Talking head video generation error:', error);
    return { success: false, error: error.message };
  }
}

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