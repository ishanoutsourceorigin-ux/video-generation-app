const axios = require('axios');
const cloudinary = require('cloudinary').v2;
const fs = require('fs');
const path = require('path');
const { promisify } = require('util');

// Try to import ffmpeg, but handle gracefully if missing
let ffmpeg = null;
try {
  ffmpeg = require('fluent-ffmpeg');
} catch (error) {
  console.warn('⚠️ FFmpeg not available - thumbnail generation will be disabled');
}

class A2ECompletionService {
  constructor() {
    this.apiUrl = 'https://video.a2e.ai/api/v1/talkingPhoto';
    this.apiToken = process.env.A2E_API_TOKEN;
    
    if (!this.apiToken) {
      throw new Error('A2E_API_TOKEN is required');
    }

    // Configure Cloudinary
    cloudinary.config({
      cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
      api_key: process.env.CLOUDINARY_API_KEY,
      api_secret: process.env.CLOUDINARY_API_SECRET,
    });
  }

  /**
   * Complete A2E video processing - download from A2E, upload to Cloudinary, create thumbnail
   * @param {string} taskId - A2E task ID
   * @param {string} projectId - MongoDB project ID
   * @returns {Promise<Object>} Completion result with Cloudinary URLs
   */
  async completeA2EVideo(taskId, projectId) {
    try {
      console.log('🎬 Starting A2E video completion process...');
      console.log('📋 Task ID:', taskId);
      console.log('📋 Project ID:', projectId);

      // Step 1: Get A2E task status and video URL
      const taskStatus = await this.getA2ETaskStatus(taskId);
      
      if (taskStatus.current_status !== 'completed') {
        throw new Error(`A2E task not completed. Status: ${taskStatus.current_status}`);
      }

      if (!taskStatus.result_url) {
        throw new Error('A2E task completed but no result URL available');
      }

      console.log('✅ A2E task completed, downloading video...');
      console.log('📹 A2E Video URL:', taskStatus.result_url);

      // Step 2: Download video from A2E
      const videoBuffer = await this.downloadVideoFromA2E(taskStatus.result_url);
      console.log('✅ Video downloaded from A2E');

      // Step 3: Upload video to Cloudinary
      const videoResult = await this.uploadVideoToCloudinary(videoBuffer, projectId);
      console.log('✅ Video uploaded to Cloudinary:', videoResult.secure_url);

      // Step 4: Try to extract first frame as thumbnail (optional if ffmpeg available)
      let thumbnailResult = null;
      let videoInfo = { fileSize: videoBuffer.length };
      
      if (ffmpeg) {
        try {
          thumbnailResult = await this.createThumbnailFromVideo(videoBuffer, projectId);
          console.log('✅ Thumbnail created:', thumbnailResult.secure_url);
          
          // Step 5: Get video dimensions and file size
          videoInfo = await this.getVideoInfo(videoBuffer);
          console.log('✅ Video info extracted:', videoInfo);
        } catch (error) {
          console.warn('⚠️ Thumbnail/info extraction failed, but video upload succeeded:', error.message);
        }
      } else {
        console.log('⚠️ FFmpeg not available - skipping thumbnail generation');
      }

      return {
        success: true,
        videoUrl: videoResult.secure_url,
        thumbnailUrl: thumbnailResult?.secure_url || null,
        dimensions: videoInfo.dimensions || { width: 720, height: 1280 }, // Default dimensions
        fileSize: videoInfo.fileSize,
        actualDuration: taskStatus.duration || videoInfo.duration || 0,
        a2eTaskId: taskId,
        cloudinaryVideoId: videoResult.public_id,
        cloudinaryThumbnailId: thumbnailResult?.public_id || null
      };

    } catch (error) {
      console.error('❌ A2E completion failed:', error.message);
      throw error;
    }
  }

  /**
   * Get A2E task status
   * @param {string} taskId - A2E task ID
   * @returns {Promise<Object>} Task status data
   */
  async getA2ETaskStatus(taskId) {
    try {
      const response = await axios.get(
        `${this.apiUrl}/${taskId}`,
        {
          headers: {
            'Authorization': `Bearer ${this.apiToken}`,
          },
          timeout: 10000,
        }
      );

      if (response.data.code === 0 && response.data.data) {
        return response.data.data;
      } else {
        throw new Error(`A2E API Error: ${response.data.message || 'Unknown error'}`);
      }

    } catch (error) {
      console.error('❌ Failed to get A2E task status:', error.message);
      throw error;
    }
  }

  /**
   * Download video from A2E URL
   * @param {string} videoUrl - A2E video URL
   * @returns {Promise<Buffer>} Video buffer
   */
  async downloadVideoFromA2E(videoUrl) {
    try {
      const response = await axios({
        method: 'GET',
        url: videoUrl,
        responseType: 'arraybuffer',
        timeout: 60000, // 60 seconds for video download
      });

      return Buffer.from(response.data);

    } catch (error) {
      console.error('❌ Failed to download video from A2E:', error.message);
      throw error;
    }
  }

  /**
   * Upload video to Cloudinary
   * @param {Buffer} videoBuffer - Video buffer
   * @param {string} projectId - Project ID for naming
   * @returns {Promise<Object>} Cloudinary upload result
   */
  async uploadVideoToCloudinary(videoBuffer, projectId) {
    try {
      return new Promise((resolve, reject) => {
        const uploadStream = cloudinary.uploader.upload_stream(
          {
            resource_type: 'video',
            folder: 'ai-generated-videos',
            public_id: `avatar_video_${projectId}_${Date.now()}`,
            quality: 'auto',
            format: 'mp4',
          },
          (error, result) => {
            if (error) {
              reject(error);
            } else {
              resolve(result);
            }
          }
        );

        uploadStream.end(videoBuffer);
      });

    } catch (error) {
      console.error('❌ Failed to upload video to Cloudinary:', error.message);
      throw error;
    }
  }

  /**
   * Create thumbnail from video (requires ffmpeg)
   * @param {Buffer} videoBuffer - Video buffer
   * @param {string} projectId - Project ID for naming
   * @returns {Promise<Object>} Cloudinary thumbnail upload result
   */
  async createThumbnailFromVideo(videoBuffer, projectId) {
    if (!ffmpeg) {
      throw new Error('FFmpeg not available for thumbnail generation');
    }
    
    try {
      // Save video buffer to temporary file
      const tempVideoPath = path.join(__dirname, '../temp', `temp_video_${Date.now()}.mp4`);
      const tempThumbnailPath = path.join(__dirname, '../temp', `temp_thumbnail_${Date.now()}.jpg`);
      
      // Ensure temp directory exists
      const tempDir = path.dirname(tempVideoPath);
      if (!fs.existsSync(tempDir)) {
        fs.mkdirSync(tempDir, { recursive: true });
      }

      // Write video buffer to temp file
      fs.writeFileSync(tempVideoPath, videoBuffer);

      // Extract first frame using ffmpeg
      await new Promise((resolve, reject) => {
        ffmpeg(tempVideoPath)
          .screenshots({
            timestamps: ['0.1'], // Get frame at 0.1 seconds
            filename: path.basename(tempThumbnailPath),
            folder: path.dirname(tempThumbnailPath),
            size: '720x1280' // Match video dimensions
          })
          .on('end', resolve)
          .on('error', reject);
      });

      // Upload thumbnail to Cloudinary
      const thumbnailResult = await cloudinary.uploader.upload(tempThumbnailPath, {
        resource_type: 'image',
        folder: 'avatar-thumbnails',
        public_id: `avatar_thumbnail_${projectId}_${Date.now()}`,
        quality: 'auto',
        format: 'jpg',
      });

      // Clean up temp files
      try {
        fs.unlinkSync(tempVideoPath);
        fs.unlinkSync(tempThumbnailPath);
      } catch (cleanupError) {
        console.warn('⚠️ Failed to clean up temp files:', cleanupError.message);
      }

      return thumbnailResult;

    } catch (error) {
      console.error('❌ Failed to create thumbnail:', error.message);
      throw error;
    }
  }

  /**
   * Get video information (dimensions, duration, file size) - requires ffmpeg
   * @param {Buffer} videoBuffer - Video buffer
   * @returns {Promise<Object>} Video information
   */
  async getVideoInfo(videoBuffer) {
    if (!ffmpeg) {
      return {
        dimensions: { width: 720, height: 1280 }, // Default dimensions
        duration: 0, // Unknown duration
        fileSize: videoBuffer.length
      };
    }
    
    try {
      const tempVideoPath = path.join(__dirname, '../temp', `info_video_${Date.now()}.mp4`);
      
      // Ensure temp directory exists
      const tempDir = path.dirname(tempVideoPath);
      if (!fs.existsSync(tempDir)) {
        fs.mkdirSync(tempDir, { recursive: true });
      }

      // Write video buffer to temp file
      fs.writeFileSync(tempVideoPath, videoBuffer);

      // Get video info using ffmpeg
      const videoInfo = await new Promise((resolve, reject) => {
        ffmpeg.ffprobe(tempVideoPath, (err, metadata) => {
          if (err) {
            reject(err);
          } else {
            const videoStream = metadata.streams.find(stream => stream.codec_type === 'video');
            resolve({
              dimensions: {
                width: videoStream.width,
                height: videoStream.height
              },
              duration: metadata.format.duration,
              fileSize: videoBuffer.length
            });
          }
        });
      });

      // Clean up temp file
      try {
        fs.unlinkSync(tempVideoPath);
      } catch (cleanupError) {
        console.warn('⚠️ Failed to clean up temp file:', cleanupError.message);
      }

      return videoInfo;

    } catch (error) {
      console.error('❌ Failed to get video info:', error.message);
      throw error;
    }
  }

  /**
   * Poll A2E task until completion
   * @param {string} taskId - A2E task ID
   * @param {number} maxAttempts - Maximum polling attempts
   * @returns {Promise<Object>} Final task status
   */
  async pollA2ETaskCompletion(taskId, maxAttempts = 60) { // 60 attempts = 10 minutes max
    let attempts = 0;
    
    while (attempts < maxAttempts) {
      try {
        const taskStatus = await this.getA2ETaskStatus(taskId);
        
        console.log(`🔄 Polling A2E task (${attempts + 1}/${maxAttempts}): ${taskStatus.current_status}`);
        
        if (taskStatus.current_status === 'completed') {
          console.log('✅ A2E task completed!');
          return taskStatus;
        }
        
        if (taskStatus.current_status === 'failed') {
          throw new Error(`A2E task failed: ${taskStatus.failed_message}`);
        }
        
        // Wait 10 seconds before next poll
        await new Promise(resolve => setTimeout(resolve, 10000));
        attempts++;
        
      } catch (error) {
        console.error(`❌ Error polling A2E task (attempt ${attempts + 1}):`, error.message);
        attempts++;
        
        if (attempts >= maxAttempts) {
          throw new Error('Max polling attempts reached');
        }
        
        // Wait before retry
        await new Promise(resolve => setTimeout(resolve, 5000));
      }
    }
    
    throw new Error('A2E task polling timeout');
  }
}

module.exports = A2ECompletionService;