const express = require('express');
const multer = require('multer');
const cloudinary = require('cloudinary').v2;
const axios = require('axios');
const FormData = require('form-data');
const fs = require('fs');
const path = require('path');
const { v4: uuidv4 } = require('uuid');

const Avatar = require('../models/Avatar');

const router = express.Router();

// Configure Cloudinary
cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET,
  secure: true, // Use HTTPS
});

// Log Cloudinary configuration (without secrets)
console.log('☁️ Cloudinary configured:', {
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME ? '✅ Set' : '❌ Missing',
  api_key: process.env.CLOUDINARY_API_KEY ? '✅ Set' : '❌ Missing',
  api_secret: process.env.CLOUDINARY_API_SECRET ? '✅ Set' : '❌ Missing',
});

// Configure multer for file uploads
const upload = multer({
  dest: 'uploads/',
  limits: {
    fileSize: 10 * 1024 * 1024, // 10MB limit
  },
  fileFilter: (req, file, cb) => {
    console.log(`📁 File received: ${file.fieldname}`);
    console.log(`📄 Original name: ${file.originalname}`);
    console.log(`🔍 MIME type: ${file.mimetype}`);
    console.log(`📊 Size: ${file.size} bytes`);
    
    if (file.fieldname === 'image') {
      // Allow image files by MIME type or file extension
      const isImageMimeType = file.mimetype.startsWith('image/');
      const isImageExtension = /\.(jpg|jpeg|png|gif|bmp|webp)$/i.test(file.originalname);
      
      if (!isImageMimeType && !isImageExtension) {
        console.log(`❌ Rejected image file - Invalid MIME type: ${file.mimetype} and extension: ${file.originalname}`);
        return cb(new Error('Only image files are allowed for avatar photo'));
      }
      console.log(`✅ Accepted image file: ${file.mimetype} (${file.originalname})`);
    } else if (file.fieldname === 'voice') {
      // Allow audio files by MIME type or file extension
      const allowedAudioTypes = ['audio/mpeg', 'audio/wav', 'audio/mp4', 'audio/aac'];
      const isAudioMimeType = allowedAudioTypes.includes(file.mimetype);
      const isAudioExtension = /\.(mp3|wav|m4a|aac)$/i.test(file.originalname);
      
      if (!isAudioMimeType && !isAudioExtension) {
        console.log(`❌ Rejected audio file - Invalid MIME type: ${file.mimetype} and extension: ${file.originalname}`);
        return cb(new Error('Only MP3, WAV, M4A, and AAC audio files are allowed'));
      }
      console.log(`✅ Accepted audio file: ${file.mimetype} (${file.originalname})`);
    }
    cb(null, true);
  },
});

// Helper function to upload to Cloudinary
const uploadToCloudinary = async (filePath, resourceType = 'auto', folder = 'avatars', options = {}) => {
  try {
    // Generate current timestamp to avoid stale request errors
    const timestamp = Math.round(Date.now() / 1000);
    
    const uploadOptions = {
      resource_type: resourceType,
      folder: folder,
      use_filename: true,
      unique_filename: true,
      timestamp: timestamp,
      // Add timeout and retry configuration
      timeout: 60000, // 60 seconds timeout
      ...options, // Merge additional options
    };
    
    const result = await cloudinary.uploader.upload(filePath, uploadOptions);
    return result;
  } catch (error) {
    console.error('Cloudinary upload error:', error);
    console.error('Error details:', {
      message: error.message,
      http_code: error.http_code,
      timestamp: Math.round(Date.now() / 1000)
    });
    
    // If it's a stale request error, retry once with new timestamp
    if (error.message && error.message.includes('Stale request')) {
      console.log('🔄 Retrying Cloudinary upload due to stale request...');
      try {
        const newTimestamp = Math.round(Date.now() / 1000);
        const retryResult = await cloudinary.uploader.upload(filePath, {
          resource_type: resourceType,
          folder: folder,
          use_filename: true,
          unique_filename: true,
          timestamp: newTimestamp,
          timeout: 60000,
        });
        console.log('✅ Retry successful');
        return retryResult;
      } catch (retryError) {
        console.error('❌ Retry failed:', retryError);
        throw new Error(`Failed to upload file to Cloudinary after retry: ${retryError.message}`);
      }
    }
    
    throw new Error(`Failed to upload file to Cloudinary: ${error.message}`);
  }
};

// Helper function to clone voice with ElevenLabs
const cloneVoice = async (voiceFilePath, voiceName) => {
  try {
    const formData = new FormData();
    formData.append('name', voiceName);
    formData.append('files', fs.createReadStream(voiceFilePath));
    formData.append('description', `AI cloned voice for ${voiceName}`);

    const response = await axios.post(
      'https://api.elevenlabs.io/v1/voices/add',
      formData,
      {
        headers: {
          'Accept': 'application/json',
          'xi-api-key': process.env.ELEVENLABS_API_KEY,
          ...formData.getHeaders(),
        },
      }
    );

    return response.data.voice_id;
  } catch (error) {
    console.error('ElevenLabs voice cloning error:', error.response?.data || error.message);
    throw new Error('Failed to clone voice with ElevenLabs');
  }
};

// POST /api/avatars/create - Create new avatar
router.post('/create', upload.fields([
  { name: 'image', maxCount: 1 },
  { name: 'voice', maxCount: 1 }
]), async (req, res) => {
  let uploadedFiles = [];
  
  try {
    console.log('🎯 Avatar creation request received');
    console.log('📝 Request body:', req.body);
    console.log('📁 Files received:', req.files);
    
    const { name, profession, gender } = req.body;
    const userId = req.user.uid;

    console.log(`👤 User ID: ${userId}`);
    console.log(`📋 Avatar details: ${name}, ${profession}, ${gender}`);

    // Validation
    if (!name || !profession || !gender) {
      return res.status(400).json({
        error: 'Missing required fields: name, profession, gender'
      });
    }

    if (!req.files?.image || !req.files?.voice) {
      console.log('❌ Missing files - Image:', !!req.files?.image, 'Voice:', !!req.files?.voice);
      return res.status(400).json({
        error: 'Both image and voice files are required'
      });
    }

    const imageFile = req.files.image[0];
    const voiceFile = req.files.voice[0];
    
    console.log('🖼️ Image file details:', {
      originalname: imageFile.originalname,
      mimetype: imageFile.mimetype,
      size: imageFile.size
    });
    
    console.log('🎵 Voice file details:', {
      originalname: voiceFile.originalname,
      mimetype: voiceFile.mimetype,
      size: voiceFile.size
    });

    // Upload image to Cloudinary
    console.log('Uploading image to Cloudinary...');
    const imageUpload = await uploadToCloudinary(imageFile.path, 'image', 'avatars/images');
    uploadedFiles.push({ type: 'image', public_id: imageUpload.public_id });

    // Upload voice to Cloudinary with MP3 conversion
    console.log('Uploading voice to Cloudinary...');
    const voiceUpload = await uploadToCloudinary(voiceFile.path, 'raw', 'avatars/voices', {
      format: 'mp3', // Convert to MP3 format
      audio_codec: 'mp3',
    });
    uploadedFiles.push({ type: 'voice', public_id: voiceUpload.public_id });

    // Create avatar record in database
    const avatar = new Avatar({
      userId,
      name,
      profession,
      gender,
      expressions: [{
        start_frame: 0,
        expression: 'neutral',
        intensity: 1.0
      }],
      imageUrl: imageUpload.secure_url,
      voiceUrl: voiceUpload.secure_url,
      cloudinaryImageId: imageUpload.public_id,
      cloudinaryVoiceId: voiceUpload.public_id,
      status: 'processing',
      metadata: {
        originalImageName: imageFile.originalname,
        originalVoiceName: voiceFile.originalname,
        imageSize: imageFile.size,
        voiceSize: voiceFile.size,
      }
    });

    await avatar.save();

    // Clone voice with ElevenLabs (async process)
    console.log('Starting voice cloning with ElevenLabs...');
    try {
      const voiceId = await cloneVoice(voiceFile.path, `${name}_${Date.now()}`);
      
      // Update avatar with voice ID
      avatar.voiceId = voiceId;
      avatar.status = 'active';
      await avatar.save();
      
      console.log('Voice cloning completed successfully');
    } catch (voiceError) {
      console.error('Voice cloning failed:', voiceError);
      avatar.status = 'failed';
      await avatar.save();
    }

    // Clean up uploaded files
    fs.unlinkSync(imageFile.path);
    fs.unlinkSync(voiceFile.path);

    res.status(201).json({
      message: 'Avatar created successfully',
      avatar: {
        id: avatar._id,
        name: avatar.name,
        profession: avatar.profession,
        gender: avatar.gender,
        imageUrl: avatar.imageUrl,
        status: avatar.status,
        createdAt: avatar.createdAt,
      }
    });

  } catch (error) {
    console.error('Create avatar error:', error);

    // Clean up uploaded files on error
    if (req.files?.image?.[0]?.path) {
      try { fs.unlinkSync(req.files.image[0].path); } catch (e) {}
    }
    if (req.files?.voice?.[0]?.path) {
      try { fs.unlinkSync(req.files.voice[0].path); } catch (e) {}
    }

    // Clean up Cloudinary uploads on error
    for (const file of uploadedFiles) {
      try {
        await cloudinary.uploader.destroy(file.public_id, { 
          resource_type: file.type === 'image' ? 'image' : 'raw' 
        });
      } catch (cleanupError) {
        console.error('Cloudinary cleanup error:', cleanupError);
      }
    }

    res.status(500).json({
      error: error.message || 'Failed to create avatar'
    });
  }
});

// GET /api/avatars - Get user's avatars
router.get('/', async (req, res) => {
  try {
    const userId = req.user.uid;
    const { status, limit = 20, page = 1 } = req.query;

    // Always filter by authenticated user ID
    const query = { userId };
    if (status) {
      query.status = status;
    }
    
    console.log(`🔍 Fetching avatars - User ID: ${userId}, Query:`, query);

    const skip = (parseInt(page) - 1) * parseInt(limit);

    const avatars = await Avatar.find(query)
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(parseInt(limit))
      .select('-cloudinaryImageId -cloudinaryVoiceId -voiceId');

    const total = await Avatar.countDocuments(query);

    res.json({
      avatars,
      pagination: {
        total,
        page: parseInt(page),
        limit: parseInt(limit),
        pages: Math.ceil(total / parseInt(limit))
      }
    });

  } catch (error) {
    console.error('Get avatars error:', error);
    res.status(500).json({
      error: 'Failed to fetch avatars'
    });
  }
});

// GET /api/avatars/:id - Get specific avatar
router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.uid;

    const avatar = await Avatar.findOne({ _id: id, userId })
      .select('-cloudinaryImageId -cloudinaryVoiceId');

    if (!avatar) {
      return res.status(404).json({
        error: 'Avatar not found'
      });
    }

    res.json({ avatar });

  } catch (error) {
    console.error('Get avatar error:', error);
    res.status(500).json({
      error: 'Failed to fetch avatar'
    });
  }
});

// DELETE /api/avatars/:id - Delete avatar
router.delete('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.uid;

    const avatar = await Avatar.findOne({ _id: id, userId });

    if (!avatar) {
      return res.status(404).json({
        error: 'Avatar not found'
      });
    }

    // Delete from Cloudinary
    try {
      await cloudinary.uploader.destroy(avatar.cloudinaryImageId, { resource_type: 'image' });
      await cloudinary.uploader.destroy(avatar.cloudinaryVoiceId, { resource_type: 'raw' });
    } catch (cloudinaryError) {
      console.error('Cloudinary deletion error:', cloudinaryError);
    }

    // Delete voice from ElevenLabs
    if (avatar.voiceId) {
      try {
        await axios.delete(`https://api.elevenlabs.io/v1/voices/${avatar.voiceId}`, {
          headers: {
            'xi-api-key': process.env.ELEVENLABS_API_KEY,
          },
        });
      } catch (elevenLabsError) {
        console.error('ElevenLabs voice deletion error:', elevenLabsError);
      }
    }

    // Delete from database
    await Avatar.findByIdAndDelete(id);

    res.json({
      message: 'Avatar deleted successfully'
    });

  } catch (error) {
    console.error('Delete avatar error:', error);
    res.status(500).json({
      error: 'Failed to delete avatar'
    });
  }
});

module.exports = router;