const express = require('express');
const cloudinary = require('cloudinary').v2;
const axios = require('axios');
const fetch = require('node-fetch'); // Add this for streaming

const Project = require('../models/Project');
const Video = require('../models/Video');
const Avatar = require('../models/Avatar');
const RunwayService = require('../services/runwayService');
const elevenLabsService = require('../services/elevenLabsService');

// Create RunwayService instance
const runwayService = new RunwayService();

const router = express.Router();

// Configure Cloudinary with enhanced settings
cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET,
  secure: true,
  // Add configuration to handle timestamp issues
  sign_url: true,
  long_url_signature: true
});

// Helper function to get user ID
const getUserId = (req) => {
  try {
    return req.user ? req.user.uid : `dev-user-${Date.now()}`;
  } catch (error) {
    return `dev-user-${Date.now()}`;
  }
};

// Helper function to normalize aspect ratio
const normalizeAspectRatio = (aspectRatio) => {
  const ratioMap = {
    '16:9': '1280:720',
    '9:16': '720:1280',
    '1:1': '1:1', // Keep square format as is
    '1280:720': '1280:720',
    '720:1280': '720:1280'
  };
  
  const normalized = ratioMap[aspectRatio] || '720:1280';
  console.log(`📐 Normalized aspect ratio: ${aspectRatio} -> ${normalized}`);
  return normalized;
};

// POST /api/projects/create-text-based - Create text-based video project
router.post('/create-text-based', async (req, res) => {
  try {
    console.log('🎬 === STARTING TEXT-BASED VIDEO PROJECT CREATION ===');
    console.log('📥 Request body:', JSON.stringify(req.body, null, 2));
    
    // Handle both direct values and nested configuration
    let title, description, aspectRatio, resolution, duration, model, veo3Config;
    
    if (req.body.configuration) {
      // Frontend sent nested configuration
      title = req.body.title;
      description = req.body.description;
      aspectRatio = normalizeAspectRatio(req.body.configuration.aspectRatio || '9:16');
      resolution = parseInt(req.body.configuration.resolution) || 1080;
      duration = parseInt(req.body.configuration.duration) || 8;
      model = req.body.model || 'veo3';
      veo3Config = req.body.veo3Config;
    } else {
      // Direct values in body
      const destructured = req.body;
      title = destructured.title;
      description = destructured.description;
      aspectRatio = normalizeAspectRatio(destructured.aspectRatio || '9:16');
      resolution = destructured.resolution || 1080;
      duration = destructured.duration || 8;
      model = destructured.model || 'veo3';
      veo3Config = destructured.veo3Config;
    }

    const userId = getUserId(req);
    console.log('👤 User ID:', userId);

    // VEO-3 specific validation
    if (model === 'veo-3' || veo3Config) {
      console.log('🎯 VEO-3 model detected - applying VEO-3 validations');
      
      // VEO-3 requires exactly 8 seconds duration
      console.log(`⚠️ VEO-3 Duration: Adjusting from ${duration}s to 8s (VEO-3 requirement)`);
      duration = 8; // Force duration to 8 for VEO-3

      // Ensure VEO-3 compatible settings
      resolution = 720; // VEO-3 uses 720p
      
      console.log('✅ VEO-3 settings applied:', { duration, resolution });
    }

    // Validation
    console.log('✅ Validating input parameters...');
    if (!title || !description) {
      console.log('❌ Validation failed: Missing required fields');
      return res.status(400).json({
        error: 'Missing required fields: title, description'
      });
    }

    if (description.length > 5000) {
      console.log('❌ Validation failed: Description too long');
      return res.status(400).json({
        error: 'Description is too long. Maximum 5000 characters allowed.'
      });
    }

    if (duration < 1 || duration > 60) {
      console.log('❌ Validation failed: Invalid duration');
      return res.status(400).json({
        error: 'Duration must be between 1 and 60 seconds (8 seconds max for VEO-3).'
      });
    }

    // Validate aspect ratio (VEO-3 supported ratios only)
    const validAspectRatios = ['1280:720', '720:1280']; // VEO-3 specific ratios
    if (!validAspectRatios.includes(aspectRatio)) {
      console.log('❌ Validation failed: Invalid aspect ratio');
      return res.status(400).json({
        error: 'Invalid aspect ratio. VEO-3 supports: 1280:720 (Landscape), 720:1280 (Vertical)'
      });
    }

    // Validate resolution
    const validResolutions = [720, 1080];
    if (!validResolutions.includes(resolution)) {
      console.log('❌ Validation failed: Invalid resolution');
      return res.status(400).json({
        error: 'Invalid resolution. Supported: 720, 1080'
      });
    }
    
    console.log('✅ All validations passed');
    console.log('📋 Project config:', { title, description, aspectRatio, resolution, duration, model });

    // Create project
    console.log('💾 Creating project in database...');
    const project = new Project({
      userId,
      title,
      description,
      type: 'text-based',
      status: 'pending',
      configuration: {
        aspectRatio,
        resolution,
        duration,
        model: model || 'veo3',
        veo3Config: veo3Config || null,
      },
      provider: 'runway',
    });

    await project.save();
    console.log('✅ Project created with ID:', project._id);

    // Start async video generation
    console.log('🚀 Starting async video generation process...');
    processTextBasedVideoGeneration(project._id, {
      title,
      description,
      aspectRatio,
      resolution,
      duration,
      model: model || 'veo3',
      veo3Config,
    });

    console.log('📤 Sending response to client...');
    res.status(201).json({
      message: `Text-based video project created successfully with ${model || 'VEO-3'} model`,
      project: {
        id: project._id,
        title: project.title,
        description: project.description,
        status: project.status,
        type: project.type,
        configuration: project.configuration,
        createdAt: project.createdAt,
        estimatedCompletionTime: project.estimatedCompletionTime,
      }
    });

  } catch (error) {
    console.error('Create text-based project error:', error);
    res.status(500).json({
      error: error.message || 'Failed to create text-based video project'
    });
  }
});

// POST /api/projects/create-avatar-based - Create avatar-based video project
router.post('/create-avatar-based', async (req, res) => {
  try {
    const {
      title,
      script,
      avatarId,
      aspectRatio = '9:16',
      resolution = 1080,
      duration,
      style = 'professional',
      provider = 'runway',
    } = req.body;

    const userId = getUserId(req);

    // Validation
    if (!title || !script || !avatarId) {
      return res.status(400).json({
        error: 'Missing required fields: title, script, avatarId'
      });
    }

    if (script.length > 2000) {
      return res.status(400).json({
        error: 'Script is too long. Maximum 2000 characters allowed.'
      });
    }

    // Find and validate avatar
    let avatar;
    if (userId.startsWith('dev-user-')) {
      avatar = await Avatar.findById(avatarId);
    } else {
      avatar = await Avatar.findOne({ _id: avatarId, userId });
    }

    if (!avatar) {
      return res.status(404).json({
        error: 'Avatar not found'
      });
    }

    if (avatar.status !== 'active') {
      return res.status(400).json({
        error: 'Avatar is not ready for video generation'
      });
    }

    // Estimate duration based on script length (if not provided)
    const estimatedDuration = duration || Math.ceil(script.length / 150) * 60; // 150 chars per minute

    // Create project
    const project = new Project({
      userId,
      title,
      description: `Avatar video with script: ${script.substring(0, 100)}...`,
      script,
      type: 'avatar-based',
      status: 'pending',
      avatarId,
      configuration: {
        aspectRatio,
        resolution,
        duration: estimatedDuration,
        style,
        features: {
          withAudio: true,
          withSubtitles: true,
          withLipSync: true,
        },
      },
      provider,
    });

    await project.save();

    // Start async avatar video generation
    processAvatarBasedVideoGeneration(project._id, avatar, script, provider);

    res.status(201).json({
      message: 'Avatar-based video project created successfully',
      project: {
        id: project._id,
        title: project.title,
        script: project.script,
        status: project.status,
        type: project.type,
        avatar: {
          id: avatar._id,
          name: avatar.name,
          profession: avatar.profession,
          imageUrl: avatar.imageUrl,
        },
        configuration: project.configuration,
        createdAt: project.createdAt,
        estimatedCompletionTime: project.estimatedCompletionTime,
      }
    });

  } catch (error) {
    console.error('Create avatar-based project error:', error);
    res.status(500).json({
      error: error.message || 'Failed to create avatar-based video project'
    });
  }
});

// GET /api/projects - Get user's projects
router.get('/', async (req, res) => {
  try {
    const userId = getUserId(req);
    const {
      status,
      type,
      limit = 20,
      page = 1,
      sort = 'createdAt',
      order = 'desc'
    } = req.query;

    // Build query
    const query = {};
    
    if (!userId.startsWith('dev-user-')) {
      query.userId = userId;
    }

    if (status) query.status = status;
    if (type) query.type = type;

    const skip = (parseInt(page) - 1) * parseInt(limit);
    const sortOrder = order === 'desc' ? -1 : 1;

    const projects = await Project.find(query)
      .populate('avatarId', 'name profession imageUrl')
      .populate('videoId')
      .sort({ [sort]: sortOrder })
      .skip(skip)
      .limit(parseInt(limit));

    const total = await Project.countDocuments(query);

    // Add computed fields
    const projectsWithDetails = projects.map(project => ({
      ...project.toJSON(),
      processingTime: project.processingTime,
      estimatedTimeRemaining: project.estimatedTimeRemaining,
    }));

    res.json({
      projects: projectsWithDetails,
      pagination: {
        total,
        page: parseInt(page),
        limit: parseInt(limit),
        pages: Math.ceil(total / parseInt(limit))
      }
    });

  } catch (error) {
    console.error('Get projects error:', error);
    res.status(500).json({
      error: 'Failed to fetch projects'
    });
  }
});

// GET /api/projects/stats - Get user's project statistics
router.get('/stats', async (req, res) => {
  try {
    const userId = getUserId(req);

    let stats;
    if (userId.startsWith('dev-user-')) {
      // Dev mode: get stats for all projects
      stats = await Project.aggregate([
        {
          $group: {
            _id: null,
            totalProjects: { $sum: 1 },
            completedProjects: { $sum: { $cond: [{ $eq: ['$status', 'completed'] }, 1, 0] } },
            processingProjects: { $sum: { $cond: [{ $eq: ['$status', 'processing'] }, 1, 0] } },
            failedProjects: { $sum: { $cond: [{ $eq: ['$status', 'failed'] }, 1, 0] } },
            textBasedProjects: { $sum: { $cond: [{ $eq: ['$type', 'text-based'] }, 1, 0] } },
            avatarBasedProjects: { $sum: { $cond: [{ $eq: ['$type', 'avatar-based'] }, 1, 0] } },
            totalViews: { $sum: '$viewCount' },
            totalDownloads: { $sum: '$downloadCount' },
            avgDuration: { $avg: '$configuration.duration' },
          }
        }
      ]);
    } else {
      stats = await Project.getStats(userId);
    }

    const result = stats[0] || {
      totalProjects: 0,
      completedProjects: 0,
      processingProjects: 0,
      failedProjects: 0,
      textBasedProjects: 0,
      avatarBasedProjects: 0,
      totalViews: 0,
      totalDownloads: 0,
      avgDuration: 0,
    };

    res.json({
      stats: result
    });

  } catch (error) {
    console.error('Get project stats error:', error);
    res.status(500).json({
      error: 'Failed to fetch project statistics'
    });
  }
});

// GET /api/projects/:id - Get specific project
router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const userId = getUserId(req);

    let project;
    if (userId.startsWith('dev-user-')) {
      project = await Project.findById(id)
        .populate('avatarId', 'name profession imageUrl voiceId')
        .populate('videoId');
    } else {
      project = await Project.findOne({ _id: id, userId })
        .populate('avatarId', 'name profession imageUrl voiceId')
        .populate('videoId');
    }

    if (!project) {
      return res.status(404).json({
        error: 'Project not found'
      });
    }

    // Increment view count
    await project.incrementView();

    const projectData = {
      ...project.toJSON(),
      processingTime: project.processingTime,
      estimatedTimeRemaining: project.estimatedTimeRemaining,
    };

    res.json({ project: projectData });

  } catch (error) {
    console.error('Get project error:', error);
    res.status(500).json({
      error: 'Failed to fetch project'
    });
  }
});

// PUT /api/projects/:id - Update project
router.put('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const userId = getUserId(req);
    const updates = req.body;

    let project;
    if (userId.startsWith('dev-user-')) {
      project = await Project.findById(id);
    } else {
      project = await Project.findOne({ _id: id, userId });
    }

    if (!project) {
      return res.status(404).json({
        error: 'Project not found'
      });
    }

    // Prevent updating certain fields if project is processing or completed
    if (project.status === 'processing' || project.status === 'completed') {
      const allowedUpdates = ['title', 'tags', 'isPublic'];
      Object.keys(updates).forEach(key => {
        if (!allowedUpdates.includes(key)) {
          delete updates[key];
        }
      });
    }

    Object.assign(project, updates);
    await project.save();

    res.json({
      message: 'Project updated successfully',
      project
    });

  } catch (error) {
    console.error('Update project error:', error);
    res.status(500).json({
      error: 'Failed to update project'
    });
  }
});

// DELETE /api/projects/:id - Delete project
router.delete('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const userId = getUserId(req);

    let project;
    if (userId.startsWith('dev-user-')) {
      project = await Project.findById(id);
    } else {
      project = await Project.findOne({ _id: id, userId });
    }

    if (!project) {
      return res.status(404).json({
        error: 'Project not found'
      });
    }

    // Cancel ongoing processing if exists
    if (project.status === 'processing' && project.taskId) {
      try {
        if (project.provider === 'runway') {
          await runwayService.cancelTask(project.taskId);
        }
        // Add other provider cancellations here
      } catch (error) {
        console.error('Failed to cancel task:', error);
      }
    }

    // Delete associated video and Cloudinary assets
    if (project.videoId) {
      const video = await Video.findById(project.videoId);
      if (video) {
        // Delete from Cloudinary
        if (video.cloudinaryVideoId) {
          try {
            await cloudinary.uploader.destroy(video.cloudinaryVideoId, { resource_type: 'video' });
          } catch (error) {
            console.error('Cloudinary deletion error:', error);
          }
        }
        
        // Delete video record
        await Video.findByIdAndDelete(project.videoId);
      }
    }

    // Delete project
    await Project.findByIdAndDelete(id);

    res.json({
      message: 'Project deleted successfully'
    });

  } catch (error) {
    console.error('Delete project error:', error);
    res.status(500).json({
      error: 'Failed to delete project'
    });
  }
});

// POST /api/projects/:id/retry - Retry failed project
router.post('/:id/retry', async (req, res) => {
  try {
    const { id } = req.params;
    const userId = getUserId(req);

    let project;
    if (userId.startsWith('dev-user-')) {
      project = await Project.findById(id).populate('avatarId');
    } else {
      project = await Project.findOne({ _id: id, userId }).populate('avatarId');
    }

    if (!project) {
      return res.status(404).json({
        error: 'Project not found'
      });
    }

    if (project.status !== 'failed') {
      return res.status(400).json({
        error: 'Only failed projects can be retried'
      });
    }

    if (project.retryCount >= 3) {
      return res.status(400).json({
        error: 'Maximum retry attempts reached'
      });
    }

    // Increment retry count and reset status
    await project.incrementRetry();
    project.status = 'pending';
    project.errorMessage = null;
    project.processingStartedAt = null;
    project.processingCompletedAt = null;
    project.estimatedCompletionTime = null;
    
    await project.save();

    // Restart processing based on project type
    if (project.type === 'text-based') {
      processTextBasedVideoGeneration(project._id, {
        title: project.title,
        description: project.description,
        ...project.configuration,
      });
    } else if (project.type === 'avatar-based' && project.avatarId) {
      processAvatarBasedVideoGeneration(
        project._id, 
        project.avatarId, 
        project.script, 
        project.provider
      );
    }

    res.json({
      message: 'Project retry initiated',
      project
    });

  } catch (error) {
    console.error('Retry project error:', error);
    res.status(500).json({
      error: 'Failed to retry project'
    });
  }
});

// Async function to handle text-based video generation
async function processTextBasedVideoGeneration(projectId, config) {
  try {
    console.log('🎥 === STARTING VIDEO GENERATION PROCESS ===');
    console.log('📋 Project ID:', projectId);
    console.log('🔧 Config:', JSON.stringify(config, null, 2));
    
    const project = await Project.findById(projectId);
    if (!project) {
      console.error(`❌ Project not found: ${projectId}`);
      return;
    }
    
    console.log('✅ Project found in database');
    console.log('👤 User ID:', project.userId);
    console.log('📝 Project title:', project.title);

    console.log('🔄 Updating project status to processing...');
    await project.updateStatus('processing');
    console.log('✅ Project status updated to processing');

    console.log(`🎬 Starting ${config.model || 'VEO-3'} video generation for project ${projectId}`);
    console.log('🔑 Checking RunwayML API availability...');
    
    // Check if RunwayML API key is configured
    if (!process.env.RUNWAY_API_KEY) {
      console.error('❌ RUNWAY_API_KEY not configured in environment variables');
      throw new Error('RunwayML API key not configured. Please set RUNWAY_API_KEY environment variable.');
    }
    console.log('✅ RunwayML API key found');

    // Check if this is a VEO-3 specific request
    if (config.model === 'veo-3' || config.veo3Config) {
      console.log('🎯 VEO-3 specific generation detected');
      
      const veo3Config = config.veo3Config || {};
      const promptText = veo3Config.promptText || config.description;
      const ratio = veo3Config.ratio || (config.aspectRatio === '9:16' ? '720:1280' : '1280:720');
      const seed = veo3Config.seed || Math.floor(Math.random() * 1000000);
      
      try {
        console.log('🌐 Calling VEO-3 specific API...');
        const veo3Result = await runwayService.generateVeo3Video(
          promptText,
          config.duration,
          ratio,
          seed
        );

        console.log(`🚀 VEO-3 API response received!`);
        console.log(`📋 Task ID: ${veo3Result.id}`);

        // Update project with task ID
        console.log('💾 Updating project with VEO-3 task ID...');
        await project.updateStatus('processing', {
          taskId: veo3Result.id,
          provider: 'runway-veo3'
        });
        console.log('✅ Project updated with VEO-3 task ID');

        // Start polling for completion
        console.log('🔄 Starting VEO-3 task polling...');
        pollRunwayTask(projectId, veo3Result.id);

      } catch (veo3Error) {
        console.error(`❌ VEO-3 API error:`, veo3Error);
        throw veo3Error;
      }

    } else {
      // Use standard text-based video generation
      console.log('🎨 Enhancing prompt for better AI generation...');
      const enhancedPrompt = runwayService.enhancePrompt(config.description);

      console.log(`📝 Original prompt: "${config.description}"`);
      console.log(`📝 Enhanced prompt: "${enhancedPrompt}"`);
      console.log(`⚙️ Video config: ${config.aspectRatio}, ${config.resolution}p, ${config.duration}s`);

      try {
        console.log('🌐 Calling RunwayML API...');
        // Use real RunwayML API
        const runwayResult = await runwayService.generateTextBasedVideo({
          prompt: enhancedPrompt,
          duration: parseInt(config.duration),
          aspectRatio: config.aspectRatio,
          resolution: parseInt(config.resolution),
          motion: 'medium'
        });

        console.log(`🚀 RunwayML API response received!`);
        console.log(`📋 Task ID: ${runwayResult.taskId}`);
        console.log(`⏱️ Estimated processing time: ${runwayResult.estimatedTime || 'Unknown'}`);

        // Update project with task ID
        console.log('💾 Updating project with task ID...');
        await project.updateStatus('processing', {
          taskId: runwayResult.taskId,
          provider: 'runway'
        });
        console.log('✅ Project updated with task ID');

        // Start polling for completion
        console.log('🔄 Starting task polling...');
        pollRunwayTask(projectId, runwayResult.taskId);

      } catch (runwayError) {
        console.error(`❌ Runway API error:`, runwayError);
        console.error(`❌ Error details:`, runwayError.message);
        console.error(`❌ Error stack:`, runwayError.stack);
        
        // Fail immediately if RunwayML API fails - no fallback to mock
        throw new Error(`RunwayML API failed: ${runwayError.message}`);
      }
    }

  } catch (error) {
    console.error(`Text-based video generation failed for project ${projectId}:`, error);
    
    const project = await Project.findById(projectId);
    if (project) {
      await project.updateStatus('failed', {
        errorMessage: error.message,
      });
    }
  }
}

// Async function to handle avatar-based video generation
async function processAvatarBasedVideoGeneration(projectId, avatar, script, provider = 'runway') {
  try {
    const project = await Project.findById(projectId);
    if (!project) {
      console.error(`Project not found: ${projectId}`);
      return;
    }

    await project.updateStatus('processing');

    console.log(`🎭 Starting avatar-based video generation for project ${projectId} using ${provider}`);

    // Simulate processing (in production, integrate with actual services)
    const processingTime = 60 + (script.length / 10); // Base 60 seconds + script complexity
    
    setTimeout(async () => {
      try {
        // In production, this would call the actual video generation service
        // For now, we'll mark it as processing and let the real service handle it
        
        const video = new Video({
          userId: project.userId,
          avatarId: avatar._id,
          title: project.title,
          script: script,
          videoUrl: null, // Will be set when actual video is generated
          status: 'processing',
          duration: Math.ceil(script.length / 150) * 60, // Estimate
          metadata: {
            type: 'avatar-based',
            provider: provider,
            scriptLength: script.length,
          }
        });

        await video.save();

        await project.updateStatus('completed', {
          videoId: video._id,
          videoUrl: null, // Will be set when actual video is generated
          actualDuration: video.duration,
        });

        console.log(`✅ Avatar-based video generation completed for project ${projectId}`);

      } catch (error) {
        console.error(`❌ Avatar-based video generation failed for project ${projectId}:`, error);
        await project.updateStatus('failed', {
          errorMessage: error.message,
        });
      }
    }, processingTime * 1000);

  } catch (error) {
    console.error(`Avatar-based video generation failed for project ${projectId}:`, error);
    
    const project = await Project.findById(projectId);
    if (project) {
      await project.updateStatus('failed', {
        errorMessage: error.message,
      });
    }
  }
}

// Helper function to calculate processing time based on configuration
function calculateProcessingTime(config) {
  let baseTime = 30; // Base 30 seconds
  
  // Duration factor
  baseTime += config.duration * 2; // 2 seconds per video second
  
  // Resolution factor
  if (config.resolution === 1080) {
    baseTime += 15;
  }
  
  return Math.min(baseTime, 180); // Max 3 minutes for demo
}





// Poll Runway task status
async function pollRunwayTask(projectId, taskId) {
  console.log('🔄 === STARTING RUNWAY TASK POLLING ===');
  console.log('📋 Project ID:', projectId);
  console.log('🎯 Task ID:', taskId);
  
  const maxAttempts = 60; // 5 minutes max (5 second intervals)
  let attempts = 0;

  const poll = async () => {
    try {
      attempts++;
      console.log(`🔍 Polling attempt ${attempts}/${maxAttempts} for task ${taskId}`);
      
      const project = await Project.findById(projectId);
      if (!project || project.status !== 'processing') {
        console.log(`🛑 Stopping poll for project ${projectId} - status changed to: ${project?.status || 'not found'}`);
        return;
      }

      console.log('🌐 Checking RunwayML task status...');
      // Use a simple status check with the corrected endpoint
      const response = await axios.get(
        `https://api.dev.runwayml.com/v1/tasks/${taskId}`,
        {
          headers: {
            'Authorization': `Bearer ${process.env.RUNWAY_API_KEY}`,
            'Content-Type': 'application/json',
            'X-Runway-Version': '2024-11-06'
          }
        }
      );
      
      const taskStatus = response.data;
      console.log(`📊 Task status response:`, JSON.stringify(taskStatus, null, 2));
      console.log(`🔍 Runway task ${taskId} status: ${taskStatus.status}`);

      if (taskStatus.status === 'SUCCEEDED') {
        console.log('🎉 Video generation completed!');
        console.log('📹 Output URL:', taskStatus.output?.[0]);
        // Video generation completed
        await handleVideoCompletion(projectId, taskStatus.output?.[0], project);
        
      } else if (taskStatus.status === 'FAILED') {
        console.log('❌ Video generation failed');
        console.log('❌ Error message:', taskStatus.failure_reason);
        // Video generation failed
        await project.updateStatus('failed', {
          errorMessage: taskStatus.failure_reason || 'Video generation failed',
        });
        
      } else if (taskStatus.status === 'RUNNING' || taskStatus.status === 'PENDING') {
        console.log(`⏳ Task still ${taskStatus.status}... continuing to poll`);
        // Still processing, continue polling
        if (attempts < maxAttempts) {
          console.log(`⏰ Waiting 5 seconds before next poll...`);
          setTimeout(poll, 5000); // Poll every 5 seconds
        } else {
          console.log('⏰ Maximum polling attempts reached - timing out');
          await project.updateStatus('failed', {
            errorMessage: 'Video generation timed out',
          });
        }
      }
      
    } catch (error) {
      console.error(`❌ Error polling Runway task ${taskId}:`, error);
      console.error(`❌ Error details:`, error.message);
      
      if (attempts < maxAttempts) {
        setTimeout(poll, 10000); // Retry in 10 seconds on error
      } else {
        const project = await Project.findById(projectId);
        if (project) {
          await project.updateStatus('failed', {
            errorMessage: 'Failed to check video generation status',
          });
        }
      }
    }
  };

  // Start polling
  setTimeout(poll, 5000); // First check after 5 seconds
}

// Enhanced Cloudinary streaming upload function
async function uploadRunwayVideoToCloudinary(runwayUrl, projectId) {
  return new Promise(async (resolve, reject) => {
    try {
      console.log('🌊 === STARTING STREAMING UPLOAD ===');
      console.log('📡 Fetching video from Runway URL:', runwayUrl);
      
      // Fetch video as stream from Runway
      const response = await fetch(runwayUrl);
      
      if (!response.ok) {
        throw new Error(`Failed to fetch video: ${response.status} ${response.statusText}`);
      }
      
      console.log('✅ Video stream obtained from Runway');
      console.log('📊 Content Length:', response.headers.get('content-length'));
      console.log('📋 Content Type:', response.headers.get('content-type'));
      
      // Create upload stream to Cloudinary
      const uploadStream = cloudinary.uploader.upload_stream(
        {
          resource_type: 'video',
          folder: 'ai-generated-videos',
          public_id: `video_${projectId}_${Date.now()}`,
          overwrite: true,
          invalidate: true,
          transformation: [
            { quality: 'auto' },
            { format: 'mp4' }
          ],
          // Enhanced options for streaming
          timeout: 300000, // 5 minutes timeout
          chunk_size: 6000000, // 6MB chunks
        },
        (error, result) => {
          if (error) {
            console.error('❌ Cloudinary streaming upload error:', error);
            reject(error);
          } else {
            console.log('✅ Cloudinary streaming upload successful!');
            console.log('📋 Upload result:', JSON.stringify({
              secure_url: result.secure_url,
              public_id: result.public_id,
              bytes: result.bytes,
              width: result.width,
              height: result.height,
              duration: result.duration
            }, null, 2));
            resolve(result);
          }
        }
      );
      
      // Pipe the video stream directly to Cloudinary
      console.log('🚰 Piping video stream to Cloudinary...');
      response.body.pipe(uploadStream);
      
    } catch (error) {
      console.error('❌ Streaming upload setup error:', error);
      reject(error);
    }
  });
}

// Handle video completion - upload to Cloudinary
async function handleVideoCompletion(projectId, runwayVideoUrl, project) {
  try {
    console.log('🎬 === STARTING VIDEO COMPLETION PROCESS ===');
    console.log('📋 Project ID:', projectId);
    console.log('🔗 Runway video URL:', runwayVideoUrl);
    console.log(`🎥 Video completed for project ${projectId}. Uploading to Cloudinary...`);
    
    // Use streaming upload instead of direct URL upload
    console.log('🌊 Using streaming upload to prevent URL expiry issues...');
    const cloudinaryResult = await uploadRunwayVideoToCloudinary(runwayVideoUrl, projectId);

    console.log(`✅ Video uploaded to Cloudinary successfully!`);
    console.log('📋 Cloudinary result:', JSON.stringify({
      secure_url: cloudinaryResult.secure_url,
      public_id: cloudinaryResult.public_id,
      bytes: cloudinaryResult.bytes,
      width: cloudinaryResult.width,
      height: cloudinaryResult.height,
      duration: cloudinaryResult.duration
    }, null, 2));

    console.log('💾 Creating video record in database...');
    // Create video record
    const video = new Video({
      userId: project.userId,
      title: project.title,
      script: project.description,
      videoUrl: cloudinaryResult.secure_url,
      thumbnailUrl: cloudinaryResult.secure_url.replace('.mp4', '.jpg'),
      cloudinaryVideoId: cloudinaryResult.public_id,
      status: 'completed',
      duration: project.configuration.duration,
      fileSize: cloudinaryResult.bytes,
      resolution: {
        width: cloudinaryResult.width,
        height: cloudinaryResult.height
      },
      metadata: {
        type: 'text-based',
        description: project.description,
        duration: project.configuration.duration,
        aspectRatio: project.configuration.aspectRatio,
        resolution: project.configuration.resolution,
        provider: 'runway',
        cloudinaryPublicId: cloudinaryResult.public_id,
        uploadMethod: 'streaming' // Track that streaming upload was used
      }
    });

    await video.save();
    console.log('✅ Video record created in database with ID:', video._id);

    console.log('🔄 Updating project status to completed...');
    // Update project
    await project.updateStatus('completed', {
      videoId: video._id,
      videoUrl: cloudinaryResult.secure_url,
      thumbnailUrl: cloudinaryResult.secure_url.replace('.mp4', '.jpg'),
      actualDuration: project.configuration.duration,
      fileSize: cloudinaryResult.bytes,
      dimensions: {
        width: cloudinaryResult.width,
        height: cloudinaryResult.height
      }
    });

    console.log(`✅ Text-based video generation completed for project ${projectId}`);
    console.log('🎉 === VIDEO GENERATION PROCESS COMPLETED SUCCESSFULLY ===');

  } catch (error) {
    console.error(`❌ Error handling video completion for project ${projectId}:`, error);
    
    // If streaming upload fails, try traditional upload methods
    if (error.message && (error.message.includes('fetch') || error.message.includes('stream'))) {
      console.log('🔄 Streaming upload failed, trying traditional upload method...');
      
      try {
        console.log('🔄 Attempting traditional Cloudinary upload...');
        const traditionalResult = await cloudinary.uploader.upload(runwayVideoUrl, {
          resource_type: 'video',
          folder: 'ai-generated-videos',
          overwrite: true,
          timeout: 120000 // 2 minutes
        });
        
        console.log('✅ Traditional Cloudinary upload successful!');
        
        // Create video record with successful upload
        const video = new Video({
          userId: project.userId,
          title: project.title,
          script: project.description,
          videoUrl: traditionalResult.secure_url,
          thumbnailUrl: traditionalResult.secure_url.replace('.mp4', '.jpg'),
          cloudinaryVideoId: traditionalResult.public_id,
          status: 'completed',
          duration: project.configuration.duration,
          fileSize: traditionalResult.bytes,
          resolution: {
            width: traditionalResult.width,
            height: traditionalResult.height
          },
          metadata: {
            type: 'text-based',
            description: project.description,
            duration: project.configuration.duration,
            aspectRatio: project.configuration.aspectRatio,
            resolution: project.configuration.resolution,
            provider: 'runway',
            cloudinaryPublicId: traditionalResult.public_id,
            uploadMethod: 'traditional'
          }
        });

        await video.save();
        console.log('✅ Video record created with traditional upload');

        await project.updateStatus('completed', {
          videoId: video._id,
          videoUrl: traditionalResult.secure_url,
          thumbnailUrl: traditionalResult.secure_url.replace('.mp4', '.jpg'),
          actualDuration: project.configuration.duration,
          fileSize: traditionalResult.bytes,
          dimensions: {
            width: traditionalResult.width,
            height: traditionalResult.height
          }
        });

        console.log(`✅ Text-based video generation completed for project ${projectId} (traditional upload)`);
        return;
        
      } catch (simpleError) {
        console.error(`❌ Simple upload also failed for project ${projectId}:`, simpleError);
        console.log('🔄 Falling back to Runway URL storage...');
      }
      
      try {
        // Store the Runway video URL directly without Cloudinary
        const video = new Video({
          userId: project.userId,
          title: project.title,
          script: project.description,
          videoUrl: runwayVideoUrl,
          thumbnailUrl: runwayVideoUrl.replace('.mp4', '.jpg'),
          cloudinaryVideoId: null,
          status: 'completed',
          duration: project.configuration.duration,
          fileSize: null,
          resolution: {
            width: project.configuration.aspectRatio === '1280:720' ? 1280 : 720,
            height: project.configuration.aspectRatio === '1280:720' ? 720 : 1280
          },
          metadata: {
            type: 'text-based',
            description: project.description,
            duration: project.configuration.duration,
            aspectRatio: project.configuration.aspectRatio,
            resolution: project.configuration.resolution,
            provider: 'runway',
            cloudinaryPublicId: null,
            fallbackUrl: true
          }
        });

        await video.save();
        console.log('✅ Video record created with Runway URL fallback');

        await project.updateStatus('completed', {
          videoId: video._id,
          videoUrl: runwayVideoUrl,
          thumbnailUrl: runwayVideoUrl.replace('.mp4', '.jpg'),
          actualDuration: project.configuration.duration,
          fileSize: null,
          dimensions: {
            width: project.configuration.aspectRatio === '1280:720' ? 1280 : 720,
            height: project.configuration.aspectRatio === '1280:720' ? 720 : 1280
          }
        });

        console.log(`✅ Text-based video generation completed for project ${projectId} (fallback mode)`);
        return;
        
      } catch (fallbackError) {
        console.error(`❌ Fallback storage also failed for project ${projectId}:`, fallbackError);
      }
    }
    
    await project.updateStatus('failed', {
      errorMessage: `Upload failed: ${error.message}`,
    });
  }
}

// DEBUG ROUTE: Check RunwayML task status manually
router.get('/debug/runway/:taskId', async (req, res) => {
  try {
    const { taskId } = req.params;
    console.log(`🔍 DEBUG: Checking RunwayML task status for: ${taskId}`);
    
    const response = await axios.get(
      `https://api.dev.runwayml.com/v1/tasks/${taskId}`,
      {
        headers: {
          'Authorization': `Bearer ${process.env.RUNWAY_API_KEY}`,
          'Content-Type': 'application/json',
          'X-Runway-Version': '2024-11-06'
        }
      }
    );
    
    console.log(`✅ DEBUG: Task status retrieved successfully`);
    res.json({
      success: true,
      taskId,
      data: response.data
    });
    
  } catch (error) {
    console.error(`❌ DEBUG: Error checking task ${req.params.taskId}:`, error.response?.data || error.message);
    res.status(error.response?.status || 500).json({
      success: false,
      taskId: req.params.taskId,
      error: error.response?.data || error.message
    });
  }
});

// DEBUG ROUTE: Manually resume polling for a stuck project
router.post('/debug/resume-polling/:projectId', async (req, res) => {
  try {
    const { projectId } = req.params;
    const { taskId } = req.body;
    
    if (!taskId) {
      return res.status(400).json({
        error: 'taskId is required in request body'
      });
    }
    
    console.log(`🔧 DEBUG: Manually resuming polling for project ${projectId} with task ${taskId}`);
    
    // Start polling
    pollRunwayTask(projectId, taskId);
    
    res.json({
      success: true,
      message: `Polling resumed for project ${projectId} with task ${taskId}`
    });
    
  } catch (error) {
    console.error(`❌ DEBUG: Error resuming polling:`, error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

module.exports = router;