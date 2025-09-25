🚨 QUICK FIX for "Unknown API key" Error

The error happens because Cloudinary cloud name is not configured yet.

🔧 SOLUTION (Takes 2 minutes):

1️⃣ Get your Cloudinary cloud name:
   - Go to https://cloudinary.com
   - Sign up (free)
   - Copy your cloud name from the dashboard

2️⃣ Update the configuration:
   - Open: lib/Config/cloudinary_config.dart
   - Find: static const String cloudName = 'your_cloud_name';
   - Replace with: static const String cloudName = 'YOUR_ACTUAL_CLOUD_NAME';

3️⃣ Test:
   - Hot restart the app
   - Go to Settings > Profile Settings
   - Select an image and upload

✅ The app now has detailed console logs to help debug any issues!

💡 The console will show:
   - Configuration status
   - Upload progress
   - Specific error solutions
   - Success confirmations

Example console output:
=== Cloudinary Configuration Test ===
Cloud Name: my-cloud-123
Upload Preset: ml_default
Is Configured: true
=====================================
📤 Uploading to Cloudinary...
✅ Upload successful!
🔗 URL: https://res.cloudinary.com/...