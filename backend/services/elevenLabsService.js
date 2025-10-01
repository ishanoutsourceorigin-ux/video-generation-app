const axios = require('axios');
const FormData = require('form-data');
const fs = require('fs');
const cloudinary = require('cloudinary').v2;

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

  // Generate speech for avatar videos (with Cloudinary upload)
  async generateSpeech(script, voiceId, options = {}) {
    try {
      console.log('🎙️ Generating speech for avatar video...');
      console.log('📝 Script length:', script.length);
      console.log('🗣️ Voice ID:', voiceId);

      // Generate audio using text-to-speech
      const audioBuffer = await this.textToSpeech(script, voiceId, {
        stability: options.stability || 0.75,
        similarityBoost: options.similarityBoost || 0.85,
        style: options.style || 0.2,
        useSpeakerBoost: true,
        modelId: 'eleven_multilingual_v2' // Better for avatar videos
      });

      console.log('✅ Audio generated, uploading to Cloudinary...');

      // Upload audio to Cloudinary
      const timestamp = Date.now();
      const cloudinaryResult = await new Promise((resolve, reject) => {
        const uploadStream = cloudinary.uploader.upload_stream(
          {
            resource_type: 'video', // Audio files are treated as video in Cloudinary
            folder: 'avatar-audio',
            public_id: `avatar_audio_${timestamp}`,
            format: 'mp3',
            overwrite: true
          },
          (error, result) => {
            if (error) {
              console.error('❌ Cloudinary upload error:', error);
              reject(error);
            } else {
              console.log('✅ Audio uploaded to Cloudinary:', result.secure_url);
              resolve(result);
            }
          }
        );
        
        uploadStream.end(audioBuffer);
      });

      return {
        success: true,
        audioUrl: cloudinaryResult.secure_url,
        duration: cloudinaryResult.duration || 8,
        fileSize: cloudinaryResult.bytes,
        publicId: cloudinaryResult.public_id
      };

    } catch (error) {
      console.error('❌ Avatar speech generation error:', error);
      return {
        success: false,
        error: error.message
      };
    }
  }

  // Clone voice from Cloudinary URL (for avatar creation)
  async cloneVoiceFromUrl(audioUrl, voiceName, description = '') {
    try {
      console.log('🎵 Cloning voice from URL:', audioUrl);
      
      // Download audio from Cloudinary
      const audioResponse = await axios.get(audioUrl, {
        responseType: 'stream'
      });

      // Create temporary file
      const tempFilePath = `/tmp/voice_${Date.now()}.mp3`;
      const writer = fs.createWriteStream(tempFilePath);
      audioResponse.data.pipe(writer);

      await new Promise((resolve, reject) => {
        writer.on('finish', resolve);
        writer.on('error', reject);
      });

      // Clone voice using temporary file
      const result = await this.cloneVoice(tempFilePath, voiceName, description);
      
      // Clean up temporary file
      try {
        fs.unlinkSync(tempFilePath);
      } catch (cleanupError) {
        console.warn('⚠️ Failed to clean up temp file:', cleanupError.message);
      }

      console.log('✅ Voice cloned successfully:', result.voice_id);
      return result;

    } catch (error) {
      console.error('❌ Voice cloning from URL error:', error);
      throw new Error(`Failed to clone voice from URL: ${error.message}`);
    }
  }
}

module.exports = new ElevenLabsService();