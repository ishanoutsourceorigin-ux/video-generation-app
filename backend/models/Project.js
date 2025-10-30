const mongoose = require('mongoose');

const projectSchema = new mongoose.Schema({
  userId: {
    type: String,
    required: true,
    index: true,
  },
  title: {
    type: String,
    required: true,
    trim: true,
  },
  description: {
    type: String,
    required: true,
    maxlength: 5000,
  },
  type: {
    type: String,
    enum: ['text-based', 'avatar-based'],
    required: true,
  },
  status: {
    type: String,
    enum: ['pending', 'processing', 'completed', 'failed'],
    default: 'pending',
  },
  
  // Video Configuration
  configuration: {
    aspectRatio: {
      type: String,
      enum: ['1280:720', '720:1280', '16:9', '9:16', '1:1'], // Support all formats including square
      default: '720:1280',
    },
    resolution: {
      type: Number,
      enum: [720, 1080],
      default: 1080,
    },
    duration: {
      type: Number,
      max: 60,
      required: false,
      default: 0, // 0 means auto-detect from audio
    },
    style: {
      type: String,
      default: 'cinematic',
    },
    voice: {
      type: String,
      default: 'default',
    },
    features: {
      withAudio: { type: Boolean, default: true },
      withSubtitles: { type: Boolean, default: true },
      withLipSync: { type: Boolean, default: true },
    },
  },

  // For avatar-based videos
  avatarId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Avatar',
    required: false,
  },
  script: {
    type: String,
    required: false,
    maxlength: 2000,
  },

  // Generated Content
  videoId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Video',
    required: false,
  },
  videoUrl: {
    type: String,
    required: false,
  },
  thumbnailUrl: {
    type: String,
    required: false,
  },

  // Processing Information
  provider: {
    type: String,
    enum: ['runway', 'elevenlabs-runway', 'elevenlabs-did', 'elevenlabs-a2e', 'synthesia', 'custom'],
    default: 'runway',
  },
  taskId: {
    type: String, // External provider task ID
    required: false,
  },
  processingStartedAt: {
    type: Date,
    required: false,
  },
  processingCompletedAt: {
    type: Date,
    required: false,
  },
  estimatedCompletionTime: {
    type: Date,
    required: false,
  },

  // Error Handling
  errorMessage: {
    type: String,
    required: false,
  },
  retryCount: {
    type: Number,
    default: 0,
    max: 3,
  },

  // Metadata
  fileSize: {
    type: Number, // Size in bytes
    required: false,
  },
  actualDuration: {
    type: Number, // Actual video duration in seconds
    required: false,
  },
  dimensions: {
    width: { type: Number, required: false },
    height: { type: Number, required: false },
  },

  // Analytics
  viewCount: {
    type: Number,
    default: 0,
  },
  downloadCount: {
    type: Number,
    default: 0,
  },
  shareCount: {
    type: Number,
    default: 0,
  },

  // Timestamps
  createdAt: {
    type: Date,
    default: Date.now,
  },
  updatedAt: {
    type: Date,
    default: Date.now,
  },

  // Tags for categorization
  tags: [{
    type: String,
    trim: true,
  }],

  // Privacy settings
  isPublic: {
    type: Boolean,
    default: false,
  },
  sharedWith: [{
    userId: String,
    permission: {
      type: String,
      enum: ['view', 'edit'],
      default: 'view',
    },
  }],
});

// Indexes for efficient queries
projectSchema.index({ userId: 1, createdAt: -1 });
projectSchema.index({ status: 1 });
projectSchema.index({ type: 1 });
projectSchema.index({ 'configuration.aspectRatio': 1 });
projectSchema.index({ 'configuration.duration': 1 });

// Update timestamp on save
projectSchema.pre('save', function(next) {
  this.updatedAt = Date.now();
  next();
});

// Virtual for processing time
projectSchema.virtual('processingTime').get(function() {
  if (this.processingStartedAt && this.processingCompletedAt) {
    return this.processingCompletedAt - this.processingStartedAt;
  }
  return null;
});

// Virtual for estimated time remaining
projectSchema.virtual('estimatedTimeRemaining').get(function() {
  if (this.estimatedCompletionTime && this.status === 'processing') {
    const remaining = this.estimatedCompletionTime - new Date();
    return Math.max(0, Math.ceil(remaining / 1000)); // Return seconds
  }
  return null;
});

// Methods
projectSchema.methods.updateStatus = function(status, additionalData = {}) {
  this.status = status;
  
  if (status === 'processing' && !this.processingStartedAt) {
    this.processingStartedAt = new Date();
    
    // Estimate completion time based on configuration
    const baseTime = this.configuration.duration * 15; // 15 seconds per video second
    const resolutionMultiplier = this.configuration.resolution === 1080 ? 1.2 : 1;
    const typeMultiplier = this.type === 'text-based' ? 1.5 : 1; // Text-based takes longer
    
    const estimatedSeconds = baseTime * resolutionMultiplier * typeMultiplier;
    this.estimatedCompletionTime = new Date(Date.now() + estimatedSeconds * 1000);
  }
  
  if (status === 'completed' || status === 'failed') {
    this.processingCompletedAt = new Date();
  }
  
  // Merge additional data
  Object.assign(this, additionalData);
  
  return this.save();
};

projectSchema.methods.incrementRetry = function() {
  this.retryCount += 1;
  return this.save();
};

projectSchema.methods.incrementView = function() {
  this.viewCount += 1;
  return this.save();
};

projectSchema.methods.incrementDownload = function() {
  this.downloadCount += 1;
  return this.save();
};

projectSchema.methods.incrementShare = function() {
  this.shareCount += 1;
  return this.save();
};

// Static methods
projectSchema.statics.getByUser = function(userId, options = {}) {
  const query = { userId };
  
  if (options.status) {
    query.status = options.status;
  }
  
  if (options.type) {
    query.type = options.type;
  }
  
  return this.find(query)
    .populate('avatarId', 'name profession imageUrl')
    .populate('videoId')
    .sort({ createdAt: -1 })
    .limit(options.limit || 20)
    .skip(options.skip || 0);
};

projectSchema.statics.getStats = function(userId) {
  return this.aggregate([
    { $match: { userId } },
    {
      $group: {
        _id: null,
        totalProjects: { $sum: 1 },
        completedProjects: { $sum: { $cond: [{ $eq: ['$status', 'completed'] }, 1, 0] } },
        processingProjects: { $sum: { $cond: [{ $eq: ['$status', 'processing'] }, 1, 0] } },
        failedProjects: { $sum: { $cond: [{ $eq: ['$status', 'failed'] }, 1, 0] } },
        totalViews: { $sum: '$viewCount' },
        totalDownloads: { $sum: '$downloadCount' },
        totalShares: { $sum: '$shareCount' },
        avgDuration: { $avg: '$configuration.duration' },
        totalVideoTime: { $sum: '$actualDuration' },
      }
    }
  ]);
};

module.exports = mongoose.model('Project', projectSchema);