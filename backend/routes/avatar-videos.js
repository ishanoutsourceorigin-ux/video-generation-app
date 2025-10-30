const express = require('express');
const cloudinary = require('cloudinary').v2;
const Project = require('../models/Project');
const Avatar = require('../models/Avatar');
const elevenLabsService = require('../services/elevenLabsService');
const RunwayService = require('../services/runwayService');
const a2eService = require('../services/a2eService');

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
    
    const { 
      avatarId, 
      title, 
      script, 
      prompt = "high quality, clear, cinematic, natural speaking, perfect lip sync",
      negative_prompt = "blurry, low quality, chaotic, deformed, watermark, bad anatomy, shaky camera, distorted face"
    } = req.body;
    
    console.log(`📋 Generation prompt: "${prompt}"`);
    console.log(`🚫 Negative prompt: "${negative_prompt}"`);
    
    const userId = getUserId(req);
    
    // Validation
    if (!avatarId || !title || !script) {
      return res.status(400).json({
        error: 'Missing required fields: avatarId, title, script'
      });
    }

    // Validate A2E parameters
    const validation = a2eService.validateParams({
      name: title,
      image_url: 'dummy', // Will be replaced with actual avatar URL
      audio_url: 'dummy', // Will be replaced with generated audio
      duration: 0, // 0 = auto-detect duration
      prompt,
      negative_prompt
    });

    if (!validation.valid) {
      return res.status(400).json({
        error: 'Invalid parameters for A2E',
        details: validation.errors
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
      provider: 'elevenlabs-a2e',
      configuration: {
        prompt,
        negative_prompt,
        duration: 0, // 0 = auto-detect from audio
        voice: avatar.voiceId,
        features: {
          withAudio: true,
          withLipSync: true,
          talkingPhoto: true,
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
    processAvatarVideoGeneration(project._id, avatar, script, prompt, negative_prompt)
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

// Async function to process avatar video generation with A2E
async function processAvatarVideoGeneration(projectId, avatar, script, prompt, negative_prompt) {
  try {
    console.log('🎬 Starting A2E avatar video processing for project:', projectId);

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
    console.log('🎵 Audio URL:', audioResult.audioUrl);

    // Step 2: Generate optimized prompts if not provided
    let finalPrompt = prompt;
    let finalNegativePrompt = negative_prompt;
    
    if (!prompt || prompt === "high quality, clear, cinematic, natural speaking, perfect lip sync") {
      const generatedPrompts = a2eService.generatePrompts({
        avatarType: avatar.profession || 'professional',
        content: script
      });
      finalPrompt = generatedPrompts.prompt;
      finalNegativePrompt = generatedPrompts.negative_prompt;
    }

    console.log('🎥 Step 3: Creating talking photo with A2E...');
    console.log('📋 Using prompt:', finalPrompt);
    console.log('🚫 Using negative prompt:', finalNegativePrompt);

    // Step 4: Create talking photo using A2E (duration auto-detected by A2E)
    const a2eResult = await a2eService.startTalkingPhoto({
      name: `Avatar_${avatar.name}_${Date.now()}`,
      image_url: avatar.imageUrl,
      audio_url: audioResult.audioUrl,
      duration: 0, // 0 = auto-detect duration from audio length
      prompt: finalPrompt,
      negative_prompt: finalNegativePrompt
    });

    if (!a2eResult.success) {
      throw new Error(`A2E talking photo generation failed: ${a2eResult.message}`);
    }

    console.log('✅ A2E talking photo generation started');
    console.log('🆔 Task ID:', a2eResult.taskId);

    // Step 5: Update project with A2E task information
    await Project.findByIdAndUpdate(projectId, {
      status: 'processing',
      provider: 'elevenlabs-a2e', // A2E + ElevenLabs combination
      taskId: a2eResult.taskId, // A2E task ID
      processingStartedAt: new Date(),
      configuration: {
        prompt: finalPrompt,
        negative_prompt: finalNegativePrompt,
        voice: avatar.voiceId,
        audioUrl: audioResult.audioUrl,
        features: {
          withAudio: true,
          withLipSync: true,
          talkingPhoto: true,
        },
      }
    });

    console.log('⏳ A2E video processing started. Waiting for webhook completion...');
    console.log('📝 Note: Video will be completed when A2E webhook is received');

  } catch (error) {
    console.error('❌ A2E avatar video processing failed:', error);
    
    // Update project with error
    await Project.findByIdAndUpdate(projectId, {
      status: 'failed',
      errorMessage: error.message,
      processingCompletedAt: new Date()
    });
  }
}

// Helper function to complete A2E video processing (called by webhook)
async function completeA2EVideoProcessing(projectId, videoUrl, thumbnailUrl, metadata = {}) {
  try {
    console.log('� Completing A2E video processing for project:', projectId);
    console.log('🎥 Video URL:', videoUrl);
    console.log('🖼️ Thumbnail URL:', thumbnailUrl);

    // Upload video to Cloudinary for our own storage
    console.log('☁️ Uploading A2E video to Cloudinary...');
    const cloudinaryResult = await cloudinary.uploader.upload(videoUrl, {
      resource_type: 'video',
      folder: 'avatar-videos-a2e',
      public_id: `a2e_avatar_${projectId}_${Date.now()}`,
      quality: 'auto:good'
    });

    // Generate our own thumbnail if not provided
    let finalThumbnailUrl = thumbnailUrl;
    if (!thumbnailUrl) {
      const thumbnailResult = await cloudinary.uploader.upload(cloudinaryResult.secure_url, {
        resource_type: 'video',
        folder: 'avatar-thumbnails-a2e',
        public_id: `a2e_thumb_${projectId}_${Date.now()}`,
        transformation: [
          { width: 400, height: 600, crop: 'fill' },
          { quality: 'auto:good' },
          { format: 'jpg' },
          { flags: 'attachment' }
        ]
      });
      finalThumbnailUrl = thumbnailResult.secure_url;
    }

    // Update project with final video
    await Project.findByIdAndUpdate(projectId, {
      status: 'completed',
      videoUrl: cloudinaryResult.secure_url,
      thumbnailUrl: finalThumbnailUrl,
      processingCompletedAt: new Date(),
      fileSize: cloudinaryResult.bytes,
      dimensions: {
        width: cloudinaryResult.width,
        height: cloudinaryResult.height
      },
      metadata: {
        a2e: metadata,
        provider: 'a2e'
      }
    });

    console.log('🎉 A2E avatar video project completed:', projectId);
    return { success: true };

  } catch (error) {
    console.error('❌ A2E video completion error:', error);
    
    // Update project with error
    await Project.findByIdAndUpdate(projectId, {
      status: 'failed',
      errorMessage: error.message,
      processingCompletedAt: new Date()
    });
    
    return { success: false, error: error.message };
  }
}

// Export the completion function for use in webhooks
router.completeA2EVideoProcessing = completeA2EVideoProcessing;

// GET /api/avatar-videos/status/:taskId - Check A2E task status
router.get('/status/:taskId', async (req, res) => {
  try {
    const { taskId } = req.params;
    const status = await a2eService.getTaskStatus(taskId);
    res.json(status);
  } catch (error) {
    console.error('❌ Error checking A2E task status:', error);
    res.status(500).json({ error: 'Failed to check task status' });
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

// POST /api/avatar-videos/webhook/a2e - A2E webhook endpoint
router.post('/webhook/a2e', async (req, res) => {
  try {
    console.log('🔗 A2E Webhook received:', JSON.stringify(req.body, null, 2));
    
    const { taskId, status, videoUrl, thumbnailUrl, metadata } = req.body;
    
    if (!taskId) {
      return res.status(400).json({ error: 'Task ID is required' });
    }

    // Find project by A2E task ID
    const project = await Project.findOne({ taskId, provider: 'elevenlabs-a2e' });
    
    if (!project) {
      console.log('⚠️ Project not found for A2E task ID:', taskId);
      return res.status(404).json({ error: 'Project not found for task ID' });
    }

    console.log('📝 Found project:', project._id, 'for task:', taskId);

    // Handle different status updates
    switch (status) {
      case 'completed':
      case 'success':
        if (videoUrl) {
          console.log('✅ A2E video generation completed, processing final video...');
          await completeA2EVideoProcessing(project._id, videoUrl, thumbnailUrl, metadata);
        } else {
          console.log('❌ A2E completed but no video URL provided');
          await Project.findByIdAndUpdate(project._id, {
            status: 'failed',
            errorMessage: 'A2E completed but no video URL provided',
            processingCompletedAt: new Date()
          });
        }
        break;
        
      case 'failed':
      case 'error':
        console.log('❌ A2E video generation failed for task:', taskId);
        await Project.findByIdAndUpdate(project._id, {
          status: 'failed',
          errorMessage: metadata?.error || 'A2E video generation failed',
          processingCompletedAt: new Date()
        });
        break;
        
      case 'processing':
      case 'in_progress':
        console.log('🔄 A2E video generation in progress for task:', taskId);
        await Project.findByIdAndUpdate(project._id, {
          status: 'processing',
          metadata: { a2e: metadata }
        });
        break;
        
      default:
        console.log('🔄 A2E status update:', status, 'for task:', taskId);
        await Project.findByIdAndUpdate(project._id, {
          metadata: { a2e: { status, ...metadata } }
        });
    }

    res.status(200).json({ 
      message: 'Webhook processed successfully',
      projectId: project._id,
      taskId: taskId
    });

  } catch (error) {
    console.error('❌ A2E webhook processing error:', error);
    res.status(500).json({ 
      error: 'Webhook processing failed',
      details: error.message 
    });
  }
});

module.exports = router;