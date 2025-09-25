const axios = require('axios');
const FormData = require('form-data');

class DIDService {
  constructor() {
    this.apiKey = process.env.D_ID_API_KEY;
    this.baseURL = 'https://api.d-id.com';
    
    this.client = axios.create({
      baseURL: this.baseURL,
      headers: {
        'Authorization': `Basic ${this.apiKey}`,
        'Content-Type': 'application/json',
      },
    });
  }

  // Create a talking video with D-ID
  async createTalkingVideo(imageUrl, audioUrl, options = {}) {
    try {
      const payload = {
        source_url: imageUrl,
        script: {
          type: 'audio',
          audio_url: audioUrl,
        },
        config: {
          fluent: options.fluent || true,
          pad_audio: options.padAudio || 0.0,
          stitch: options.stitch || true,
          result_format: options.resultFormat || 'mp4',
        },
        ...options.extraConfig
      };

      const response = await this.client.post('/talks', payload);
      return response.data;
    } catch (error) {
      console.error('D-ID create talking video error:', error.response?.data || error.message);
      throw new Error(`Failed to create talking video: ${error.response?.data?.message || error.message}`);
    }
  }

  // Get video status
  async getVideoStatus(videoId) {
    try {
      const response = await this.client.get(`/talks/${videoId}`);
      return response.data;
    } catch (error) {
      console.error('D-ID get video status error:', error.response?.data || error.message);
      throw new Error(`Failed to get video status: ${error.response?.data?.message || error.message}`);
    }
  }

  // Delete a video
  async deleteVideo(videoId) {
    try {
      const response = await this.client.delete(`/talks/${videoId}`);
      return response.data;
    } catch (error) {
      console.error('D-ID delete video error:', error.response?.data || error.message);
      throw new Error(`Failed to delete video: ${error.response?.data?.message || error.message}`);
    }
  }

  // Get account credits
  async getCredits() {
    try {
      const response = await this.client.get('/credits');
      return response.data;
    } catch (error) {
      console.error('D-ID get credits error:', error.response?.data || error.message);
      throw new Error(`Failed to get credits: ${error.response?.data?.message || error.message}`);
    }
  }

  // Create a presenter (for consistent avatar appearance)
  async createPresenter(imageUrl, name) {
    try {
      const payload = {
        source_url: imageUrl,
        presenter_name: name,
        driver_id: 'bank://lively/',
      };

      const response = await this.client.post('/clips/presenters', payload);
      return response.data;
    } catch (error) {
      console.error('D-ID create presenter error:', error.response?.data || error.message);
      throw new Error(`Failed to create presenter: ${error.response?.data?.message || error.message}`);
    }
  }

  // Get all presenters
  async getPresenters() {
    try {
      const response = await this.client.get('/clips/presenters');
      return response.data;
    } catch (error) {
      console.error('D-ID get presenters error:', error.response?.data || error.message);
      throw new Error(`Failed to get presenters: ${error.response?.data?.message || error.message}`);
    }
  }
}

module.exports = new DIDService();