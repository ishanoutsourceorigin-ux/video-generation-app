const axios = require('axios');
const fs = require('fs');
const path = require('path');
const { uploadVideo, cleanupLocalFile } = require('./cloudinaryService');

class DIDService {
  constructor() {
    this.apiKey = process.env.DID_API_KEY || 'aXNoYW5vdXRzb3VyY2VvcmlnaW5AZ21haWwuY29t:oYJ3mUGgaBJ9egzChE6zK';
    this.baseUrl = process.env.DID_BASE_URL || 'https://api.d-id.com';
    
    console.log('🎭 D-ID Service initialized');
    console.log('🔑 API Key configured:', !!this.apiKey);
    console.log('🌐 API Base URL:', this.baseUrl);
    
    if (!process.env.DID_API_KEY) {
      console.warn('⚠️ Using fallback D-ID API key. Please set DID_API_KEY in environment variables.');
    }
  }

  // Generate talking head video using D-ID API
  async generateTalkingHead(options) {
    try {
      console.log('🎭 === D-ID TALKING HEAD GENERATION ===');
      console.log('📸 Image URL:', options.imageUrl);
      console.log('🎵 Audio URL:', options.audioUrl);
      console.log('⏱️ Duration: Auto-detected from audio');
      console.log('📐 Aspect Ratio:', options.aspectRatio || '9:16');
      console.log('😊 Expression:', options.expression || 'neutral');

      // Validate API key
      if (!this.apiKey) {
        throw new Error('D-ID API key is not configured');
      }

      // Convert aspect ratio to D-ID format with expression
      const didRatio = this.convertAspectRatio(options.aspectRatio || '9:16', options.expression || 'neutral');

      // Prepare the request payload
      const payload = {
        source_url: options.imageUrl,
        script: {
          type: 'audio',
          audio_url: options.audioUrl,
          reduce_noise: true,
          ssml: false
        },
        config: {
          fluent: true,
          pad_audio: 0.0,
          stitch: true,
          result_format: 'mp4',
          ...didRatio
        }
        // Note: webhook removed - we'll poll instead
      };

      console.log('📦 D-ID Payload:', JSON.stringify(payload, null, 2));

      // Make API request to create talking head video
      const response = await axios.post(
        `${this.baseUrl}/talks`,
        payload,
        {
          headers: {
            'Authorization': `Basic ${this.apiKey}`,
            'Content-Type': 'application/json',
            'Accept': 'application/json'
          },
          timeout: 30000
        }
      );

      console.log('✅ D-ID talk creation successful!');
      console.log('🆔 Talk ID:', response.data.id);
      console.log('📋 Response:', JSON.stringify(response.data, null, 2));

      // Poll for completion
      const result = await this.pollTalkCompletion(response.data.id);

      return {
        success: true,
        talkId: response.data.id,
        videoUrl: result.result_url,
        status: result.status,
        duration: result.duration,
        created_at: result.created_at
      };

    } catch (error) {
      console.error('❌ D-ID talking head generation error:', error.response?.data || error.message);
      return {
        success: false,
        error: error.response?.data?.message || error.message,
        details: error.response?.data
      };
    }
  }

  // Poll for talk completion
  async pollTalkCompletion(talkId, maxAttempts = 60) {
    console.log(`🔄 Starting polling for D-ID talk: ${talkId}`);
    let attempts = 0;

    while (attempts < maxAttempts) {
      try {
        attempts++;
        console.log(`🔍 Polling attempt ${attempts}/${maxAttempts} for talk ${talkId}`);

        const response = await axios.get(
          `${this.baseUrl}/talks/${talkId}`,
          {
            headers: {
              'Authorization': `Basic ${this.apiKey}`,
              'Accept': 'application/json'
            }
          }
        );

        const talkData = response.data;
        console.log(`📊 Talk status: ${talkData.status}`);

        if (talkData.status === 'done') {
          console.log('🎉 D-ID talk generation completed successfully!');
          console.log('🎥 Video URL:', talkData.result_url);
          return talkData;
        } else if (talkData.status === 'error' || talkData.status === 'rejected') {
          console.error('❌ D-ID talk generation failed:', talkData.error?.description);
          throw new Error(talkData.error?.description || 'D-ID talk generation failed');
        } else if (talkData.status === 'created' || talkData.status === 'started') {
          // Continue polling
          console.log(`⏳ Talk still ${talkData.status}, waiting...`);
          await new Promise(resolve => setTimeout(resolve, 5000)); // 5 second interval
        } else {
          console.warn(`⚠️ Unknown talk status: ${talkData.status}`);
          await new Promise(resolve => setTimeout(resolve, 5000));
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
        await new Promise(resolve => setTimeout(resolve, 10000)); // Wait longer on error
      }
    }

    throw new Error(`D-ID talk generation timeout after ${maxAttempts} attempts`);
  }

  // Convert aspect ratio to D-ID format with expression
  convertAspectRatio(aspectRatio, expression = 'neutral') {
    // Create expression config with user-selected expression
    const expressionConfig = {
      driver_expressions: {
        expressions: [{
          start_frame: 0,
          expression: expression, // Use user-selected expression instead of hardcoded 'neutral'
          intensity: 1.0
        }]
      },
      result_format: 'mp4'
    };

    // All aspect ratios use the same expression configuration
    const supportedRatios = ['9:16', '16:9', '1:1', '4:3', '3:4'];
    
    if (supportedRatios.includes(aspectRatio)) {
      return expressionConfig;
    }
    
    return expressionConfig; // Default configuration
  }

  // Get talk status
  async getTalkStatus(talkId) {
    try {
      const response = await axios.get(
        `${this.baseUrl}/talks/${talkId}`,
        {
          headers: {
            'Authorization': `Basic ${this.apiKey}`,
            'Accept': 'application/json'
          }
        }
      );

      return {
        success: true,
        status: response.data.status,
        result_url: response.data.result_url,
        duration: response.data.duration,
        created_at: response.data.created_at,
        error: response.data.error
      };
    } catch (error) {
      console.error('❌ D-ID status check error:', error.response?.data || error.message);
      return {
        success: false,
        error: error.response?.data?.message || error.message
      };
    }
  }

  // Delete a talk
  async deleteTalk(talkId) {
    try {
      await axios.delete(
        `${this.baseUrl}/talks/${talkId}`,
        {
          headers: {
            'Authorization': `Basic ${this.apiKey}`,
            'Accept': 'application/json'
          }
        }
      );

      console.log(`🗑️ D-ID talk deleted: ${talkId}`);
      return { success: true };
    } catch (error) {
      console.error('❌ D-ID talk deletion error:', error.response?.data || error.message);
      return {
        success: false,
        error: error.response?.data?.message || error.message
      };
    }
  }

  // Download video from D-ID and upload to Cloudinary
  async downloadAndUploadVideo(videoUrl, projectId) {
    try {
      console.log('📥 Downloading video from D-ID...');

      // Download the video file (AWS S3 URLs don't need D-ID authorization)
      const response = await axios({
        method: 'GET',
        url: videoUrl,
        responseType: 'stream'
        // Note: No authorization headers needed for AWS S3 URLs
      });

      // Create temp file path
      const tempDir = path.join(__dirname, '../temp');
      if (!fs.existsSync(tempDir)) {
        fs.mkdirSync(tempDir, { recursive: true });
      }

      const tempVideoPath = path.join(tempDir, `temp_did_video_${projectId}_${Date.now()}.mp4`);

      // Save to temp file
      const writer = fs.createWriteStream(tempVideoPath);
      response.data.pipe(writer);

      await new Promise((resolve, reject) => {
        writer.on('finish', resolve);
        writer.on('error', reject);
      });

      console.log('✅ Video downloaded to temp file');

      // Upload to Cloudinary
      const fileName = `did_avatar_video_${projectId}_${Date.now()}`;
      const cloudinaryResult = await uploadVideo(tempVideoPath, fileName);

      // Clean up temp file
      cleanupLocalFile(tempVideoPath);

      console.log('☁️ Video uploaded to Cloudinary:', cloudinaryResult.secure_url);
      return cloudinaryResult;

    } catch (error) {
      console.error('❌ Error downloading/uploading D-ID video:', error);
      throw error;
    }
  }

  // Get account credits/usage
  async getCredits() {
    try {
      const response = await axios.get(
        `${this.baseUrl}/credits`,
        {
          headers: {
            'Authorization': `Basic ${this.apiKey}`,
            'Accept': 'application/json'
          }
        }
      );

      return {
        success: true,
        remaining: response.data.remaining,
        total: response.data.total,
        used: response.data.total - response.data.remaining
      };
    } catch (error) {
      console.error('❌ D-ID credits check error:', error.response?.data || error.message);
      return {
        success: false,
        error: error.response?.data?.message || error.message
      };
    }
  }
}

module.exports = new DIDService();