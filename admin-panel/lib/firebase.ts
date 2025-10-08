import { initializeApp } from 'firebase/app';
import { getAuth } from 'firebase/auth';
import { getFirestore } from 'firebase/firestore';

const firebaseConfig = {
  apiKey: 'AIzaSyCuW1ugsdCKY597-XvYhZgyAWjnjKLowsc',
  authDomain: 'video-generator-app-dc8ee.firebaseapp.com',
  projectId: 'video-generator-app-dc8ee',
  storageBucket: 'video-generator-app-dc8ee.firebasestorage.app',
  messagingSenderId: '288062969366',
  appId: '1:288062969366:web:1b47c8b19be8a2fa820737',
  measurementId: 'G-4FCK58P396'
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);

// Initialize Firebase Authentication and get a reference to the service
export const auth = getAuth(app);

// Initialize Cloud Firestore and get a reference to the service
export const db = getFirestore(app);

export default app;