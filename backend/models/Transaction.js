const mongoose = require('mongoose');

const transactionSchema = new mongoose.Schema({
  userId: {
    type: String,
    required: true,
    index: true,
  },
  
  // Transaction Details
  type: {
    type: String,
    enum: ['purchase', 'refund', 'credit_bonus', 'referral_bonus', 'client_payment'],
    required: true,
  },
  status: {
    type: String,
    enum: ['pending', 'completed', 'failed', 'cancelled', 'refunded'],
    default: 'pending',
  },
  
  // Payment Information
  amount: {
    type: Number,
    required: true,
    min: 0,
  },
  currency: {
    type: String,
    default: 'USD',
    uppercase: true,
  },
  
  // Plan Information
  planType: {
    type: String,
    enum: [
      // Legacy plans
      'starter', 'pro', 'enterprise', 'credit_pack', 'business',
      // New subscription plans
      'basic',
      // New credit top-ups
      'credits_10', 'credits_20', 'credits_30',
      // Faceless LTD plans
      'faceless_basic', 'faceless_starter', 'faceless_pro'
    ],
  },
  planId: {
    type: String,
  },
  creditsPurchased: {
    type: Number,
    required: true,
    min: 0,
  },
  
  // Payment Gateway Details
  paymentGateway: {
    type: String,
    enum: ['stripe', 'paypal', 'razorpay', 'manual', 'google_play', 'app_store', 'client_stripe'],
    default: 'stripe',
  },
  paymentMethod: {
    type: String,
    enum: ['stripe', 'paypal', 'razorpay', 'google_play', 'app_store', 'manual', 'stripe_webhook'],
    default: 'stripe',
  },
  
  // Stripe specific fields
  stripeSessionId: {
    type: String,
    index: true,
  },
  stripePaymentIntentId: String,
  stripeCustomerId: String,
  stripeSubscriptionId: String,
  
  // PayPal specific fields
  paypalOrderId: String,
  paypalPaymentId: String,
  
  // In-App Purchase specific fields (Cross-platform)
  transactionId: {
    type: String,
    index: true,
  },
  purchaseToken: String, // Android: Purchase token, iOS: Receipt data
  productId: String,
  
  // Platform-specific fields
  platform: {
    type: String,
    enum: ['android', 'ios', 'web'],
    default: 'android',
  },
  originalTransactionId: String, // iOS: Original transaction ID
  appStoreReceiptUrl: String,    // iOS: Receipt URL
  bundleId: String,              // iOS: Bundle identifier
  
  // Invoice Details
  invoiceNumber: {
    type: String,
    unique: true,
  },
  invoiceUrl: String,
  receiptUrl: String,
  
  // Billing Information
  billingAddress: {
    name: String,
    email: String,
    line1: String,
    line2: String,
    city: String,
    state: String,
    postal_code: String,
    country: String,
  },
  
  // Discount & Coupon
  discount: {
    couponCode: String,
    discountAmount: Number,
    discountPercentage: Number,
  },
  
  // Tax Information
  tax: {
    amount: { type: Number, default: 0 },
    rate: { type: Number, default: 0 },
    taxId: String,
  },
  
  // Subscription Details (for recurring payments)
  subscription: {
    isRecurring: { type: Boolean, default: false },
    interval: {
      type: String,
      enum: ['month', 'year'],
    },
    intervalCount: { type: Number, default: 1 },
    currentPeriodStart: Date,
    currentPeriodEnd: Date,
    nextBillingDate: Date,
  },
  
  // Refund Information
  refund: {
    amount: Number,
    reason: String,
    refundedAt: Date,
    refundId: String,
  },
  
  // Processing Dates
  createdAt: {
    type: Date,
    default: Date.now,
  },
  processedAt: Date,
  completedAt: Date,
  
  // Metadata
  metadata: {
    source: String, // 'web', 'mobile', 'api'
    userAgent: String,
    ipAddress: String,
    referrer: String,
    purchaseType: String, // 'in_app_purchase', 'web_payment'
    platform: String, // 'android', 'ios', 'web'
    purchaseToken: String,
    productId: String,
    verifiedAt: String,
  },
  
  // Internal Notes
  notes: String,
  
  // Webhook Information
  webhookEvents: [{
    event: String,
    receivedAt: Date,
    processed: Boolean,
  }],
});

// Indexes for efficient queries
transactionSchema.index({ userId: 1, createdAt: -1 });
transactionSchema.index({ status: 1 });
transactionSchema.index({ type: 1 });
transactionSchema.index({ planType: 1 });
transactionSchema.index({ stripeSessionId: 1 });
transactionSchema.index({ invoiceNumber: 1 });
transactionSchema.index({ createdAt: -1 });

// Auto-generate invoice number
transactionSchema.pre('save', function(next) {
  if (!this.invoiceNumber && this.isNew) {
    const date = new Date();
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const random = Math.random().toString(36).substr(2, 6).toUpperCase();
    this.invoiceNumber = `INV-${year}${month}-${random}`;
  }
  next();
});

// Virtual for formatted amount
transactionSchema.virtual('formattedAmount').get(function() {
  return `${this.currency} ${this.amount.toFixed(2)}`;
});

// Virtual for transaction age
transactionSchema.virtual('daysSinceCreated').get(function() {
  const diffTime = Date.now() - this.createdAt.getTime();
  return Math.floor(diffTime / (1000 * 60 * 60 * 24));
});

// Methods
transactionSchema.methods.markCompleted = function() {
  this.status = 'completed';
  this.completedAt = new Date();
  if (!this.processedAt) {
    this.processedAt = new Date();
  }
  return this.save();
};

transactionSchema.methods.markFailed = function(reason) {
  this.status = 'failed';
  this.notes = reason;
  this.processedAt = new Date();
  return this.save();
};

transactionSchema.methods.processRefund = function(amount, reason) {
  this.refund = {
    amount: amount || this.amount,
    reason,
    refundedAt: new Date(),
    refundId: `ref_${Date.now()}`,
  };
  this.status = 'refunded';
  return this.save();
};

transactionSchema.methods.addWebhookEvent = function(event) {
  this.webhookEvents.push({
    event: event.type,
    receivedAt: new Date(),
    processed: false,
  });
  return this.save();
};

// Static methods
transactionSchema.statics.findByUser = function(userId, options = {}) {
  const query = { userId };
  
  if (options.status) {
    query.status = options.status;
  }
  
  if (options.type) {
    query.type = options.type;
  }
  
  return this.find(query)
    .sort({ createdAt: -1 })
    .limit(options.limit || 50);
};

transactionSchema.statics.getRevenueStats = function(days = 30) {
  const startDate = new Date();
  startDate.setDate(startDate.getDate() - days);
  
  return this.aggregate([
    {
      $match: {
        status: 'completed',
        createdAt: { $gte: startDate }
      }
    },
    {
      $group: {
        _id: {
          $dateToString: { format: '%Y-%m-%d', date: '$createdAt' }
        },
        totalRevenue: { $sum: '$amount' },
        transactionCount: { $sum: 1 },
        avgTransactionValue: { $avg: '$amount' }
      }
    },
    {
      $sort: { _id: 1 }
    }
  ]);
};

transactionSchema.statics.getMonthlyRevenue = function() {
  return this.aggregate([
    {
      $match: { status: 'completed' }
    },
    {
      $group: {
        _id: {
          year: { $year: '$createdAt' },
          month: { $month: '$createdAt' }
        },
        totalRevenue: { $sum: '$amount' },
        transactionCount: { $sum: 1 },
        uniqueUsers: { $addToSet: '$userId' }
      }
    },
    {
      $addFields: {
        uniqueUserCount: { $size: '$uniqueUsers' }
      }
    },
    {
      $sort: { '_id.year': -1, '_id.month': -1 }
    }
  ]);
};

transactionSchema.statics.getPlanStats = function() {
  return this.aggregate([
    {
      $match: { 
        status: 'completed',
        type: 'purchase'
      }
    },
    {
      $group: {
        _id: '$planType',
        totalSales: { $sum: 1 },
        totalRevenue: { $sum: '$amount' },
        avgSaleValue: { $avg: '$amount' },
        totalCredits: { $sum: '$creditsPurchased' }
      }
    }
  ]);
};

module.exports = mongoose.model('Transaction', transactionSchema);