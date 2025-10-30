const axios = require('axios');
const fs = require('fs');
const path = require('path');

class A2EService {
  constructor() {
    this.apiUrl = 'https://video.a2e.ai/api/v1/talkingPhoto';
    this.apiToken = process.env.A2E_API_TOKEN;
    
    if (!this.apiToken) {
      console.error('❌ A2E API token not found in environment variables');
      throw new Error('A2E_API_TOKEN is required');
    }
    
    console.log('✅ A2E Service initialized');
  }

  /**
   * Start talking photo generation with A2E API
   * @param {Object} params - Generation parameters
   * @param {string} params.name - Task name
   * @param {string} params.image_url - Avatar image URL
   * @param {string} params.audio_url - Generated audio URL
   * @param {string} params.prompt - Generation prompt
   * @param {string} params.negative_prompt - Negative prompt
   * @returns {Promise<Object>} A2E API response
   */
  async startTalkingPhoto({
    name,
    image_url,
    audio_url,
    duration = 0, // 0 means auto-detect duration from audio
    prompt = "high quality, clear, cinematic, natural speaking, perfect lip sync",
    negative_prompt = "blurry, low quality, chaotic, deformed, watermark, bad anatomy, shaky camera, distorted face, unnatural movement"
  }) {
    try {
      console.log('🎬 Starting A2E talking photo generation...');
      console.log('📝 Task name:', name);
      console.log('🖼️ Image URL:', image_url);
      console.log('🎵 Audio URL:', audio_url);
      console.log('⏱️ Duration:', duration, '(0 = auto-detect)');
      console.log('📋 Prompt:', prompt);
      console.log('🚫 Negative prompt:', negative_prompt);

      const requestData = {
        name,
        image_url,
        audio_url,
        duration,
        prompt,
        negative_prompt
      };

      // Remove undefined/null values
      Object.keys(requestData).forEach(key => {
        if (requestData[key] === undefined || requestData[key] === null) {
          delete requestData[key];
        }
      });

      const response = await axios.post(
        `${this.apiUrl}/start`,
        requestData,
        {
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${this.apiToken}`,
          },
          timeout: 30000, // 30 second timeout
        }
      );

      console.log('✅ A2E API Response:', JSON.stringify(response.data, null, 2));

      if (response.data.code === 200 || response.data.code === 0) {
        return {
          success: true,
          taskId: response.data.data?._id || response.data.data?.taskId || response.data.data?.id,
          message: response.data.message || 'Task created successfully',
          data: response.data.data
        };
      } else {
        throw new Error(`A2E API Error: ${response.data.message || 'Unknown error'}`);
      }

    } catch (error) {
      console.error('❌ A2E talking photo generation failed:', error.message);
      
      if (error.response) {
        console.error('📄 Response status:', error.response.status);
        console.error('📄 Response data:', error.response.data);
        throw new Error(`A2E API Error (${error.response.status}): ${error.response.data?.message || error.message}`);
      } else if (error.request) {
        console.error('📡 No response received from A2E API');
        throw new Error('Network error: Unable to connect to A2E API');
      } else {
        throw new Error(`A2E Service Error: ${error.message}`);
      }
    }
  }

  /**
   * Check task status (if A2E provides status endpoint)
   * @param {string} taskId - Task ID from start response
   * @returns {Promise<Object>} Task status
   */
  async getTaskStatus(taskId) {
    try {
      console.log('🔍 Checking A2E task status for:', taskId);

      const response = await axios.get(
        `${this.apiUrl}/status/${taskId}`,
        {
          headers: {
            'Authorization': `Bearer ${this.apiToken}`,
          },
          timeout: 10000,
        }
      );

      console.log('📊 A2E Status Response:', response.data);
      return response.data;

    } catch (error) {
      console.error('❌ Failed to get A2E task status:', error.message);
      
      if (error.response?.status === 404) {
        return {
          success: false,
          message: 'Task not found'
        };
      }
      
      throw error;
    }
  }

  /**
   * Generate optimized prompts based on avatar type and content
   * @param {Object} options - Generation options
   * @param {string} options.avatarType - Type of avatar (professional, casual, etc.)
   * @param {string} options.content - Script content for context
   * @returns {Object} Generated prompts
   */
  generatePrompts({ avatarType = 'professional', content = '' }) {
    const basePrompt = "high quality, clear, cinematic, natural speaking, perfect lip sync, professional presenter";
    const baseNegativePrompt = "blurry, low quality, chaotic, deformed, watermark, bad anatomy, shaky camera, distorted face, unnatural movement";

    let typePrompt = '';
    switch (avatarType) {
      case 'business':
        typePrompt = ', professional business person, corporate setting';
        break;
      case 'casual':
        typePrompt = ', casual friendly person, approachable';
        break;
      case 'teacher':
        typePrompt = ', educational presenter, clear articulation';
        break;
      default:
        typePrompt = ', professional presenter';
    }

    return {
      prompt: basePrompt + typePrompt,
      negative_prompt: baseNegativePrompt + ', amateur, unprofessional, awkward expressions'
    };
  }

  // Note: Duration estimation removed - A2E API automatically determines optimal duration based on audio length

  /**
   * Validate required parameters for talking photo generation
   * @param {Object} params - Parameters to validate
   * @returns {Object} Validation result
   */
  validateParams(params) {
    const errors = [];

    if (!params.name || typeof params.name !== 'string') {
      errors.push('Task name is required and must be a string');
    }

    if (!params.image_url || typeof params.image_url !== 'string') {
      errors.push('Image URL is required and must be a valid URL');
    }

    // Audio URL is optional but if provided should be valid
    if (params.audio_url && typeof params.audio_url !== 'string') {
      errors.push('Audio URL must be a valid URL string');
    }

    if (params.duration !== undefined && (typeof params.duration !== 'number' || params.duration < 0)) {
      errors.push('Duration must be a positive number');
    }

    return {
      valid: errors.length === 0,
      errors
    };
  }
}

module.exports = new A2EService();