const mongoose = require('mongoose');

const videoSchema = new mongoose.Schema({
  userId: {
    type: String,
    required: true,
    index: true,
  },
  avatarId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Avatar',
    required: false, // Not required for text-based videos
  },
  title: {
    type: String,
    required: true,
    trim: true,
  },
  script: {
    type: String,
    required: true,
  },
  videoUrl: {
    type: String,
    required: false, // Will be set after video generation
  },
  thumbnailUrl: {
    type: String,
    required: false,
  },
  cloudinaryVideoId: {
    type: String,
    required: false,
  },
  runwayTaskId: {
    type: String,
    required: false, // Runway API task ID for tracking
  },
  status: {
    type: String,
    enum: ['queued', 'processing', 'completed', 'failed'],
    default: 'queued',
  },
  duration: {
    type: Number, // Duration in seconds
    required: false,
  },
  fileSize: {
    type: Number, // File size in bytes
    required: false,
  },
  resolution: {
    width: Number,
    height: Number,
  },
  processingStartedAt: {
    type: Date,
    required: false,
  },
  processingCompletedAt: {
    type: Date,
    required: false,
  },
  createdAt: {
    type: Date,
    default: Date.now,
  },
  updatedAt: {
    type: Date,
    default: Date.now,
  },
  errorMessage: {
    type: String,
    required: false,
  },
  metadata: {
    type: { type: String, default: 'avatar' }, // 'avatar' or 'text-based'
    description: String, // For text-based videos
    style: String, // Video style (Professional, Casual, etc.)
    voice: String, // Voice type for narration
    scriptLength: Number,
    estimatedDuration: Number,
    provider: String, // 'did', 'runway', 'ai-text-generator', etc.
    generationMethod: String, // Description of how video was generated
    voiceSettings: {
      stability: { type: Number, default: 0.5 },
      similarityBoost: { type: Number, default: 0.75 },
    },
  }
});

// Update timestamp on save
videoSchema.pre('save', function(next) {
  this.updatedAt = Date.now();
  next();
});

// Index for efficient queries
videoSchema.index({ userId: 1, createdAt: -1 });
videoSchema.index({ status: 1 });
videoSchema.index({ avatarId: 1 });

module.exports = mongoose.model('Video', videoSchema);