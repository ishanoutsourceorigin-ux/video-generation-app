const crypto = require('crypto');
const admin = require('firebase-admin');
const User = require('../models/User');
const Transaction = require('../models/Transaction');
const emailService = require('./emailService');

class ClientUserService {
  constructor() {
    this.initialized = false;
  }

  // Initialize Firebase Admin if not already done
  init() {
    try {
      if (!this.initialized) {
        // Firebase should already be initialized in middleware/auth.js
        this.initialized = true;
        console.log('✅ ClientUserService initialized');
      }
    } catch (error) {
      console.error('❌ ClientUserService initialization failed:', error);
    }
  }

  // Generate secure random 6-digit password using Math.random()
  generateRandomPassword(length = 6) {
    const characters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    let password = '';
    
    // Generate exactly 6 characters using Math.random()
    for (let i = 0; i < length; i++) {
      const randomIndex = Math.floor(Math.random() * characters.length);
      password += characters[randomIndex];
    }
    
    return password;
  }

  // Calculate credits based on payment amount
  calculateCreditsFromPayment(amountInCents, currency = 'usd') {
    // Convert to dollars
    const amountInDollars = amountInCents / 100;
    
    // Credit calculation: roughly 50 credits per dollar
    // This matches the existing plan structure
    const creditsPerDollar = 50;
    const calculatedCredits = Math.floor(amountInDollars * creditsPerDollar);
    
    // Minimum 10 credits for any payment
    return Math.max(calculatedCredits, 10);
  }

  // Create Firebase user with email and password
  async createFirebaseUser(email, password, displayName) {
    try {
      const userRecord = await admin.auth().createUser({
        email: email,
        password: password,
        displayName: displayName,
        emailVerified: false, // Will need to verify email
      });

      console.log('✅ Firebase user created:', {
        uid: userRecord.uid,
        email: userRecord.email,
        displayName: userRecord.displayName
      });

      return {
        success: true,
        uid: userRecord.uid,
        firebaseUser: userRecord
      };

    } catch (error) {
      console.error('❌ Firebase user creation failed:', error);
      
      // Handle specific Firebase errors
      if (error.code === 'auth/email-already-exists') {
        // Try to get existing user
        try {
          const existingUser = await admin.auth().getUserByEmail(email);
          console.log('⚠️ Firebase user already exists, using existing:', existingUser.uid);
          return {
            success: true,
            uid: existingUser.uid,
            firebaseUser: existingUser,
            existed: true
          };
        } catch (getError) {
          return {
            success: false,
            error: 'Email already exists but cannot retrieve user',
            code: 'auth/email-already-exists'
          };
        }
      }

      return {
        success: false,
        error: error.message,
        code: error.code
      };
    }
  }

  // Create complete user account from client payment
  async createClientUserFromPayment(paymentData) {
    try {
      console.log('🔄 Creating client user from payment:', {
        email: paymentData.email,
        amount: paymentData.amount,
        clientSource: paymentData.clientSource
      });

      const { 
        email, 
        amount, 
        currency, 
        paymentIntentId, 
        customerEmail, 
        customerName, 
        clientSource,
        metadata = {}
      } = paymentData;

      // Use customer email if provided, otherwise use email from payment
      const userEmail = customerEmail || email;
      const userName = customerName || userEmail.split('@')[0];

      // Check if user already exists in MongoDB
      let existingUser = await User.findByEmail(userEmail);
      if (existingUser) {
        console.log('⚠️ User already exists in MongoDB:', userEmail);
        
        // Add credits to existing user instead of creating new
        const credits = this.calculateCreditsFromPayment(amount, currency);
        const previousBalance = existingUser.availableCredits || existingUser.credits || 0;
        
        existingUser.availableCredits = previousBalance + credits;
        existingUser.credits = existingUser.availableCredits; // Keep legacy field in sync
        existingUser.totalPurchased = (existingUser.totalPurchased || 0) + credits;
        existingUser.lastActiveAt = new Date();

        await existingUser.save();

        // Create transaction record
        const transaction = new Transaction({
          userId: existingUser.uid,
          transactionId: paymentIntentId,
          type: 'client_payment',
          amount: amount / 100,
          creditsPurchased: credits,
          status: 'completed',
          paymentMethod: 'stripe_webhook',
          paymentGateway: 'client_stripe',
          completedAt: new Date(),
          metadata: {
            clientSource,
            customerEmail,
            customerName,
            paymentIntentId,
            webhookProcessed: new Date().toISOString()
          }
        });

        await transaction.save();

        // Send payment confirmation email
        await emailService.sendPaymentConfirmationEmail(userEmail, {
          amount: amount / 100,
          credits,
          transactionId: paymentIntentId,
          clientSource
        });

        return {
          success: true,
          user: existingUser,
          transaction,
          newUser: false,
          creditsAdded: credits
        };
      }

      // Generate random 6-digit password using Math.random()
      const generatedPassword = this.generateRandomPassword(6);
      
      // Create Firebase user
      const firebaseResult = await this.createFirebaseUser(
        userEmail,
        generatedPassword,
        userName
      );

      if (!firebaseResult.success) {
        throw new Error(`Firebase user creation failed: ${firebaseResult.error}`);
      }

      // Calculate credits from payment amount
      const credits = this.calculateCreditsFromPayment(amount, currency);

      // Create MongoDB user with complete client account data
      const newUser = new User({
        uid: firebaseResult.uid,
        email: userEmail,
        name: userName,
        photoURL: null,
        phoneNumber: null,
        
        // Credit system
        plan: 'free',
        availableCredits: credits,
        credits: credits, // Legacy field
        totalPurchased: credits,
        totalUsed: 0,
        totalSpent: amount / 100,
        
        // Client account fields
        clientAccount: {
          isClientUser: true,
          clientSource: clientSource,
          paymentSource: 'stripe-webhook',
          automaticallyCreated: true,
          generatedPassword: generatedPassword, // Store temporarily for email
          clientPaymentId: paymentIntentId,
          clientCustomerId: metadata.customerId || null,
          welcomeEmailSent: false,
        },
        
        // Account status
        isActive: true,
        isEmailVerified: false,
        
        // Metadata
        metadata: {
          signupSource: 'client-website',
          clientWebhookData: paymentData,
          createdVia: 'stripe-webhook'
        },
        
        // Timestamps
        createdAt: new Date(),
        updatedAt: new Date(),
        lastActiveAt: new Date(),
      });

      // Create transaction record
      const transaction = new Transaction({
        userId: firebaseResult.uid,
        transactionId: paymentIntentId,
        type: 'client_payment',
        amount: amount / 100,
        creditsPurchased: credits,
        status: 'completed',
        paymentMethod: 'stripe_webhook',
        paymentGateway: 'client_stripe',
        completedAt: new Date(),
        metadata: {
          clientSource,
          customerEmail,
          customerName,
          paymentIntentId,
          firebaseUid: firebaseResult.uid,
          webhookProcessed: new Date().toISOString(),
          automaticUserCreation: true
        }
      });

      // Save both user and transaction
      await Promise.all([
        newUser.save(),
        transaction.save()
      ]);

      console.log('✅ Client user created successfully:', {
        uid: firebaseResult.uid,
        email: userEmail,
        credits: credits,
        clientSource: clientSource
      });

      // Send welcome email with credentials
      const emailResult = await emailService.sendWelcomeEmail(
        userEmail,
        {
          name: userName,
          password: generatedPassword,
          credits: credits,
          clientSource: clientSource
        }
      );

      if (emailResult.success) {
        // Update user to mark welcome email as sent and clear password
        newUser.clientAccount.welcomeEmailSent = true;
        newUser.clientAccount.welcomeEmailDate = new Date();
        newUser.clientAccount.generatedPassword = null; // Clear for security
        await newUser.save();
        
        console.log('✅ Welcome email sent successfully to:', userEmail);
      } else {
        console.log('⚠️ Welcome email failed:', emailResult.error);
      }

      return {
        success: true,
        user: newUser,
        transaction,
        firebaseUser: firebaseResult.firebaseUser,
        newUser: true,
        creditsAdded: credits,
        emailSent: emailResult.success
      };

    } catch (error) {
      console.error('❌ Client user creation failed:', error);
      throw error;
    }
  }

  // Get client user statistics
  async getClientUserStats() {
    try {
      const stats = await User.aggregate([
        {
          $group: {
            _id: '$clientAccount.clientSource',
            totalUsers: { $sum: 1 },
            clientUsers: { 
              $sum: { 
                $cond: ['$clientAccount.isClientUser', 1, 0] 
              } 
            },
            totalCreditsAllocated: { 
              $sum: '$clientAccount.isClientUser' ? '$availableCredits' : 0 
            },
            totalSpent: { $sum: '$totalSpent' },
          }
        }
      ]);

      return stats;
    } catch (error) {
      console.error('❌ Failed to get client user stats:', error);
      return [];
    }
  }
}

// Export singleton instance
module.exports = new ClientUserService();