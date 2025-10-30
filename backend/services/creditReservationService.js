const User = require('../models/User');
const Transaction = require('../models/Transaction');

class CreditReservationService {
  
  /**
   * Reserve credits for video generation without actually deducting them
   * Credits are put in a "reserved" state and can be confirmed or returned later
   */
  static async reserveCredits({ 
    userId, 
    credits, 
    videoType, 
    projectId, 
    durationMinutes 
  }) {
    try {
      console.log(`💰 Reserving ${credits} credits for user ${userId}`);
      
      const user = await User.findByUid(userId);
      if (!user) {
        throw new Error('User not found');
      }

      const availableCredits = user.availableCredits || user.credits || 0;
      
      if (availableCredits < credits) {
        return {
          success: false,
          error: 'Insufficient credits',
          required: credits,
          available: availableCredits
        };
      }

      // Create a pending transaction record
      const reservationTransaction = new Transaction({
        userId: userId,
        transactionId: `reserve_${projectId}_${Date.now()}`,
        type: 'credit_reservation',
        amount: credits,
        status: 'pending',
        metadata: {
          videoType,
          projectId,
          durationMinutes,
          reservedAt: new Date(),
          action: 'reserve'
        }
      });

      await reservationTransaction.save();

      // Update user's reserved credits (don't deduct from available yet)
      user.reservedCredits = (user.reservedCredits || 0) + credits;
      await user.save();

      console.log(`✅ Reserved ${credits} credits for project ${projectId}`);
      console.log(`📊 User balance: ${availableCredits} available, ${user.reservedCredits} reserved`);

      return {
        success: true,
        reservationId: reservationTransaction._id.toString(),
        transactionId: reservationTransaction.transactionId,
        creditsReserved: credits,
        availableCredits: availableCredits - credits, // What they'll have after confirmation
        reservedCredits: user.reservedCredits
      };

    } catch (error) {
      console.error('❌ Credit reservation error:', error);
      return {
        success: false,
        error: error.message
      };
    }
  }

  /**
   * Confirm reserved credits when video generation succeeds
   * Moves credits from reserved to actually consumed
   */
  static async confirmReservation({ 
    userId, 
    reservationId, 
    projectId 
  }) {
    try {
      console.log(`✅ Confirming credit reservation ${reservationId} for project ${projectId}`);

      const user = await User.findByUid(userId);
      if (!user) {
        throw new Error('User not found');
      }

      // Find the reservation transaction
      const reservationTransaction = await Transaction.findById(reservationId);
      if (!reservationTransaction || reservationTransaction.status !== 'pending') {
        throw new Error('Invalid or already processed reservation');
      }

      const credits = reservationTransaction.amount;

      // Deduct from available credits and reserved credits
      user.availableCredits = (user.availableCredits || user.credits || 0) - credits;
      user.credits = user.availableCredits; // Keep legacy field in sync
      user.reservedCredits = Math.max(0, (user.reservedCredits || 0) - credits);
      user.totalUsed = (user.totalUsed || 0) + credits;

      // Update reservation transaction to completed
      reservationTransaction.status = 'completed';
      reservationTransaction.metadata.confirmedAt = new Date();
      reservationTransaction.metadata.action = 'confirm';

      // Create consumption transaction for tracking
      const consumptionTransaction = new Transaction({
        userId: userId,
        transactionId: `consume_${projectId}_${Date.now()}`,
        type: 'credit_consumption',
        amount: credits,
        status: 'completed',
        metadata: {
          ...reservationTransaction.metadata,
          reservationId: reservationId,
          consumedAt: new Date(),
          action: 'consume'
        }
      });

      // Save all changes
      await Promise.all([
        user.save(),
        reservationTransaction.save(),
        consumptionTransaction.save()
      ]);

      console.log(`✅ Credits confirmed: ${credits} credits consumed for successful video generation`);
      console.log(`📊 User balance: ${user.availableCredits} available, ${user.reservedCredits} reserved, ${user.totalUsed} total used`);

      return {
        success: true,
        creditsConsumed: credits,
        newBalance: user.availableCredits,
        reservedCredits: user.reservedCredits,
        totalUsed: user.totalUsed
      };

    } catch (error) {
      console.error('❌ Credit confirmation error:', error);
      return {
        success: false,
        error: error.message
      };
    }
  }

  /**
   * Return reserved credits when video generation fails
   * Moves credits from reserved back to available
   */
  static async returnReservation({ 
    userId, 
    reservationId, 
    projectId, 
    reason = 'Video generation failed' 
  }) {
    try {
      console.log(`🔄 Returning credit reservation ${reservationId} for project ${projectId}`);

      const user = await User.findByUid(userId);
      if (!user) {
        throw new Error('User not found');
      }

      // Find the reservation transaction
      const reservationTransaction = await Transaction.findById(reservationId);
      if (!reservationTransaction || reservationTransaction.status !== 'pending') {
        console.warn(`⚠️ Reservation ${reservationId} not found or already processed`);
        return { success: true, message: 'Reservation already processed' };
      }

      const credits = reservationTransaction.amount;

      // Return credits from reserved to available (no actual deduction)
      user.reservedCredits = Math.max(0, (user.reservedCredits || 0) - credits);
      // Available credits remain unchanged since they were never actually deducted

      // Update reservation transaction to returned
      reservationTransaction.status = 'returned';
      reservationTransaction.metadata.returnedAt = new Date();
      reservationTransaction.metadata.returnReason = reason;
      reservationTransaction.metadata.action = 'return';

      // Create return transaction for tracking
      const returnTransaction = new Transaction({
        userId: userId,
        transactionId: `return_${projectId}_${Date.now()}`,
        type: 'credit_return',
        amount: credits,
        status: 'completed',
        metadata: {
          ...reservationTransaction.metadata,
          reservationId: reservationId,
          returnedAt: new Date(),
          returnReason: reason,
          action: 'return'
        }
      });

      // Save all changes
      await Promise.all([
        user.save(),
        reservationTransaction.save(),
        returnTransaction.save()
      ]);

      console.log(`✅ Credits returned: ${credits} credits returned due to failed video generation`);
      console.log(`📊 User balance: ${user.availableCredits} available, ${user.reservedCredits} reserved`);

      return {
        success: true,
        creditsReturned: credits,
        availableCredits: user.availableCredits,
        reservedCredits: user.reservedCredits,
        reason: reason
      };

    } catch (error) {
      console.error('❌ Credit return error:', error);
      return {
        success: false,
        error: error.message
      };
    }
  }

  /**
   * Get user's credit status including reserved credits
   */
  static async getCreditStatus(userId) {
    try {
      const user = await User.findByUid(userId);
      if (!user) {
        throw new Error('User not found');
      }

      return {
        success: true,
        availableCredits: user.availableCredits || user.credits || 0,
        reservedCredits: user.reservedCredits || 0,
        totalCredits: (user.availableCredits || user.credits || 0) + (user.reservedCredits || 0),
        totalUsed: user.totalUsed || 0,
        totalPurchased: user.totalPurchased || 0
      };
    } catch (error) {
      console.error('❌ Get credit status error:', error);
      return {
        success: false,
        error: error.message
      };
    }
  }

  /**
   * Clean up old pending reservations (older than 1 hour)
   */
  static async cleanupExpiredReservations() {
    try {
      const oneHourAgo = new Date(Date.now() - 60 * 60 * 1000);
      
      const expiredReservations = await Transaction.find({
        type: 'credit_reservation',
        status: 'pending',
        createdAt: { $lt: oneHourAgo }
      });

      console.log(`🧹 Found ${expiredReservations.length} expired reservations to clean up`);

      for (const reservation of expiredReservations) {
        await this.returnReservation({
          userId: reservation.userId,
          reservationId: reservation._id.toString(),
          projectId: reservation.metadata.projectId,
          reason: 'Reservation expired (timeout)'
        });
      }

      return {
        success: true,
        cleanedUp: expiredReservations.length
      };
    } catch (error) {
      console.error('❌ Cleanup expired reservations error:', error);
      return {
        success: false,
        error: error.message
      };
    }
  }
}

module.exports = CreditReservationService;