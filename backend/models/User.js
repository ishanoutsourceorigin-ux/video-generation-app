const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
  uid: {
    type: String,
    required: true,
    unique: true,
    index: true,
  },
  email: {
    type: String,
    required: true,
    unique: true,
    lowercase: true,
    trim: true,
  },
  name: {
    type: String,
    required: true,
    trim: true,
  },
  photoURL: {
    type: String,
    default: null,
  },
  phoneNumber: {
    type: String,
    default: null,
  },
  
  // Subscription & Credits
  plan: {
    type: String,
    enum: ['free', 'starter', 'pro', 'enterprise'],
    default: 'free',
  },
  
  // Credit System (Enhanced for Payment Integration)
  availableCredits: {
    type: Number,
    default: 0, // New users start with 0 credits (must purchase)
    min: 0,
  },
  reservedCredits: {
    type: Number,
    default: 0, // Credits reserved for pending video generation
    min: 0,
  },
  totalPurchased: {
    type: Number,
    default: 0,
    min: 0,
  },
  totalUsed: {
    type: Number,
    default: 0,
    min: 0,
  },
  totalSpent: {
    type: Number,
    default: 0,
    min: 0,
  },
  
  // Legacy credits field (keeping for backward compatibility)
  credits: {
    type: Number,
    default: 0, // New users start with 0 credits
    min: 0,
  },
  
  // Profile Information
  profession: {
    type: String,
    trim: true,
  },
  bio: {
    type: String,
    trim: true,
    maxlength: 500,
  },
  country: {
    type: String,
    trim: true,
  },
  
  // Preferences
  preferences: {
    language: {
      type: String,
      default: 'en',
    },
    timezone: {
      type: String,
      default: 'UTC',
    },
    notifications: {
      email: { type: Boolean, default: true },
      push: { type: Boolean, default: true },
      marketing: { type: Boolean, default: false },
    },
    defaultVideoSettings: {
      aspectRatio: {
        type: String,
        enum: ['1280:720', '720:1280', '16:9', '9:16', '1:1'],
        default: '720:1280',
      },
      resolution: {
        type: Number,
        enum: [720, 1080],
        default: 1080,
      },
      duration: {
        type: Number,
        default: 15,
        min: 4,
        max: 60,
      },
    },
  },
  
  // Subscription Details
  subscription: {
    stripeCustomerId: String,
    stripeSubscriptionId: String,
    currentPeriodStart: Date,
    currentPeriodEnd: Date,
    cancelAtPeriodEnd: Boolean,
    status: {
      type: String,
      enum: ['active', 'canceled', 'past_due', 'unpaid'],
      default: 'active',
    },
  },
  
  // Usage Statistics
  usage: {
    totalProjects: { type: Number, default: 0 },
    totalVideosGenerated: { type: Number, default: 0 },
    totalCreditsUsed: { type: Number, default: 0 },
    totalSpent: { type: Number, default: 0 },
    lastProjectDate: Date,
    lastLoginDate: Date,
  },
  
  // Account Status
  isActive: {
    type: Boolean,
    default: true,
  },
  isEmailVerified: {
    type: Boolean,
    default: false,
  },
  isPhoneVerified: {
    type: Boolean,
    default: false,
  },
  
  // Security
  lastPasswordChange: Date,
  twoFactorEnabled: {
    type: Boolean,
    default: false,
  },
  
  // Referral System
  referral: {
    referredBy: String, // User ID who referred this user
    referralCode: {
      type: String,
      unique: true,
      sparse: true,
    },
    referralCount: { type: Number, default: 0 },
    referralEarnings: { type: Number, default: 0 },
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
  lastActiveAt: {
    type: Date,
    default: Date.now,
  },
  
  // Metadata
  metadata: {
    signupSource: String, // 'web', 'mobile', 'referral', etc.
    ipAddress: String,
    userAgent: String,
    deviceInfo: String,
  }
});

// Indexes for efficient queries
userSchema.index({ email: 1 });
userSchema.index({ uid: 1 });
userSchema.index({ plan: 1 });
userSchema.index({ createdAt: -1 });
userSchema.index({ lastActiveAt: -1 });
userSchema.index({ 'subscription.status': 1 });
userSchema.index({ 'referral.referralCode': 1 });

// Update timestamp on save
userSchema.pre('save', function(next) {
  this.updatedAt = Date.now();
  next();
});

// Virtual for full name display
userSchema.virtual('displayName').get(function() {
  return this.name || this.email.split('@')[0];
});

// Virtual for subscription status
userSchema.virtual('isSubscribed').get(function() {
  return this.plan !== 'free' && this.subscription.status === 'active';
});

// Virtual for credits remaining
userSchema.virtual('hasCredits').get(function() {
  return this.credits > 0;
});

// Methods
userSchema.methods.deductCredits = function(amount = 1) {
  if (this.credits >= amount) {
    this.credits -= amount;
    this.usage.totalCreditsUsed += amount;
    this.lastActiveAt = new Date();
    return this.save();
  } else {
    throw new Error('Insufficient credits');
  }
};

userSchema.methods.addCredits = function(amount) {
  this.credits += amount;
  this.lastActiveAt = new Date();
  return this.save();
};

userSchema.methods.updateUsage = function(stats = {}) {
  Object.assign(this.usage, stats);
  this.lastActiveAt = new Date();
  return this.save();
};

userSchema.methods.updateLastActive = function() {
  this.lastActiveAt = new Date();
  return this.save();
};

userSchema.methods.upgradeSubscription = function(plan, subscriptionData = {}) {
  this.plan = plan;
  
  // Credits are only added through purchase, not subscription upgrade
  // Remove automatic credit addition to force users to buy credits
  
  Object.assign(this.subscription, subscriptionData);
  this.lastActiveAt = new Date();
  return this.save();
};

// Static methods
userSchema.statics.findByUid = function(uid) {
  return this.findOne({ uid });
};

userSchema.statics.findByEmail = function(email) {
  return this.findOne({ email: email.toLowerCase() });
};

userSchema.statics.getActiveUsers = function(days = 30) {
  const cutoffDate = new Date();
  cutoffDate.setDate(cutoffDate.getDate() - days);
  
  return this.find({
    lastActiveAt: { $gte: cutoffDate },
    isActive: true
  });
};

userSchema.statics.getSubscriberStats = function() {
  return this.aggregate([
    {
      $group: {
        _id: '$plan',
        count: { $sum: 1 },
        totalRevenue: { $sum: '$usage.totalSpent' },
        avgCreditsUsed: { $avg: '$usage.totalCreditsUsed' }
      }
    }
  ]);
};

userSchema.statics.getUserStats = function() {
  return this.aggregate([
    {
      $group: {
        _id: null,
        totalUsers: { $sum: 1 },
        activeUsers: { $sum: { $cond: ['$isActive', 1, 0] } },
        verifiedUsers: { $sum: { $cond: ['$isEmailVerified', 1, 0] } },
        totalRevenue: { $sum: '$usage.totalSpent' },
        totalCreditsUsed: { $sum: '$usage.totalCreditsUsed' },
        avgProjectsPerUser: { $avg: '$usage.totalProjects' }
      }
    }
  ]);
};

module.exports = mongoose.model('User', userSchema);