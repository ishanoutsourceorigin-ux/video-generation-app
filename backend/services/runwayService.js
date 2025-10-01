const axios = require('axios');
const fs = require('fs');
const path = require('path');
const { uploadVideo, uploadRawFile, cleanupLocalFile } = require('./cloudinaryService');

class RunwayService {
  constructor() {
    this.apiKey = process.env.RUNWAY_API_KEY;
    this.baseUrl = 'https://api.dev.runwayml.com';
    
    console.log('🎬 RunwayService initialized');
    console.log('🔑 API Key configured:', !!this.apiKey);
    console.log('🌐 API Base URL:', this.baseUrl);
    
    if (!this.apiKey) {
      console.error('❌ Runway API key not configured. Set RUNWAY_API_KEY environment variable.');
    }
  }

  // VEO-3 specific video generation function as per ChatGPT requirements
  async generateVeo3Video(promptText, duration, ratio, seed) {
    try {
      console.log('🎬 === VEO-3 VIDEO GENERATION ===');
      console.log(`📝 Prompt: "${promptText}"`);
      console.log(`⏱️ Duration: ${duration}s`);
      console.log(`📐 Ratio: ${ratio}`);
      console.log(`🎲 Seed: ${seed}`);

      // Validate API key
      if (!this.apiKey || this.apiKey === 'your-runway-api-key-here') {
        throw new Error('Runway API key is not configured. Please set RUNWAY_API_KEY in your environment variables.');
      }

      // Validate duration (VEO-3 requires exactly 8 seconds)
      if (duration !== 8) {
        console.log(`⚠️ VEO-3 Warning: Duration adjusted from ${duration}s to 8s (VEO-3 requirement)`);
        duration = 8; // Force to 8 seconds for VEO-3
      }

      // Validate ratio (VEO-3 only supports specific ratios)
      const validRatios = ['1280:720', '720:1280'];
      if (!validRatios.includes(ratio)) {
        throw new Error('Ratio must be either "1280:720" (landscape) or "720:1280" (portrait) for VEO-3 model.');
      }

      console.log('✅ All VEO-3 validations passed');

      // Prepare API request payload
      const payload = {
        model: 'veo3',
        promptText,
        duration,
        ratio,
        seed
      };

      console.log('🌐 Sending request to RunwayML VEO-3 API...');
      console.log('📦 Payload:', JSON.stringify(payload, null, 2));

      // Make API call
      const response = await axios.post(
        'https://api.dev.runwayml.com/v1/text_to_video',
        payload,
        {
          headers: {
            'Authorization': `Bearer ${this.apiKey}`,
            'Content-Type': 'application/json',
            'X-Runway-Version': '2024-11-06'
          }
        }
      );

      console.log('✅ VEO-3 API call successful!');
      console.log('📋 Response:', JSON.stringify(response.data, null, 2));

      // Return the parsed JSON response
      return response.data;

    } catch (error) {
      console.error('❌ VEO-3 API Error:', error.response?.data || error.message);
      
      // Throw error with API error message if available
      if (error.response?.data?.error) {
        throw new Error(`VEO-3 API Error: ${error.response.data.error}`);
      } else if (error.response?.data) {
        throw new Error(`VEO-3 API Error: ${JSON.stringify(error.response.data)}`);
      } else {
        throw new Error(`VEO-3 Error: ${error.message}`);
      }
    }
  }

  // Enhanced video generation method that handles the full pipeline
  async generateVideo(speechCloudinaryUrl, script, projectId) {
    try {
      if (!this.apiKey || this.apiKey === 'your-runway-api-key-here') {
        throw new Error('Runway API key is not configured. Please set RUNWAY_API_KEY in your environment variables.');
      }

      console.log('🎬 Starting text-to-video generation with Runway VEO3...');
      console.log('🎯 Using VEO3 model for pure text-to-video generation');
      
      // Use VEO3 model for text-to-video (our working model!)
      const videoGenerationPayload = {
        promptText: script.substring(0, 500),
        model: 'veo3', // Working model from our subscription
        ratio: '1280:720', // Valid aspect ratio
        duration: 8 // VEO3 requires duration 8
      };

      try {
        console.log('🎯 Starting VEO3 text-to-video generation...');
        const videoResponse = await axios.post(
          `${this.baseUrl}/v1/text_to_video`,
          videoGenerationPayload,
          {
            headers: {
              'Authorization': `Bearer ${this.apiKey}`,
              'Content-Type': 'application/json',
              'X-Runway-Version': '2024-11-06'
            }
          }
        );

        console.log('✅ VEO3 text-to-video generation task created:', videoResponse.data.id);
        
        // Poll for completion
        const taskId = videoResponse.data.id;
        const videoResult = await this.pollVideoTask(taskId);
        
        if (videoResult && videoResult.output && videoResult.output[0]) {
          const videoUrl = videoResult.output[0];
          console.log('✅ VEO3 text-to-video generated successfully:', videoUrl);
          
          // Download and upload to Cloudinary
          const cloudinaryResult = await this.downloadAndUploadVideo(videoUrl, projectId);
          
          return {
            videoPath: cloudinaryResult.secure_url,
            duration: '0:08', // VEO3 generates 8-second videos
            thumbnailPath: cloudinaryResult.thumbnail_url || null,
            cloudinaryUrl: cloudinaryResult.secure_url,
            runway_task_id: taskId,
            generationMethod: 'text-to-video (VEO3)'
          };
        } else {
          throw new Error('VEO3 text-to-video generation completed but no output received');
        }

      } catch (veo3Error) {
        console.error('❌ VEO3 text-to-video failed:', veo3Error.response?.data || veo3Error.message);
        
        // Fallback to image-to-video if VEO3 fails
        console.log('🔄 Falling back to image-to-video generation...');
        
        const fallbackImage = "https://upload.wikimedia.org/wikipedia/commons/8/85/Tour_Eiffel_Wikimedia_Commons_(cropped).jpg";
        
        const fallbackPayload = {
          promptImage: fallbackImage,
          promptText: script.substring(0, 500),
          model: 'gen3a_turbo',
          ratio: '1280:768', // Different ratio for image-to-video
          duration: 5
        };

        try {
          const fallbackResponse = await axios.post(
            `${this.baseUrl}/v1/image_to_video`,
            fallbackPayload,
            {
              headers: {
                'Authorization': `Bearer ${this.apiKey}`,
                'Content-Type': 'application/json',
                'X-Runway-Version': '2024-11-06'
              }
            }
          );

          console.log('✅ Image-to-video fallback task created:', fallbackResponse.data.id);
          
          const fallbackTaskId = fallbackResponse.data.id;
          const fallbackVideoResult = await this.pollVideoTask(fallbackTaskId);
          
          if (fallbackVideoResult && fallbackVideoResult.output && fallbackVideoResult.output[0]) {
            const videoUrl = fallbackVideoResult.output[0];
            console.log('✅ Image-to-video fallback generated successfully:', videoUrl);
            
            const cloudinaryResult = await this.downloadAndUploadVideo(videoUrl, projectId);
            
            return {
              videoPath: cloudinaryResult.secure_url,
              duration: '0:05', 
              thumbnailPath: cloudinaryResult.thumbnail_url || null,
              cloudinaryUrl: cloudinaryResult.secure_url,
              runway_task_id: fallbackTaskId,
              generationMethod: 'image-to-video (fallback)'
            };
          } else {
            throw new Error('Image-to-video fallback completed but no output received');
          }

        } catch (fallbackError) {
          console.error('❌ Image-to-video fallback also failed:', fallbackError.response?.data || fallbackError.message);
          throw fallbackError;
        }
      }

    } catch (error) {
      console.error('Runway video generation error:', error.response?.data || error.message);
      
      // Handle subscription-related errors
      if (error.response?.status === 401) {
        throw new Error('Runway API key is invalid. Please update your subscription and API key.');
      }
      
      if (error.response?.status === 429) {
        throw new Error('Runway API quota exceeded. Please upgrade your subscription to continue generating videos.');
      }
      
      if (error.response?.status === 402) {
        throw new Error('Runway subscription limit reached. Please upgrade your plan to generate more videos.');
      }
      
      if (error.response?.data?.error?.includes('credit') || error.response?.data?.error?.includes('quota')) {
        throw new Error('Runway account has insufficient credits. Please upgrade your subscription to continue generating videos.');
      }
      
      if (error.response?.data?.error?.includes('subscription')) {
        throw new Error('Your Runway subscription does not support this feature. Please upgrade your plan.');
      }
      
      // Fall back to mock video
      console.log('🎬 Falling back to mock video due to API error...');
      return await this.createMockVideo(speechCloudinaryUrl, script, projectId);
    }
  }

  // Generate text-based video using Runway Gen-2
  async generateTextBasedVideo({
    prompt,
    duration = 4,
    aspectRatio = '9:16',
    resolution = 1080,
    motion = 'medium',
    seed
  }) {
    try {
      console.log('🚀 === STARTING RUNWAY VIDEO GENERATION ===');
      console.log('🔑 Checking API key...');
      if (!this.apiKey) {
        console.error('❌ Runway API key not configured');
        throw new Error('Runway API key not configured');
      }
      console.log('✅ API key verified');

      console.log(`🎬 Video generation parameters:`);
      console.log(`  📝 Prompt: "${prompt}"`);
      console.log(`  ⏱️ Duration: ${duration}s (VEO-3 model)`);
      console.log(`  📐 Aspect Ratio: ${aspectRatio}`);
      console.log(`  🔧 Resolution: ${resolution}p`);
      console.log(`  🎭 Motion: ${motion}`);
      console.log(`  🎲 Seed: ${seed || 'random'}`);

      console.log('🌐 Preparing VEO-3 API request...');

      // VEO-3 model specific constraints - MUST be exactly 8 seconds
      const veo3Duration = 8; // VEO-3 requires exactly 8 seconds, not max 8
      console.log(`⚙️ VEO-3 model - forcing duration to: ${veo3Duration}s (VEO-3 requirement)`);

      // Create a concise prompt under 1000 characters
      const shortPrompt = this.createShortPrompt(prompt, veo3Duration);
      console.log(`📝 Shortened prompt (${shortPrompt.length} chars): "${shortPrompt}"`);
      
      // Convert aspect ratio to VEO-3 supported format
      const veo3Ratio = this.convertToVeo3Ratio(aspectRatio, resolution);
      console.log(`📐 Converted to VEO-3 ratio: ${aspectRatio} → ${veo3Ratio}`);

      // Generate seed if not provided
      const finalSeed = seed || Math.floor(Math.random() * 1000000);

      // Use the specific VEO-3 function
      console.log('🎯 Using VEO-3 specific generation function...');
      const veo3Response = await this.generateVeo3Video(
        shortPrompt,
        veo3Duration,
        veo3Ratio,
        finalSeed
      );

      // Convert VEO-3 response to our standard format
      const response = {
        data: {
          id: veo3Response.id,
          status: veo3Response.status || 'queued'
        }
      };

      console.log(`✅ Runway task created: ${response.data.id}`);
      console.log('📋 Full response:', JSON.stringify(response.data, null, 2));
      
      return {
        taskId: response.data.id,
        status: response.data.status || 'queued',
        estimatedTime: veo3Duration * 15, // Rough estimate: 15 seconds processing per video second
        message: 'Video generation started with Runway VEO3 model',
        actualDuration: veo3Duration
      };

    } catch (error) {
      console.error('❌ Runway API Error Details:');
      console.error('Status:', error.response?.status);
      console.error('Data:', JSON.stringify(error.response?.data, null, 2));
      console.error('Headers:', error.response?.headers);
      console.error('Request URL:', error.config?.url);
      console.error('Request Method:', error.config?.method);
      console.error('Request Data:', JSON.stringify(error.config?.data, null, 2));
      
      throw new Error(
        `Runway generation failed: ${error.response?.data?.error || error.response?.data?.detail || error.message}`
      );
    }
  }

  // Generate video from image (lip-sync or motion)
  async generateImageBasedVideo({
    imageUrl,
    audioUrl,
    duration = 10,
    aspectRatio = '9:16',
    resolution = 1080,
    motion = 'medium',
    seed
  }) {
    try {
      if (!this.apiKey) {
        throw new Error('Runway API key not configured');
      }

      console.log(`🎭 Starting Runway image-based video generation...`);
      console.log(`Image: ${imageUrl.substring(0, 50)}...`);
      console.log(`Audio: ${audioUrl ? audioUrl.substring(0, 50) + '...' : 'None'}`);

      const dimensions = this.getVideoDimensions(aspectRatio, resolution);

      const requestData = {
        taskType: 'gen1',
        internal: false,
        options: {
          name: `image_video_${Date.now()}`,
          seconds: duration,
          gen1Options: {
            mode: 'gen1',
            seed: seed || Math.floor(Math.random() * 1000000),
            interpolate: true,
            upscale: resolution >= 1080,
            watermark: false,
            init_image: imageUrl,
            mask_image: null,
            motion_vectors: [],
            use_motion_score: true,
            motion_score: this.getMotionScore(motion),
            width: dimensions.width,
            height: dimensions.height,
          },
          exploreMode: false,
          asVideoRequest: true,
        }
      };

      // Add audio if provided
      if (audioUrl) {
        requestData.options.gen1Options.audio_url = audioUrl;
      }

      const response = await axios.post(`${this.baseUrl}/v1/tasks`, requestData, {
        headers: {
          'Authorization': `Bearer ${this.apiKey}`,
          'Content-Type': 'application/json',
        },
      });

      console.log(`✅ Runway image task created: ${response.data.task.id}`);

      return {
        taskId: response.data.task.id,
        status: 'queued',
        estimatedTime: duration * 12, // Rough estimate: 12 seconds processing per video second
        message: 'Image-based video generation started with Runway'
      };

    } catch (error) {
      console.error('Runway image-based video generation error:', error.response?.data || error.message);
      throw new Error(
        `Runway image generation failed: ${error.response?.data?.detail || error.message}`
      );
    }
  }

  async pollVideoTaskWithEndpoint(taskId, baseEndpoint, maxAttempts = 30) {
    console.log(`🔄 Polling video task ${taskId}...`);
    
    // Construct the status endpoint based on the working generation endpoint
    const statusEndpoint = `${baseEndpoint}/${taskId}`;
    
    for (let attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        const response = await axios.get(
          statusEndpoint,
          {
            headers: {
              'Authorization': `Bearer ${this.apiKey}`,
              'Content-Type': 'application/json',
              'X-Runway-Version': '2024-09-13'
            }
          }
        );

        const task = response.data;
        console.log(`📊 Task ${taskId} status: ${task.status} (attempt ${attempt}/${maxAttempts})`);

        if (task.status === 'SUCCEEDED') {
          console.log('✅ Video generation completed successfully');
          return task;
        } else if (task.status === 'FAILED') {
          throw new Error(`Video generation failed: ${task.failure_reason || 'Unknown error'}`);
        }

        // Wait before next poll (10 seconds)
        await new Promise(resolve => setTimeout(resolve, 10000));
        
      } catch (error) {
        console.error(`❌ Error polling task ${taskId}:`, error.response?.data || error.message);
        throw error;
      }
    }

    throw new Error(`Video generation timed out after ${maxAttempts} attempts`);
  }

  async pollVideoTask(taskId, maxAttempts = 30) {
    console.log(`🔄 Polling video task ${taskId}...`);
    
    for (let attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        const response = await axios.get(
          `${this.baseUrl}/v1/tasks/${taskId}`,
          {
            headers: {
              'Authorization': `Bearer ${this.apiKey}`,
              'Content-Type': 'application/json',
              'X-Runway-Version': '2024-11-06'
            }
          }
        );

        const task = response.data;
        console.log(`📊 Task ${taskId} status: ${task.status} (attempt ${attempt}/${maxAttempts})`);

        if (task.status === 'SUCCEEDED') {
          console.log('✅ Video generation completed successfully');
          return task;
        } else if (task.status === 'FAILED') {
          throw new Error(`Video generation failed: ${task.failure_reason || 'Unknown error'}`);
        }

        // Wait before next poll (10 seconds)
        await new Promise(resolve => setTimeout(resolve, 10000));
        
      } catch (error) {
        console.error(`❌ Error polling task ${taskId}:`, error.response?.data || error.message);
        throw error;
      }
    }

    throw new Error(`Video generation timed out after ${maxAttempts} attempts`);
  }

  async downloadAndUploadVideo(videoUrl, projectId) {
    try {
      console.log('📥 Downloading video from Runway...');
      
      // Download the video file
      const response = await axios({
        method: 'GET',
        url: videoUrl,
        responseType: 'stream'
      });

      // Create temp file path
      const tempDir = path.join(__dirname, '../../uploads/temp');
      if (!fs.existsSync(tempDir)) {
        fs.mkdirSync(tempDir, { recursive: true });
      }

      const tempVideoPath = path.join(tempDir, `temp_runway_video_${projectId}_${Date.now()}.mp4`);
      
      // Save to temp file
      const writer = fs.createWriteStream(tempVideoPath);
      response.data.pipe(writer);

      await new Promise((resolve, reject) => {
        writer.on('finish', resolve);
        writer.on('error', reject);
      });

      console.log('✅ Video downloaded to temp file');

      // Upload to Cloudinary
      const fileName = `runway_video_${projectId}_${Date.now()}`;
      const cloudinaryResult = await uploadVideo(tempVideoPath, fileName);
      
      // Clean up temp file
      cleanupLocalFile(tempVideoPath);
      
      console.log('☁️ Video uploaded to Cloudinary:', cloudinaryResult.secure_url);
      return cloudinaryResult;

    } catch (error) {
      console.error('❌ Error downloading/uploading video:', error);
      throw error;
    }
  }

  async createMockVideo(speechCloudinaryUrl, script, projectId) {
    try {
      // Create mock video info with Cloudinary URLs
      const mockVideoInfo = {
        id: projectId,
        script: script.substring(0, 100) + '...',
        speechUrl: speechCloudinaryUrl,
        generatedAt: new Date().toISOString(),
        expectedDuration: '5 seconds',
        status: 'Mock - Runway API not available',
        note: 'This is a placeholder. Real video will be generated when Runway API is working.',
        cloudinaryUrl: null // Will be filled when real video is generated
      };
      
      // Create temp directory for mock file
      const tempDir = path.join(__dirname, '../../uploads/temp');
      if (!fs.existsSync(tempDir)) {
        fs.mkdirSync(tempDir, { recursive: true });
      }
      
      const tempInfoPath = path.join(tempDir, `temp_video_info_${projectId}.json`);
      fs.writeFileSync(tempInfoPath, JSON.stringify(mockVideoInfo, null, 2));
      console.log('📹 Mock video info created:', tempInfoPath);
      
      // Upload mock info to Cloudinary as a raw file
      try {
        const fileName = `video_info_${projectId}_${Date.now()}`;
        const cloudinaryResult = await uploadRawFile(tempInfoPath, fileName);
        console.log('☁️ Mock video info uploaded to Cloudinary:', cloudinaryResult.secure_url);
        
        // Clean up temp file
        cleanupLocalFile(tempInfoPath);
        
        return {
          videoPath: cloudinaryResult.secure_url,
          duration: '0:05', 
          thumbnailPath: null,
          isMock: true,
          type: 'mock',
          cloudinaryUrl: cloudinaryResult.secure_url
        };
      } catch (uploadError) {
        console.error('❌ Cloudinary upload failed:', uploadError);
        cleanupLocalFile(tempInfoPath);
        
        // Return local path as fallback
        return {
          videoPath: tempInfoPath,
          duration: '0:05', 
          thumbnailPath: null,
          isMock: true,
          type: 'mock',
          cloudinaryUrl: null
        };
      }
    } catch (error) {
      console.error('❌ Mock video creation error:', error);
      throw error;
    }
  }

  // Check task status
  async getTaskStatus(taskId) {
    try {
      if (!this.apiKey) {
        throw new Error('Runway API key not configured');
      }

      console.log(`🔍 Checking task status for: ${taskId}`);
      const response = await axios.get(`${this.baseUrl}/v1/tasks/${taskId}`, {
        headers: {
          'Authorization': `Bearer ${this.apiKey}`,
          'Content-Type': 'application/json',
          'X-Runway-Version': '2024-11-06',
        },
      });

      console.log('📋 Task status response:', JSON.stringify(response.data, null, 2));
      const task = response.data;

      return {
        taskId: task.id,
        status: this.mapRunwayStatus(task.status),
        progress: task.progress || 0,
        outputUrl: task.output?.[0] || null,
        errorMessage: task.failure_reason || task.error || null,
        estimatedTimeRemaining: task.estimatedTimeUntilStart || 0,
        createdAt: task.createdAt,
        startedAt: task.startedAt,
        completedAt: task.completedAt,
      };

    } catch (error) {
      console.error('Runway status check error:', error.response?.data || error.message);
      throw new Error(`Failed to check task status: ${error.response?.data?.detail || error.message}`);
    }
  }

  // Cancel a task
  async cancelTask(taskId) {
    try {
      if (!this.apiKey) {
        throw new Error('Runway API key not configured');
      }

      await axios.delete(`${this.baseUrl}/tasks/${taskId}`, {
        headers: {
          'Authorization': `Bearer ${this.apiKey}`,
          'Content-Type': 'application/json',
          'X-Runway-Version': '2024-09-13',
        },
      });

      console.log(`🚫 Runway task cancelled: ${taskId}`);
      return { success: true, message: 'Task cancelled successfully' };

    } catch (error) {
      console.error('Runway cancel task error:', error.response?.data || error.message);
      throw new Error(`Failed to cancel task: ${error.response?.data?.detail || error.message}`);
    }
  }

  // Helper method to get video dimensions based on aspect ratio and resolution
  getVideoDimensions(aspectRatio, resolution) {
    const baseHeight = resolution;
    
    switch (aspectRatio) {
      case '1:1': // Square
        return { width: baseHeight, height: baseHeight };
      
      case '9:16': // Vertical (TikTok/Instagram Stories)
        return { width: Math.round(baseHeight * 9 / 16), height: baseHeight };
      
      case '16:9': // Horizontal (YouTube)
        return { width: Math.round(baseHeight * 16 / 9), height: baseHeight };
      
      case '3:4': // Portrait
        return { width: Math.round(baseHeight * 3 / 4), height: baseHeight };
      
      case '16:19': // Vertical (Instagram)
        return { width: Math.round(baseHeight * 16 / 19), height: baseHeight };
      
      default:
        return { width: Math.round(baseHeight * 9 / 16), height: baseHeight };
    }
  }

  // Convert motion level to Runway motion score
  getMotionScore(motion) {
    switch (motion) {
      case 'low':
        return 5;
      case 'medium':
        return 10;
      case 'high':
        return 15;
      case 'cinematic':
        return 8;
      default:
        return 10;
    }
  }

  // Map Runway status to our standard status
  mapRunwayStatus(runwayStatus) {
    switch (runwayStatus) {
      case 'PENDING':
      case 'QUEUED':
        return 'queued';
      
      case 'RUNNING':
      case 'PROCESSING':
        return 'processing';
      
      case 'SUCCEEDED':
      case 'COMPLETED':
        return 'completed';
      
      case 'FAILED':
      case 'CANCELLED':
        return 'failed';
      
      default:
        return 'unknown';
    }
  }

  // Get pricing information
  getPricingInfo(duration, resolution) {
    // Runway pricing (approximate, check current rates)
    const baseCredits = 5; // Base credits per generation
    const durationMultiplier = Math.ceil(duration / 4); // Credits per 4-second chunk
    const resolutionMultiplier = resolution >= 1080 ? 1.5 : 1;
    
    return {
      credits: Math.ceil(baseCredits * durationMultiplier * resolutionMultiplier),
      estimatedCost: `$${(baseCredits * durationMultiplier * resolutionMultiplier * 0.1).toFixed(2)}`,
      duration,
      resolution,
    };
  }

  // Enhance prompt for better results
  // Create a short prompt under 1000 characters
  createShortPrompt(originalPrompt, duration) {
    try {
      // Try to parse JSON to extract key information
      const parsed = JSON.parse(originalPrompt);
      if (parsed.videoScript && parsed.videoScript.scenes) {
        const scenes = parsed.videoScript.scenes;
        const visuals = scenes.map(scene => scene.visuals).join('. ');
        const style = parsed.videoScript.style;
        
        let shortPrompt = `${visuals}. ${style?.tone || 'energetic'} style with ${style?.music || 'upbeat'} mood. Cinematic lighting, professional cinematography, ${duration}s duration.`;
        
        // Ensure it's under 1000 characters
        if (shortPrompt.length > 1000) {
          shortPrompt = shortPrompt.substring(0, 997) + '...';
        }
        
        return shortPrompt;
      }
    } catch (e) {
      // If not JSON, truncate the original prompt
      console.log('⚠️ Could not parse prompt as JSON, truncating...');
    }
    
    // Fallback: truncate original prompt
    if (originalPrompt.length > 1000) {
      return originalPrompt.substring(0, 997) + '...';
    }
    return originalPrompt;
  }

  // Convert aspect ratio to RunwayML format
  convertAspectRatio(aspectRatio, resolution) {
    const ratioMap = {
      '16:9': '1280:720',   // Landscape
      '9:16': '720:1280',   // Portrait
      '1:1': '960:960',     // Square
      '4:3': '1104:832',    // Standard
      '3:4': '832:1104',    // Portrait standard
      '21:9': '1584:672'    // Ultra-wide
    };
    
    return ratioMap[aspectRatio] || '960:960'; // Default to square
  }

  // Convert aspect ratio to Gen-4 turbo specific format (supports 6 ratios)
  convertToGen4Ratio(aspectRatio, resolution) {
    // Gen-4 turbo supports these exact ratios as per documentation
    const gen4RatioMap = {
      '16:9': '1280:720',   // Landscape - 1280x720 px
      '9:16': '720:1280',   // Portrait - 720x1280 px
      '1:1': '960:960',     // Square - 960x960 px
      '4:3': '1104:832',    // Standard - 1104x832 px
      '3:4': '832:1104',    // Portrait standard - 832x1104 px
      '21:9': '1584:672'    // Ultra-wide - 1584x672 px
    };
    
    return gen4RatioMap[aspectRatio] || '720:1280'; // Default to portrait for avatars
  }

  enhancePrompt(originalPrompt) {
    // Don't enhance anymore since we create short prompts in createShortPrompt
    return originalPrompt;
  }

  // Generate image-to-video with audio for avatar talking videos
  async generateImageToVideoWithAudio(options) {
    try {
      console.log('🎭 === AVATAR IMAGE-TO-VIDEO GENERATION ===');
      console.log('📸 Image URL:', options.imageUrl);
      console.log('🎵 Audio URL:', options.audioUrl);
      console.log('📐 Aspect Ratio:', options.aspectRatio);
      console.log('🎬 Model:', options.model || 'gen3a_turbo');
      console.log('⏱️ DURATION RECEIVED:', options.duration);

      // Validate API key
      if (!this.apiKey) {
        throw new Error('Runway API key is not configured');
      }
2
      // Convert aspect ratio to Gen-4 turbo format
      const runwayRatio = this.convertToGen4Ratio(options.aspectRatio || '9:16', 720);

      // Prepare the request payload for image-to-video (WITHOUT audio - RunwayML doesn't support promptAudio)
      console.log('🔧 Creating payload with duration:', options.duration || 5);
      const payload = {
        model: options.model || 'gen4_turbo', // Use gen4_turbo for image-to-video generation
        promptImage: options.imageUrl,
        // promptAudio: options.audioUrl, // ❌ REMOVED: RunwayML doesn't support audio input for lip-sync
        ratio: runwayRatio, // Gen-4 API uses 'ratio' not 'aspectRatio'
        duration: options.duration || 5, // Use user-selected duration (5 or 10 seconds for gen4_turbo)
        promptText: 'A person speaking naturally with realistic facial expressions and mouth movements',
        seed: Math.floor(Math.random() * 1000000),
        watermark: false,
        enhance_prompt: false // We want exact control for talking heads
      };

      console.log('📦 Payload:', JSON.stringify(payload, null, 2));

      // Make API request
      const response = await axios.post(
        `${this.baseUrl}/v1/image_to_video`,
        payload,
        {
          headers: {
            'Authorization': `Bearer ${this.apiKey}`,
            'X-Runway-Version': '2024-11-06',
            'Content-Type': 'application/json'
          },
          timeout: 30000
        }
      );

      console.log('✅ Avatar video generation request submitted');
      console.log('🆔 Task ID:', response.data.id);

      // Poll for completion
      const result = await this.pollTaskCompletion(response.data.id);
      
      // Note: RunwayML generated video without audio - audio overlay would need to be done separately
      // For now, returning the silent video. Audio can be overlaid in post-processing.
      return {
        success: true,
        taskId: response.data.id,
        videoUrl: result.output?.[0] || result.artifacts?.[0]?.url,
        audioUrl: options.audioUrl, // Pass through the audio URL for later processing
        status: result.status,
        note: 'Video generated without lip-sync. Audio overlay needed for complete avatar video.'
      };

    } catch (error) {
      console.error('❌ Avatar image-to-video generation error:', error.response?.data || error.message);
      return {
        success: false,
        error: error.response?.data?.message || error.message
      };
    }
  }

  // Enhanced polling for avatar video tasks
  async pollTaskCompletion(taskId, maxAttempts = 60) {
    console.log(`🔄 Starting polling for avatar video task: ${taskId}`);
    let attempts = 0;

    while (attempts < maxAttempts) {
      try {
        attempts++;
        console.log(`🔍 Polling attempt ${attempts}/${maxAttempts} for task ${taskId}`);

        const response = await axios.get(
          `${this.baseUrl}/v1/tasks/${taskId}`,
          {
            headers: {
              'Authorization': `Bearer ${this.apiKey}`,
              'Content-Type': 'application/json',
              'X-Runway-Version': '2024-11-06'
            }
          }
        );

        const taskData = response.data;
        console.log(`📊 Task status: ${taskData.status}`);

        if (taskData.status === 'SUCCEEDED') {
          console.log('🎉 Avatar video generation completed successfully!');
          return taskData;
        } else if (taskData.status === 'FAILED') {
          console.error('❌ Avatar video generation failed:', taskData.failure_reason);
          throw new Error(taskData.failure_reason || 'Avatar video generation failed');
        } else if (taskData.status === 'RUNNING' || taskData.status === 'PENDING') {
          // Continue polling
          console.log(`⏳ Task still ${taskData.status.toLowerCase()}, waiting...`);
          await new Promise(resolve => setTimeout(resolve, 3000)); // 3 second interval
        } else {
          console.warn(`⚠️ Unknown task status: ${taskData.status}`);
          await new Promise(resolve => setTimeout(resolve, 3000));
        }
      } catch (error) {
        console.error(`❌ Polling error (attempt ${attempts}):`, error.message);
        if (error.response) {
          console.error(`❌ Error response status: ${error.response.status}`);
          console.error(`❌ Error response data:`, error.response.data);
        }
        if (attempts >= maxAttempts) {
          throw new Error(`Polling timeout after ${maxAttempts} attempts`);
        }
        await new Promise(resolve => setTimeout(resolve, 5000)); // Wait longer on error
      }
    }

    throw new Error(`Avatar video generation timeout after ${maxAttempts} attempts`);
  }
}

module.exports = RunwayService;
// Export the specific VEO-3 function for direct use
module.exports.generateVeo3Video = RunwayService.prototype.generateVeo3Video;