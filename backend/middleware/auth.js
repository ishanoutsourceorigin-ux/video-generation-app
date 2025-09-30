const admin = require('firebase-admin');

// Initialize Firebase Admin SDK
let firebaseInitialized = false;

if (!admin.apps.length) {
  // Check if Firebase credentials are provided and valid
  const hasFirebaseCredentials = process.env.FIREBASE_PROJECT_ID && 
                                 process.env.FIREBASE_PRIVATE_KEY && 
                                 process.env.FIREBASE_CLIENT_EMAIL;
  
  const isValidPrivateKey = process.env.FIREBASE_PRIVATE_KEY && 
                           process.env.FIREBASE_PRIVATE_KEY.includes('BEGIN PRIVATE KEY') &&
                           !process.env.FIREBASE_PRIVATE_KEY.includes('YOUR_ACTUAL_PRIVATE_KEY_HERE') &&
                           !process.env.FIREBASE_PRIVATE_KEY.includes('PLACEHOLDER_PRIVATE_KEY_CONTENT');

  if (hasFirebaseCredentials && isValidPrivateKey) {
    try {
      const serviceAccount = {
        projectId: process.env.FIREBASE_PROJECT_ID,
        privateKeyId: process.env.FIREBASE_PRIVATE_KEY_ID,
        privateKey: process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n'),
        clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
        clientId: process.env.FIREBASE_CLIENT_ID,
        authUri: process.env.FIREBASE_AUTH_URI || "https://accounts.google.com/o/oauth2/auth",
        tokenUri: process.env.FIREBASE_TOKEN_URI || "https://oauth2.googleapis.com/token",
      };

      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
        projectId: process.env.FIREBASE_PROJECT_ID,
      });
      
      firebaseInitialized = true;
      console.log('✅ Firebase Admin SDK initialized successfully');
    } catch (error) {
      console.error('❌ Firebase initialization failed:', error.message);
      console.warn('🔧 Running in development mode without Firebase');
    }
  } else {
    console.warn('🔧 Development Mode: Firebase credentials not configured');
    console.warn('   Set DEVELOPMENT_MODE=false and configure Firebase for production');
  }
}

const authMiddleware = async (req, res, next) => {
  try {
    // Check for temporary testing bypass (remove this in production with real Firebase)
    const isTemporaryTesting = process.env.TEMPORARY_FIREBASE_BYPASS === 'true';
    
    if (!firebaseInitialized) {
      if (isTemporaryTesting) {
        console.warn('⚠️  TEMPORARY BYPASS: Using test user (configure Firebase for production)');
        req.user = {
          uid: 'temp-user-for-testing',
          email: 'test@example.com',
          name: 'Test User',
          picture: null,
        };
        return next();
      }
      
      console.error('❌ Firebase not initialized. Configure Firebase credentials in .env');
      return res.status(500).json({ 
        error: 'Server configuration error. Please contact support.' 
      });
    }

    const authHeader = req.headers.authorization;
    
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ 
        error: 'Unauthorized: No valid authorization header' 
      });
    }

    const token = authHeader.split('Bearer ')[1];
    
    if (!token) {
      return res.status(401).json({ 
        error: 'Unauthorized: No token provided' 
      });
    }

    // Verify the Firebase ID token
    const decodedToken = await admin.auth().verifyIdToken(token);
    
    // Add user info to request object
    req.user = {
      uid: decodedToken.uid,
      email: decodedToken.email,
      name: decodedToken.name,
      picture: decodedToken.picture,
    };

    next();
  } catch (error) {
    console.error('Auth middleware error:', error);
    
    if (error.code === 'auth/id-token-expired') {
      return res.status(401).json({ 
        error: 'Unauthorized: Token expired' 
      });
    }
    
    if (error.code === 'auth/id-token-revoked') {
      return res.status(401).json({ 
        error: 'Unauthorized: Token revoked' 
      });
    }
    
    return res.status(401).json({ 
      error: 'Unauthorized: Invalid token' 
    });
  }
};

module.exports = authMiddleware;