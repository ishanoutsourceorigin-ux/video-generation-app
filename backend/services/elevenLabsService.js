const axios = require('axios');
const FormData = require('form-data');
const fs = require('fs');

class ElevenLabsService {
  constructor() {
    this.apiKey = process.env.ELEVENLABS_API_KEY;
    this.baseURL = 'https://api.elevenlabs.io/v1';
    
    this.client = axios.create({
      baseURL: this.baseURL,
      headers: {
        'xi-api-key': this.apiKey,
        'Content-Type': 'application/json',
      },
    });
  }

  // Clone a voice from audio file
  async cloneVoice(audioFilePath, voiceName, description = '') {
    try {
      const formData = new FormData();
      formData.append('name', voiceName);
      formData.append('description', description);
      formData.append('files', fs.createReadStream(audioFilePath));

      const response = await axios.post(`${this.baseURL}/voices/add`, formData, {
        headers: {
          'xi-api-key': this.apiKey,
          ...formData.getHeaders(),
        },
      });

      return response.data;
    } catch (error) {
      console.error('ElevenLabs clone voice error:', error.response?.data || error.message);
      throw new Error(`Failed to clone voice: ${error.response?.data?.detail?.message || error.message}`);
    }
  }

  // Generate speech from text
  async textToSpeech(text, voiceId, options = {}) {
    try {
      const payload = {
        text: text,
        model_id: options.modelId || 'eleven_monolingual_v1',
        voice_settings: {
          stability: options.stability || 0.5,
          similarity_boost: options.similarityBoost || 0.75,
          style: options.style || 0.0,
          use_speaker_boost: options.useSpeakerBoost || true,
        },
      };

      const response = await this.client.post(`/text-to-speech/${voiceId}`, payload, {
        responseType: 'arraybuffer',
        headers: {
          'Accept': 'audio/mpeg',
          'Content-Type': 'application/json',
          'xi-api-key': this.apiKey,
        },
      });

      return Buffer.from(response.data);
    } catch (error) {
      console.error('ElevenLabs TTS error:', error.response?.data || error.message);
      throw new Error(`Failed to generate speech: ${error.response?.data?.detail?.message || error.message}`);
    }
  }

  // Get all available voices
  async getVoices() {
    try {
      const response = await this.client.get('/voices');
      return response.data;
    } catch (error) {
      console.error('ElevenLabs get voices error:', error.response?.data || error.message);
      throw new Error(`Failed to get voices: ${error.response?.data?.detail?.message || error.message}`);
    }
  }

  // Get specific voice details
  async getVoice(voiceId) {
    try {
      const response = await this.client.get(`/voices/${voiceId}`);
      return response.data;
    } catch (error) {
      console.error('ElevenLabs get voice error:', error.response?.data || error.message);
      throw new Error(`Failed to get voice: ${error.response?.data?.detail?.message || error.message}`);
    }
  }

  // Delete a voice
  async deleteVoice(voiceId) {
    try {
      const response = await this.client.delete(`/voices/${voiceId}`);
      return response.data;
    } catch (error) {
      console.error('ElevenLabs delete voice error:', error.response?.data || error.message);
      throw new Error(`Failed to delete voice: ${error.response?.data?.detail?.message || error.message}`);
    }
  }

  // Get voice settings
  async getVoiceSettings(voiceId) {
    try {
      const response = await this.client.get(`/voices/${voiceId}/settings`);
      return response.data;
    } catch (error) {
      console.error('ElevenLabs get voice settings error:', error.response?.data || error.message);
      throw new Error(`Failed to get voice settings: ${error.response?.data?.detail?.message || error.message}`);
    }
  }

  // Update voice settings
  async updateVoiceSettings(voiceId, settings) {
    try {
      const response = await this.client.post(`/voices/${voiceId}/settings/edit`, settings);
      return response.data;
    } catch (error) {
      console.error('ElevenLabs update voice settings error:', error.response?.data || error.message);
      throw new Error(`Failed to update voice settings: ${error.response?.data?.detail?.message || error.message}`);
    }
  }

  // Get user subscription info
  async getUserSubscription() {
    try {
      const response = await this.client.get('/user/subscription');
      return response.data;
    } catch (error) {
      console.error('ElevenLabs get user subscription error:', error.response?.data || error.message);
      throw new Error(`Failed to get user subscription: ${error.response?.data?.detail?.message || error.message}`);
    }
  }

  // Get usage statistics
  async getUsageStatistics() {
    try {
      const response = await this.client.get('/user');
      return response.data;
    } catch (error) {
      console.error('ElevenLabs get usage error:', error.response?.data || error.message);
      throw new Error(`Failed to get usage statistics: ${error.response?.data?.detail?.message || error.message}`);
    }
  }
}

module.exports = new ElevenLabsService();