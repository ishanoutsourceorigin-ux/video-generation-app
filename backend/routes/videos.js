const express = require('express');
const cloudinary = require('cloudinary').v2;
const axios = require('axios');
const fs = require('fs');

const Avatar = require('../models/Avatar');
const Video = require('../models/Video');
const elevenLabsService = require('../services/elevenLabsService');

const router = express.Router();

// Configure Cloudinary
cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET,
});

// Helper function to generate audio with ElevenLabs
const generateAudio = async (text, voiceId, options = {}) => {
  try {
    return await elevenLabsService.textToSpeech(text, voiceId, options);
  } catch (error) {
    console.error('ElevenLabs TTS error:', error);
    throw new Error('Failed to generate audio with ElevenLabs');
  }
};

// D-ID service removed - using RunwayML for all video generation

// Helper function to generate video with Runway (fallback option)
const generateVideoWithRunway = async (imageUrl, audioBuffer, duration) => {
  try {
    // First, upload audio to temporary storage
    const tempAudioPath = `uploads/temp_audio_${Date.now()}.mp3`;
    fs.writeFileSync(tempAudioPath, audioBuffer);

    // Upload audio to Cloudinary for Runway to access
    const audioUpload = await cloudinary.uploader.upload(tempAudioPath, {
      resource_type: 'video',
      folder: 'temp_audio',
    });

    // Clean up temporary file
    fs.unlinkSync(tempAudioPath);

    // Call Runway API for lip-sync video generation
    const response = await axios.post(
      'https://api.runwayml.com/v1/tasks',
      {
        task_type: 'lipsync',
        input: {
          image_url: imageUrl,
          audio_url: audioUpload.secure_url,
          duration: duration,
        },
        callback_url: `${process.env.BACKEND_URL}/api/videos/runway-callback`,
      },
      {
        headers: {
          'Authorization': `Bearer ${process.env.RUNWAY_API_KEY}`,
          'Content-Type': 'application/json',
        },
      }
    );

    // Clean up temporary audio from Cloudinary
    setTimeout(async () => {
      try {
        await cloudinary.uploader.destroy(audioUpload.public_id, { resource_type: 'video' });
      } catch (e) {
        console.error('Failed to clean up temp audio:', e);
      }
    }, 5000);

    return response.data.task_id;
  } catch (error) {
    console.error('Runway API error:', error.response?.data || error.message);
    throw new Error('Failed to generate video with Runway');
  }
};

// POST /api/videos/create-text-based - Create text-based video
router.post('/create-text-based', async (req, res) => {
  try {
    const { 
      title, 
      description, 
      style, 
      voice, 
      duration, 
      aspectRatio = '9:16',
      resolution = 1080,
      withAudio = true,
      withSubtitles = true,
      withLipSync = true,
      type = 'text-based' 
    } = req.body;
    
    // Get user ID from auth or use dev mode
    let userId;
    try {
      userId = req.user ? req.user.uid : `dev-user-${Date.now()}`;
    } catch (error) {
      userId = `dev-user-${Date.now()}`;
    }

    console.log('🎬 === STARTING TEXT-TO-VIDEO PROJECT CREATION ===');
    console.log('📥 Request body:', JSON.stringify(req.body, null, 2)); 

    // Validation
    if (!title || !description || !style || !voice || !duration) {
      return res.status(400).json({
        error: 'Missing required fields: title, description, style, voice, duration'
      });
    }

    if (description.length > 5000) {
      return res.status(400).json({
        error: 'Description is too long. Maximum 5000 characters allowed.'
      });
    }

    if (duration < 4 || duration > 60) {
      return res.status(400).json({
        error: 'Duration must be between 4 and 60 seconds.'
      });
    }

    // Validate aspect ratio
    const validAspectRatios = ['1:1', '9:16', '16:19', '3:4'];
    if (!validAspectRatios.includes(aspectRatio)) {
      return res.status(400).json({
        error: 'Invalid aspect ratio. Supported: 1:1, 9:16, 16:19, 3:4'
      });
    }

    // Validate resolution
    const validResolutions = [720, 1080];
    if (!validResolutions.includes(resolution)) {
      return res.status(400).json({
        error: 'Invalid resolution. Supported: 720, 1080'
      });
    }

    // CREDIT CHECK: Text-to-video requires 320 credits (fixed cost)
    const requiredCredits = 320; // Fixed cost for text-to-video generation
    
    console.log('💰 Credit calculation:');
    console.log(`📝 Text-to-video generation`);
    console.log(`⏱️ Duration: ${duration} seconds`);
    console.log(`💳 Required credits: ${requiredCredits}`);

    // Get user model and check credits (skip in dev mode)
    if (!userId.startsWith('dev-user-')) {
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
          videoType: 'text-to-video'
        });
      }

      console.log(`✅ Credit check passed: User has ${user.credits} credits, needs ${requiredCredits}`);
    } else {
      console.log('🔧 Dev mode: Skipping credit check');
    }

    // Create video record
    const video = new Video({
      userId,
      title,
      script: description, // Use description as script for text-based videos
      status: 'queued',
      metadata: {
        type: 'text-based',
        description,
        style,
        voice,
        duration,
        aspectRatio,
        resolution,
        withAudio,
        withSubtitles,
        withLipSync,
        estimatedDuration: duration,
        provider: 'ai-text-generator',
        videoConfig: {
          aspectRatio,
          resolution: `${resolution}p`,
          features: {
            audio: withAudio,
            subtitles: withSubtitles,
            lipSync: withLipSync,
          }
        }
      }
    });

    await video.save();

    // Consume credits for text-to-video generation (skip in dev mode)
    if (!userId.startsWith('dev-user-')) {
      try {
        const User = require('../models/User');
        await User.findOneAndUpdate(
          { uid: userId },
          { 
            $inc: { credits: -requiredCredits },
            $push: {
              creditHistory: {
                type: 'consumption',
                amount: requiredCredits,
                reason: 'text_to_video_generation',
                projectId: video._id,
                videoType: 'text-based',
                duration: duration,
                timestamp: new Date()
              }
            }
          }
        );
        console.log(`💳 Consumed ${requiredCredits} credits for text-to-video generation`);
      } catch (creditError) {
        console.error('❌ Error consuming credits:', creditError);
        // Don't fail the request, but log the error
      }
    }

    // Start async text-based video generation process
    processTextBasedVideoGeneration(video._id, { 
      title, 
      description, 
      style, 
      voice, 
      duration,
      aspectRatio,
      resolution,
      withAudio,
      withSubtitles,
      withLipSync
    });

    res.status(201).json({
      message: 'Text-based video generation started',
      video: {
        id: video._id,
        title: video.title,
        status: video.status,
        createdAt: video.createdAt,
        type: 'text-based',
        estimatedDuration: duration,
        config: {
          aspectRatio,
          resolution: `${resolution}p`,
          features: {
            audio: withAudio,
            subtitles: withSubtitles,
            lipSync: withLipSync,
          }
        }
      },
      creditsInfo: {
        consumed: requiredCredits,
        videoType: 'text-to-video',
        remaining: 'Will be updated after credit consumption'
      }
    });

  } catch (error) {
    console.error('Create text-based video error:', error);
    res.status(500).json({
      error: error.message || 'Failed to create text-based video'
    });
  }
});

// POST /api/videos/create - Create new video
router.post('/create', async (req, res) => {
  try {
    const { avatarId, title, script, provider = 'runway' } = req.body; // Default to RunwayML
    
    // Get user ID from auth or use dev mode
    let userId;
    try {
      userId = req.user ? req.user.uid : `dev-user-${Date.now()}`;
    } catch (error) {
      userId = `dev-user-${Date.now()}`;
    }

    // Validation
    if (!avatarId || !title || !script) {
      return res.status(400).json({
        error: 'Missing required fields: avatarId, title, script'
      });
    }

    if (script.length > 2000) {
      return res.status(400).json({
        error: 'Script is too long. Maximum 2000 characters allowed.'
      });
    }

    // Find and validate avatar (handle dev mode)
    let avatar;
    if (userId.startsWith('dev-user-')) {
      // In dev mode, find avatar by ID only
      avatar = await Avatar.findById(avatarId);
    } else {
      // In production, find by ID and user
      avatar = await Avatar.findOne({ _id: avatarId, userId });
    }
    
    if (!avatar) {
      return res.status(404).json({
        error: 'Avatar not found'
      });
    }

    if (avatar.status !== 'active' || !avatar.voiceId) {
      return res.status(400).json({
        error: 'Avatar is not ready for video generation'
      });
    }

    // CREDIT CHECK: Avatar video generation (40 credits per minute estimated)
    const estimatedMinutes = Math.ceil(script.length / 150); // ~150 chars per minute
    const requiredCredits = estimatedMinutes * 40; // 40 credits per minute for avatar videos
    
    console.log('💰 Credit calculation:');
    console.log(`📝 Script length: ${script.length} characters`);
    console.log(`⏱️ Estimated duration: ${estimatedMinutes} minutes`);
    console.log(`💳 Required credits: ${requiredCredits}`);

    // Get user model and check credits (skip in dev mode)
    if (!userId.startsWith('dev-user-')) {
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
    } else {
      console.log('🔧 Dev mode: Skipping credit check');
    }

    // Create video record
    const video = new Video({
      userId,
      avatarId,
      title,
      script,
      status: 'queued',
      metadata: {
        scriptLength: script.length,
        estimatedDuration: Math.ceil(script.length / 150) * 60, // Rough estimate: 150 chars per minute
        provider: provider,
      }
    });

    await video.save();

    // Consume credits for avatar video generation (skip in dev mode)
    if (!userId.startsWith('dev-user-')) {
      try {
        const User = require('../models/User');
        await User.findOneAndUpdate(
          { uid: userId },
          { 
            $inc: { credits: -requiredCredits },
            $push: {
              creditHistory: {
                type: 'consumption',
                amount: requiredCredits,
                reason: 'avatar_video_generation',
                projectId: video._id,
                estimatedMinutes: estimatedMinutes,
                timestamp: new Date()
              }
            }
          }
        );
        console.log(`💳 Consumed ${requiredCredits} credits for avatar video generation`);
      } catch (creditError) {
        console.error('❌ Error consuming credits:', creditError);
        // Don't fail the request, but log the error
      }
    }

    // Start async video generation process
    processVideoGeneration(video._id, avatar, script, provider);

    res.status(201).json({
      message: 'Video generation started',
      video: {
        id: video._id,
        title: video.title,
        status: video.status,
        createdAt: video.createdAt,
        estimatedDuration: video.metadata.estimatedDuration,
        provider: provider,
      },
      creditsInfo: {
        consumed: requiredCredits,
        estimatedMinutes: estimatedMinutes,
        remaining: 'Will be updated after credit consumption'
      }
    });

  } catch (error) {
    console.error('Create video error:', error);
    res.status(500).json({
      error: error.message || 'Failed to create video'
    });
  }
});

// Async function to handle text-based video generation
async function processTextBasedVideoGeneration(videoId, { 
  title, 
  description, 
  style, 
  voice, 
  duration, 
  aspectRatio = '9:16',
  resolution = 1080,
  withAudio = true,
  withSubtitles = true,
  withLipSync = true
}) {
  try {
    // Update status to processing
    await Video.findByIdAndUpdate(videoId, {
      status: 'processing',
      processingStartedAt: new Date(),
    });

    console.log(`Starting text-based video generation for video ${videoId}`);
    console.log(`Details: ${JSON.stringify({ 
      title, 
      style, 
      voice, 
      duration, 
      aspectRatio, 
      resolution, 
      withAudio, 
      withSubtitles, 
      withLipSync 
    })}`);

    // For demo purposes, we'll simulate AI video generation
    // In a real implementation, you would integrate with AI video generation services
    // like Runway, Stability AI, Synthesia, or other text-to-video APIs

    // Simulate processing time based on video features
    let processingTime = Math.random() * (7 - 3) + 3; // Base: 3-7 minutes
    
    // Adjust processing time based on features
    if (withLipSync) processingTime += 1; // Lip sync adds complexity
    if (withSubtitles) processingTime += 0.5; // Subtitle generation
    if (resolution === 1080) processingTime += 0.5; // Higher resolution
    
    console.log(`Estimated processing time: ${processingTime.toFixed(1)} minutes`);

    // In production, integrate with actual AI video generation service
    // For now, we'll mark the video as processing and let the real service complete it
    setTimeout(async () => {
      try {
        // This would be replaced with actual Runway ML or other service integration
        // The video should remain in 'processing' status until real generation is complete
        
        console.log(`Video ${videoId} processing - integrate with real AI service here`);
        
        // TODO: Integrate with actual AI video generation service (Runway ML, etc.)
        // The video should remain in 'processing' status until actual generation is complete
        // Remove this setTimeout in production and replace with real AI service calls
        
      } catch (error) {
        console.error(`Video processing setup failed for ${videoId}:`, error);
        
        await Video.findByIdAndUpdate(videoId, {
          status: 'failed',
          errorMessage: error.message,
          processingCompletedAt: new Date(),
        });
      }
    }, 30000); // 30 seconds for demo (in production, this would be much longer)

  } catch (error) {
    console.error(`Text-based video generation failed for video ${videoId}:`, error);

    // Update video status to failed
    await Video.findByIdAndUpdate(videoId, {
      status: 'failed',
      errorMessage: error.message,
      processingCompletedAt: new Date(),
    });
  }
}

// Async function to handle video generation
async function processVideoGeneration(videoId, avatar, script, provider = 'runway') {
  try {
    // Update status to processing
    await Video.findByIdAndUpdate(videoId, {
      status: 'processing',
      processingStartedAt: new Date(),
    });

    console.log(`Starting video generation for video ${videoId} using ${provider}`);

    // Step 1: Generate audio with ElevenLabs
    console.log('Generating audio with ElevenLabs...');
    const audioBuffer = await generateAudio(script, avatar.voiceId, {
      stability: 0.6,
      similarityBoost: 0.8,
      style: 0.2,
    });

    // Step 2: Upload audio to Cloudinary
    const tempAudioPath = `uploads/temp_${videoId}_audio.mp3`;
    fs.writeFileSync(tempAudioPath, audioBuffer);
    
    const audioUpload = await cloudinary.uploader.upload(tempAudioPath, {
      resource_type: 'video',
      folder: 'video_audio',
      public_id: `audio_${videoId}`,
    });

    // Clean up temporary file
    fs.unlinkSync(tempAudioPath);

    // Step 3: Generate video with RunwayML (only provider supported)
    let videoResult;
    if (provider === 'runway') {
      console.log('Generating video with Runway...');
      const runwayTaskId = await generateVideoWithRunway(avatar.imageUrl, audioBuffer, 30);

      // Update video with Runway task ID
      await Video.findByIdAndUpdate(videoId, {
        runwayTaskId: runwayTaskId,
      });
    }

    console.log(`Video generation initiated for ${videoId} using ${provider}`);

  } catch (error) {
    console.error(`Video generation failed for video ${videoId}:`, error);

    // Update video status to failed
    await Video.findByIdAndUpdate(videoId, {
      status: 'failed',
      errorMessage: error.message,
      processingCompletedAt: new Date(),
    });
  }
}

// POST /api/videos/runway-callback - Runway completion callback
router.post('/runway-callback', async (req, res) => {
  try {
    const { task_id, status, output_url, error_message } = req.body;

    console.log(`Runway callback received for task ${task_id}: ${status}`);

    // Find video by Runway task ID
    const video = await Video.findOne({ runwayTaskId: task_id });
    if (!video) {
      console.error(`Video not found for Runway task ${task_id}`);
      return res.status(404).json({ error: 'Video not found' });
    }

    if (status === 'completed' && output_url) {
      // Download video from Runway and upload to Cloudinary
      const videoResponse = await axios.get(output_url, { responseType: 'stream' });
      
      // Upload to Cloudinary
      const uploadResult = await new Promise((resolve, reject) => {
        const uploadStream = cloudinary.uploader.upload_stream(
          {
            resource_type: 'video',
            folder: 'generated_videos',
            use_filename: true,
          },
          (error, result) => {
            if (error) reject(error);
            else resolve(result);
          }
        );
        videoResponse.data.pipe(uploadStream);
      });

      // Update video record
      await Video.findByIdAndUpdate(video._id, {
        status: 'completed',
        videoUrl: uploadResult.secure_url,
        cloudinaryVideoId: uploadResult.public_id,
        duration: uploadResult.duration,
        fileSize: uploadResult.bytes,
        resolution: {
          width: uploadResult.width,
          height: uploadResult.height,
        },
        processingCompletedAt: new Date(),
      });

      console.log(`Video generation completed for ${video._id}`);

    } else {
      // Handle failure
      await Video.findByIdAndUpdate(video._id, {
        status: 'failed',
        errorMessage: error_message || 'Video generation failed',
        processingCompletedAt: new Date(),
      });

      console.error(`Video generation failed for ${video._id}: ${error_message}`);
    }

    res.json({ message: 'Callback processed successfully' });

  } catch (error) {
    console.error('Runway callback error:', error);
    res.status(500).json({ error: 'Failed to process callback' });
  }
});

// GET /api/videos - Get user's videos
router.get('/', async (req, res) => {
  try {
    // Get user ID from auth or use dev mode
    let userId;
    try {
      userId = req.user ? req.user.uid : null;
    } catch (error) {
      userId = null;
    }

    const { status, avatarId, limit = 20, page = 1 } = req.query;

    // Build query
    const query = {};
    
    // In development mode, return all videos
    if (!userId || userId.startsWith('dev-user-')) {
      console.log('🔧 Dev mode: returning all videos');
    } else {
      query.userId = userId;
    }

    if (status) query.status = status;
    if (avatarId) query.avatarId = avatarId;

    const skip = (parseInt(page) - 1) * parseInt(limit);

    const videos = await Video.find(query)
      .populate('avatarId', 'name profession imageUrl')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(parseInt(limit));

    const total = await Video.countDocuments(query);

    res.json({
      videos,
      pagination: {
        total,
        page: parseInt(page),
        limit: parseInt(limit),
        pages: Math.ceil(total / parseInt(limit))
      }
    });

  } catch (error) {
    console.error('Get videos error:', error);
    res.status(500).json({
      error: 'Failed to fetch videos'
    });
  }
});

// GET /api/videos/:id - Get specific video
router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    // Get user ID from auth or use dev mode
    let userId;
    try {
      userId = req.user ? req.user.uid : null;
    } catch (error) {
      userId = null;
    }

    let video;
    if (!userId || userId.startsWith('dev-user-')) {
      // In dev mode, find video by ID only
      video = await Video.findById(id).populate('avatarId', 'name profession imageUrl');
    } else {
      // In production, find by ID and user
      video = await Video.findOne({ _id: id, userId })
        .populate('avatarId', 'name profession imageUrl');
    }

    if (!video) {
      return res.status(404).json({
        error: 'Video not found'
      });
    }

    res.json({ video });

  } catch (error) {
    console.error('Get video error:', error);
    res.status(500).json({
      error: 'Failed to fetch video'
    });
  }
});

// DELETE /api/videos/:id - Delete video
router.delete('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    // Get user ID from auth or use dev mode
    let userId;
    try {
      userId = req.user ? req.user.uid : null;
    } catch (error) {
      userId = null;
    }

    let video;
    if (!userId || userId.startsWith('dev-user-')) {
      // In dev mode, find video by ID only
      video = await Video.findById(id);
    } else {
      // In production, find by ID and user
      video = await Video.findOne({ _id: id, userId });
    }

    if (!video) {
      return res.status(404).json({
        error: 'Video not found'
      });
    }

    // Delete from Cloudinary if exists
    if (video.cloudinaryVideoId) {
      try {
        await cloudinary.uploader.destroy(video.cloudinaryVideoId, { resource_type: 'video' });
      } catch (cloudinaryError) {
        console.error('Cloudinary deletion error:', cloudinaryError);
      }
    }

    // Delete from database
    await Video.findByIdAndDelete(id);

    res.json({
      message: 'Video deleted successfully'
    });

  } catch (error) {
    console.error('Delete video error:', error);
    res.status(500).json({
      error: 'Failed to delete video'
    });
  }
});

module.exports = router;