const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const Project = require('../models/Project');
const Avatar = require('../models/Avatar');
const User = require('../models/User');
const Transaction = require('../models/Transaction');
const mongoose = require('mongoose');
const admin = require('firebase-admin');

const router = express.Router();

// Firebase-based admin configuration
const FIREBASE_ADMIN_EMAIL = 'ishanoutsourceorigin@gmail.com'; // Authorized admin email

// Admin authentication middleware
const adminAuth = (req, res, next) => {
  try {
    const token = req.header('Authorization')?.replace('Bearer ', '');
    
    if (!token) {
      return res.status(401).json({ success: false, message: 'No token provided' });
    }

    const decoded = jwt.verify(token, process.env.JWT_SECRET || 'your-super-secret-jwt-key-change-in-production');
    
    if (decoded.role !== 'admin') {
      return res.status(403).json({ success: false, message: 'Admin access required' });
    }

    req.admin = decoded;
    next();
  } catch (error) {
    console.error('Admin auth error:', error.message);
    if (error.name === 'JsonWebTokenError') {
      return res.status(401).json({ success: false, message: 'Invalid token signature. Please login again.' });
    }
    if (error.name === 'TokenExpiredError') {
      return res.status(401).json({ success: false, message: 'Token expired. Please login again.' });
    }
    res.status(401).json({ success: false, message: 'Token validation failed' });
  }
};

// Helper function to get user ID from different sources
const getUserId = (req) => {
  try {
    return req.user ? req.user.uid : `dev-user-${Date.now()}`;
  } catch (error) {
    return `dev-user-${Date.now()}`;
  }
};

// POST /api/admin/login - Redirect to Firebase login (deprecated)
router.post('/login', async (req, res) => {
  res.status(400).json({
    success: false,
    message: 'Please use Firebase authentication for admin login',
    redirectTo: '/admin/firebase-login'
  });
});

// POST /api/admin/firebase-login - Firebase Admin login
router.post('/firebase-login', async (req, res) => {
  try {
    const { email, uid } = req.body;
    const authHeader = req.header('Authorization');
    
    console.log('🔐 Firebase admin login attempt:', email);

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ 
        success: false, 
        message: 'No Firebase token provided' 
      });
    }

    const idToken = authHeader.replace('Bearer ', '');

    // Import Firebase Admin dynamically
    const admin = require('firebase-admin');
    
    try {
      // Verify the Firebase ID token
      const decodedToken = await admin.auth().verifyIdToken(idToken);
      
      // Check if the user is the authorized admin
      if (decodedToken.email !== FIREBASE_ADMIN_EMAIL) {
        return res.status(403).json({ 
          success: false, 
          message: 'Unauthorized: Not an admin user' 
        });
      }

      // Get the full user record to access displayName
      const userRecord = await admin.auth().getUser(decodedToken.uid);
      const displayName = userRecord.displayName || userRecord.email?.split('@')[0] || 'Admin User';

      console.log('🔥 Firebase user displayName:', displayName);

      // Generate JWT token for API access
      const token = jwt.sign(
        { 
          email: decodedToken.email,
          name: displayName,
          role: 'admin',
          uid: decodedToken.uid
        },
        process.env.JWT_SECRET || 'your-super-secret-jwt-key-change-in-production',
        { expiresIn: '24h' }
      );

      console.log('✅ Firebase admin login successful');

      res.json({
        success: true,
        message: 'Firebase admin login successful',
        token,
        admin: {
          email: decodedToken.email,
          name: displayName,
          role: 'admin',
          uid: decodedToken.uid
        }
      });

    } catch (firebaseError) {
      console.error('❌ Firebase token verification failed:', firebaseError);
      return res.status(401).json({ 
        success: false, 
        message: 'Invalid Firebase token' 
      });
    }

  } catch (error) {
    console.error('❌ Firebase admin login error:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Firebase login failed',
      error: error.message 
    });
  }
});

// GET /api/admin/stats - Dashboard statistics
router.get('/stats', adminAuth, async (req, res) => {
  try {
    console.log('📊 Fetching admin statistics...');

    // Define date for calculations
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

    // Get Firebase user stats
    let totalUsers = 0;
    let newUsers = 0;
    
    try {
      // Get all Firebase users
      const listUsersResult = await admin.auth().listUsers();
      totalUsers = listUsersResult.users.length;
      
      // Count new users (last 30 days)
      newUsers = listUsersResult.users.filter(user => {
        const userCreationTime = new Date(user.metadata.creationTime);
        return userCreationTime >= thirtyDaysAgo;
      }).length;
      
      // console.log(`🔥 Firebase Users: ${totalUsers} total, ${newUsers} new in last 30 days`);
    } catch (firebaseError) {
      console.error('❌ Error fetching Firebase users:', firebaseError);
      // Fallback to MongoDB users count if Firebase fails
      totalUsers = await User.countDocuments();
      newUsers = await User.countDocuments({
        createdAt: { $gte: thirtyDaysAgo }
      });
      console.log(`📊 Fallback to MongoDB Users: ${totalUsers} total, ${newUsers} new`);
    }

    // Get total projects
    const totalProjects = await Project.countDocuments();

    // Get projects by status
    const projectsByStatus = await Project.aggregate([
      {
        $group: {
          _id: '$status',
          count: { $sum: 1 }
        }
      }
    ]);

    const statusCounts = {};
    projectsByStatus.forEach(item => {
      statusCounts[item._id || 'unknown'] = item.count;
    });

    // Get real revenue from transactions
    const revenueStats = await Transaction.aggregate([
      {
        $match: { 
          status: 'completed',
          type: 'purchase'
        }
      },
      {
        $group: {
          _id: null,
          totalRevenue: { $sum: '$amount' },
          totalTransactions: { $sum: 1 }
        }
      }
    ]);

    const totalRevenue = revenueStats.length > 0 ? revenueStats[0].totalRevenue : 0;
    const totalTransactions = revenueStats.length > 0 ? revenueStats[0].totalTransactions : 0;

    // Get recent transactions (last 30 days)
    const recentTransactions = await Transaction.countDocuments({
      status: 'completed',
      createdAt: { $gte: thirtyDaysAgo }
    });

    const stats = {
      totalUsers,
      totalProjects,
      totalRevenue,
      recentTransactions,
      newUsers,
      projectsByStatus: statusCounts,
      totalTransactions
    };

    // console.log('✅ Statistics compiled:', stats);

    res.json({
      success: true,
      stats
    });

  } catch (error) {
    console.error('❌ Stats fetch error:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Failed to fetch statistics',
      error: error.message 
    });
  }
});

// GET /api/admin/users - Get Firebase users with project stats
router.get('/users', adminAuth, async (req, res) => {
  try {
    const { page = 1, limit = 10, search = '' } = req.query;
    const skip = (page - 1) * limit;

    // console.log('👥 Fetching Firebase users...');

    let allUsers = [];
    
    try {
      // Get all Firebase users
      const listUsersResult = await admin.auth().listUsers();
      const firebaseUsers = listUsersResult.users;
      
      console.log(`🔥 Found ${firebaseUsers.length} Firebase users`);

      // Process each Firebase user and get project stats
      for (const firebaseUser of firebaseUsers) {
        // Get user's projects count
        const userProjects = await Project.countDocuments({ 
          userId: firebaseUser.uid 
        });
        
        // Get user's transactions
        const userTransactions = await Transaction.aggregate([
          { 
            $match: { 
              userId: firebaseUser.uid,
              status: 'completed'
            }
          },
          {
            $group: {
              _id: null,
              totalSpent: { $sum: '$amount' }
            }
          }
        ]);

        const user = {
          id: firebaseUser.uid,
          uid: firebaseUser.uid,
          email: firebaseUser.email || 'No email',
          name: firebaseUser.displayName || firebaseUser.email || 'No name',
          emailVerified: firebaseUser.emailVerified,
          disabled: firebaseUser.disabled,
          createdAt: firebaseUser.metadata.creationTime,
          lastLoginAt: firebaseUser.metadata.lastSignInTime,
          totalProjects: userProjects,
          totalSpent: userTransactions.length > 0 ? userTransactions[0].totalSpent : 0,
          credits: 0, // Firebase users don't have credits system yet
          plan: 'free' // Default plan
        };

        // Apply search filter
        if (!search || 
            user.name.toLowerCase().includes(search.toLowerCase()) ||
            user.email.toLowerCase().includes(search.toLowerCase()) ||
            user.uid.includes(search)) {
          allUsers.push(user);
        }
      }
      
    } catch (firebaseError) {
      console.error('❌ Error fetching Firebase users:', firebaseError);
      
      // Fallback to MongoDB users if Firebase fails
      const users = await User.aggregate([
        { $match: search ? {
          $or: [
            { name: { $regex: search, $options: 'i' } },
            { email: { $regex: search, $options: 'i' } },
            { uid: { $regex: search, $options: 'i' } }
          ]
        } : {} },
        {
          $lookup: {
            from: 'projects',
            localField: 'uid',
            foreignField: 'userId',
            as: 'projects'
          }
        },
        {
          $lookup: {
            from: 'transactions',
            localField: 'uid',
            foreignField: 'userId',
            as: 'transactions'
          }
        },
        {
          $addFields: {
            id: '$uid',
            totalProjects: { $size: '$projects' },
            totalSpent: {
              $sum: {
                $map: {
                  input: {
                    $filter: {
                      input: '$transactions',
                      as: 'trans',
                      cond: { $eq: ['$$trans.status', 'completed'] }
                    }
                  },
                  as: 'completedTrans',
                  in: '$$completedTrans.amount'
                }
              }
            }
          }
        },
        {
          $project: {
            id: 1,
            uid: 1,
            name: 1,
            email: 1,
            credits: 1,
            plan: 1,
            totalProjects: 1,
            totalSpent: 1,
            createdAt: 1
          }
        }
      ]);
      
      allUsers = users;
      console.log(`📊 Fallback: Found ${allUsers.length} MongoDB users`);
    }

    // Apply pagination
    const total = allUsers.length;
    const startIndex = (page - 1) * limit;
    const endIndex = startIndex + parseInt(limit);
    const paginatedUsers = allUsers.slice(startIndex, endIndex);
    const pages = Math.ceil(total / limit);

    console.log(`✅ Returning ${paginatedUsers.length} users (page ${page}/${pages})`);

    res.json({
      success: true,
      users: paginatedUsers,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages
      }
    });
  } catch (error) {
    console.error('❌ Users fetch error:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Failed to fetch users',
      error: error.message 
    });
  }
});

// GET /api/admin/projects - Get all projects
router.get('/projects', adminAuth, async (req, res) => {
  try {
    const { page = 1, limit = 10, status = '', search = '' } = req.query;
    const skip = (page - 1) * limit;

    console.log('📹 Fetching projects...');

    // Build query
    const query = {};
    if (status) query.status = status;
    if (search) {
      query.$or = [
        { title: { $regex: search, $options: 'i' } },
        { description: { $regex: search, $options: 'i' } },
        { userId: { $regex: search, $options: 'i' } }
      ];
    }

    // Get projects first without user details
    const projectsRaw = await Project.aggregate([
      { $match: query },
      {
        $addFields: {
          id: '$_id',
          duration: {
            $cond: {
              if: '$actualDuration',
              then: { $concat: [{ $toString: '$actualDuration' }, 's'] },
              else: {
                $cond: {
                  if: '$configuration.duration',
                  then: { $concat: [{ $toString: '$configuration.duration' }, 's'] },
                  else: 'N/A'
                }
              }
            }
          },
          processingStep: {
            $cond: {
              if: { $eq: ['$status', 'processing'] },
              then: 'Generating video...',
              else: null
            }
          }
        }
      },
      { $sort: { createdAt: -1 } },
      { $skip: parseInt(skip) },
      { $limit: parseInt(limit) }
    ]);

    // Get Firebase user details for each project
    const projects = [];
    for (const project of projectsRaw) {
      let userDetails = {
        id: project.userId,
        name: project.userId, // Fallback to userId
        email: project.userId // Fallback to userId
      };

      try {
        // Try to get Firebase user details
        const firebaseUser = await admin.auth().getUser(project.userId);
        if (firebaseUser) {
          userDetails = {
            id: firebaseUser.uid,
            name: firebaseUser.displayName || firebaseUser.email?.split('@')[0] || firebaseUser.uid,
            email: firebaseUser.email || 'No email'
          };
        }
      } catch (firebaseError) {
        // If Firebase user not found, try MongoDB users collection as fallback
        try {
          const mongoUser = await User.findOne({ uid: project.userId });
          if (mongoUser) {
            userDetails = {
              id: mongoUser.uid,
              name: mongoUser.name || mongoUser.email?.split('@')[0] || mongoUser.uid,
              email: mongoUser.email || 'No email'
            };
          }
        } catch (mongoError) {
          console.log(`User details not found for ${project.userId}, using fallback`);
        }
      }

      projects.push({
        ...project,
        user: userDetails
      });
    }

    const total = await Project.countDocuments(query);
    const pages = Math.ceil(total / limit);

    console.log(`✅ Found ${projects.length} projects`);

    res.json({
      success: true,
      projects,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages
      }
    });

  } catch (error) {
    console.error('❌ Projects fetch error:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Failed to fetch projects',
      error: error.message 
    });
  }
});

// GET /api/admin/transactions - Get all transactions
router.get('/transactions', adminAuth, async (req, res) => {
  try {
    const { page = 1, limit = 10, status = '', search = '' } = req.query;
    const skip = (page - 1) * limit;
    
    console.log('💳 Fetching transactions...');

    // Build query
    let query = {};
    if (status) {
      query.status = status;
    }
    if (search) {
      query.$or = [
        { invoiceNumber: { $regex: search, $options: 'i' } },
        { planType: { $regex: search, $options: 'i' } },
        { stripeSessionId: { $regex: search, $options: 'i' } }
      ];
    }

    // Get transactions with user details
    const transactions = await Transaction.aggregate([
      { $match: query },
      {
        $lookup: {
          from: 'users',
          localField: 'userId',
          foreignField: 'uid',
          as: 'userDetails'
        }
      },
      {
        $addFields: {
          id: '$_id',
          user: {
            $cond: {
              if: { $gt: [{ $size: '$userDetails' }, 0] },
              then: {
                id: { $arrayElemAt: ['$userDetails.uid', 0] },
                name: { $arrayElemAt: ['$userDetails.name', 0] },
                email: { $arrayElemAt: ['$userDetails.email', 0] }
              },
              else: {
                id: '$userId',
                name: '$userId',
                email: '$userId'
              }
            }
          }
        }
      },
      {
        $project: {
          id: 1,
          planType: 1,
          amount: 1,
          currency: 1,
          creditsPurchased: 1,
          status: 1,
          type: 1,
          stripeSessionId: 1,
          invoiceNumber: 1,
          createdAt: 1,
          completedAt: 1,
          user: 1,
          paymentGateway: 1
        }
      },
      { $sort: { createdAt: -1 } },
      { $skip: parseInt(skip) },
      { $limit: parseInt(limit) }
    ]);

    // Get total count for pagination
    const total = await Transaction.countDocuments(query);
    const pages = Math.ceil(total / limit);

    console.log(`✅ Found ${transactions.length} transactions`);

    res.json({
      success: true,
      transactions,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages
      }
    });

  } catch (error) {
    console.error('❌ Transactions fetch error:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Failed to fetch transactions',
      error: error.message 
    });
  }
});

// PUT /api/admin/users/:id/credits - Update user credits
router.put('/users/:id/credits', adminAuth, async (req, res) => {
  try {
    const { id } = req.params;
    const { credits } = req.body;

    console.log(`💰 Updating credits for user ${id} to ${credits}`);

    // Validate credits value
    if (!Number.isInteger(credits) || credits < 0) {
      return res.status(400).json({
        success: false,
        message: 'Credits must be a non-negative integer'
      });
    }

    // Update user credits
    const user = await User.findOneAndUpdate(
      { uid: id },
      { credits: credits },
      { new: true }
    );

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    console.log(`✅ Updated credits for ${user.email} to ${credits}`);

    res.json({
      success: true,
      message: 'User credits updated successfully',
      user: {
        id: user.uid,
        credits: user.credits
      }
    });

  } catch (error) {
    console.error('❌ Update credits error:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Failed to update user credits',
      error: error.message 
    });
  }
});

// DELETE /api/admin/users/:id - Delete user and all associated data
router.delete('/users/:id', adminAuth, async (req, res) => {
  try {
    const { id } = req.params;

    console.log(`🗑️ Deleting user ${id} and all associated data`);

    // Find the user first
    const user = await User.findOne({ uid: id });
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    // Delete all user's projects (using uid, not userId)
    const deletedProjects = await Project.deleteMany({ uid: id });
    
    // Delete all user's avatars (using uid, not userId)
    const deletedAvatars = await Avatar.deleteMany({ uid: id });
    
    // Delete all user's transactions
    const deletedTransactions = await Transaction.deleteMany({ userId: id });
    
    // Delete the user
    await User.deleteOne({ uid: id });

    console.log(`✅ Deleted user ${user.email} and associated data:`, {
      projects: deletedProjects.deletedCount,
      avatars: deletedAvatars.deletedCount,
      transactions: deletedTransactions.deletedCount
    });

    res.json({
      success: true,
      message: 'User and all associated data deleted successfully',
      deletedData: {
        projects: deletedProjects.deletedCount,
        avatars: deletedAvatars.deletedCount,
        transactions: deletedTransactions.deletedCount
      }
    });

  } catch (error) {
    console.error('❌ Delete user error:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Failed to delete user',
      error: error.message 
    });
  }
});

// DELETE /api/admin/projects/:id - Delete project
router.delete('/projects/:id', adminAuth, async (req, res) => {
  try {
    const { id } = req.params;

    console.log(`🗑️ Deleting project ${id}`);

    const result = await Project.findByIdAndDelete(id);
    
    if (!result) {
      return res.status(404).json({
        success: false,
        message: 'Project not found'
      });
    }

    console.log(`✅ Project ${id} deleted successfully`);

    res.json({
      success: true,
      message: 'Project deleted successfully'
    });

  } catch (error) {
    console.error('❌ Delete project error:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Failed to delete project',
      error: error.message 
    });
  }
});

// PUT /api/admin/profile - Update admin profile
router.put('/profile', adminAuth, async (req, res) => {
  try {
    const { name } = req.body;

    console.log(`👤 Updating admin profile: ${name} for ${req.admin.email}`);

    // Firebase Admin User Only - Update profile in Firebase
    if (!req.admin.uid) {
      return res.status(400).json({
        success: false,
        message: 'Only Firebase admin users can update profiles'
      });
    }

    try {
      console.log('🔥 Updating Firebase admin profile...');
      
      // Update display name in Firebase Admin
      await admin.auth().updateUser(req.admin.uid, {
        displayName: name
      });

      console.log('✅ Firebase admin profile updated successfully');

      const updatedAdmin = {
        email: req.admin.email,
        name: name,
        role: 'admin',
        uid: req.admin.uid
      };

      res.json({
        success: true,
        message: 'Profile updated successfully in Firebase',
        admin: updatedAdmin
      });

    } catch (firebaseError) {
      console.error('❌ Firebase profile update error:', firebaseError);
      
      if (firebaseError.code === 'auth/user-not-found') {
        return res.status(404).json({
          success: false,
          message: 'Admin user not found in Firebase'
        });
      }

      return res.status(500).json({
        success: false,
        message: 'Failed to update profile in Firebase',
        error: firebaseError.message
      });
    }

  } catch (error) {
    console.error('❌ Profile update error:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Failed to update profile',
      error: error.message 
    });
  }
});

// PUT /api/admin/password - Change admin password
router.put('/password', adminAuth, async (req, res) => {
  try {
    const { currentPassword, newPassword } = req.body;

    console.log('🔒 Admin password change request for:', req.admin.email);

    // Firebase Admin User Only - Update password in Firebase
    if (!req.admin.uid) {
      return res.status(400).json({
        success: false,
        message: 'Only Firebase admin users can change passwords'
      });
    }

    try {
      console.log('🔥 Updating Firebase admin password...');
      
      // Update password in Firebase Admin
      await admin.auth().updateUser(req.admin.uid, {
        password: newPassword
      });

      console.log('✅ Firebase admin password updated successfully');

      res.json({
        success: true,
        message: 'Password updated successfully in Firebase'
      });

    } catch (firebaseError) {
      console.error('❌ Firebase password update error:', firebaseError);
      
      if (firebaseError.code === 'auth/user-not-found') {
        return res.status(404).json({
          success: false,
          message: 'Admin user not found in Firebase'
        });
      }
      
      if (firebaseError.code === 'auth/weak-password') {
        return res.status(400).json({
          success: false,
          message: 'Password should be at least 6 characters'
        });
      }

      return res.status(500).json({
        success: false,
        message: 'Failed to update password in Firebase',
        error: firebaseError.message
      });
    }

  } catch (error) {
    console.error('❌ Password update error:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Failed to update password',
      error: error.message 
    });
  }
});

// Health check endpoints
router.get('/health/database', adminAuth, async (req, res) => {
  try {
    await mongoose.connection.db.admin().ping();
    res.json({
      success: true,
      message: 'Database connected',
      status: 'connected'
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Database connection failed',
      error: error.message
    });
  }
});

router.get('/health/elevenlabs', adminAuth, async (req, res) => {
  try {
    // Mock ElevenLabs health check
    const hasApiKey = !!process.env.ELEVENLABS_API_KEY;
    
    res.json({
      success: hasApiKey,
      message: hasApiKey ? 'ElevenLabs API configured' : 'ElevenLabs API key missing',
      status: hasApiKey ? 'active' : 'error'
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

router.get('/health/runway', adminAuth, async (req, res) => {
  try {
    // Mock Runway health check
    const hasApiKey = !!process.env.RUNWAY_API_KEY;
    
    res.json({
      success: hasApiKey,
      message: hasApiKey ? 'Runway API configured' : 'Runway API key missing',
      status: hasApiKey ? 'active' : 'error'
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

router.get('/health/did', adminAuth, async (req, res) => {
  try {
    // Check D-ID API configuration
    const hasApiKey = !!process.env.DID_API_KEY;
    const hasBaseUrl = !!process.env.DID_BASE_URL;
    
    res.json({
      success: hasApiKey && hasBaseUrl,
      message: hasApiKey && hasBaseUrl ? 'D-ID API configured' : 'D-ID API key or base URL missing',
      status: hasApiKey && hasBaseUrl ? 'active' : 'error'
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

module.exports = router;