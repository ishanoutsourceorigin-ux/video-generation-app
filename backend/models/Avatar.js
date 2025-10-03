const mongoose = require('mongoose');

const avatarSchema = new mongoose.Schema({
  userId: {
    type: String,
    required: true,
    index: true,
  },
  name: {
    type: String,
    required: true,
    trim: true,
  },
  profession: {
    type: String,
    required: true,
    trim: true,
  },
  gender: {
    type: String,
    enum: ['Male', 'Female', 'Other'],
    required: true,
  },
  // style field removed as requested
  expressions: [{
    start_frame: {
      type: Number,
      default: 0
    },
    expression: {
      type: String,
      enum: ['neutral', 'happy', 'surprise', 'serious'],
      default: 'neutral'
    },
    intensity: {
      type: Number,
      default: 1.0,
      min: 0,
      max: 1
    }
  }],
  imageUrl: {
    type: String,
    required: true,
  },
  voiceUrl: {
    type: String,
    required: true,
  },
  voiceId: {
    type: String, // ElevenLabs voice ID
    required: false, // Will be set after voice cloning
  },
  cloudinaryImageId: {
    type: String,
    required: true,
  },
  cloudinaryVoiceId: {
    type: String,
    required: true,
  },
  status: {
    type: String,
    enum: ['processing', 'active', 'failed'],
    default: 'processing',
  },
  isActive: {
    type: Boolean,
    default: true,
  },
  createdAt: {
    type: Date,
    default: Date.now,
  },
  updatedAt: {
    type: Date,
    default: Date.now,
  },
  metadata: {
    originalImageName: String,
    originalVoiceName: String,
    imageSize: Number,
    voiceSize: Number,
    voiceDuration: Number,
  }
});

// Update timestamp on save
avatarSchema.pre('save', function(next) {
  this.updatedAt = Date.now();
  next();
});

// Index for efficient queries
avatarSchema.index({ userId: 1, createdAt: -1 });
avatarSchema.index({ status: 1 });

module.exports = mongoose.model('Avatar', avatarSchema);