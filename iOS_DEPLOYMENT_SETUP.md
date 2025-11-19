# 🍎 iOS App Store Deployment Guide - CloneX

## 📱 **Current Status**
- ✅ Bundle Identifier updated: `com.clonexai.videogenapp`
- ✅ Development Team placeholders added
- ✅ Privacy permissions configured
- ✅ App icons and splash screens set up
- ✅ Version: 1.0.1 (Build 12)

---

## 🚨 **CRITICAL STEPS BEFORE SUBMISSION**

### **1. Apple Developer Account Setup (REQUIRED)**
```bash
# You MUST have:
1. Apple Developer Program membership ($99/year)
2. Team ID from Apple Developer Console
3. App Store Connect access
```

### **2. Complete Xcode Configuration**
```bash
# Open in Xcode and configure:
cd ios
open Runner.xcworkspace

# In Xcode:
1. Select "Runner" project
2. Go to "Signing & Capabilities" 
3. Add your Team ID to DEVELOPMENT_TEAM
4. Enable "Automatically manage signing"
5. Select your Apple Developer team
```

### **3. Update Development Team ID**
After getting your Team ID from Apple Developer Console, update:
```bash
# Replace YOUR_TEAM_ID with actual Team ID
sed -i '' 's/DEVELOPMENT_TEAM = "";/DEVELOPMENT_TEAM = "YOUR_TEAM_ID";/g' ios/Runner.xcodeproj/project.pbxproj
```

---

## 🔧 **App Store Connect Setup**

### **1. Create App Record**
1. Go to App Store Connect → Apps → + (Add App)
2. **Bundle ID**: `com.clonexai.videogenapp`
3. **App Name**: CloneX - AI Avatar Video Generator
4. **SKU**: clonex-avatar-2024
5. **Language**: English (U.S.)

### **2. App Information**
```
Name: CloneX - AI Avatar Video Generator
Subtitle: Create Videos with AI Avatars
Category: Photo & Video
Content Rights: No, it does not contain, show, or access third-party content
Age Rating: 4+ (No Restricted Content)
```

### **3. Pricing & Availability**
```
Price: Free with In-App Purchases
Availability: All Countries
```

---

## 📝 **App Store Metadata Required**

### **Screenshots Needed (CRITICAL)**
You need screenshots for:
- **iPhone 6.7"** (iPhone 14 Pro Max): 3-10 screenshots
- **iPhone 6.5"** (iPhone 11 Pro Max): 3-10 screenshots  
- **iPhone 5.5"** (iPhone 8 Plus): 3-10 screenshots
- **iPad Pro 12.9"** (3rd gen): 3-10 screenshots
- **iPad Pro 12.9"** (6th gen): 3-10 screenshots

### **App Description**
```
Create stunning AI avatar videos with CloneX! Transform your photos into realistic AI avatars that can speak any text you provide.

🎭 AI Avatar Creation
• Upload your photos to create personalized avatars
• Advanced AI technology for realistic results
• Multiple avatar styles and expressions

🎬 Video Generation  
• Type any text and watch your avatar speak it
• High-quality video output
• Multiple languages supported

💳 Credit System
• Purchase credits to generate videos
• Flexible pricing plans for all needs
• Instant credit top-up

🔐 Secure & Private
• Your data is protected with enterprise-level security
• Firebase authentication
• No data sharing with third parties

Perfect for content creators, marketers, educators, and anyone wanting to create engaging video content!
```

### **Keywords**
```
AI, avatar, video, generator, deepfake, clone, voice, text to speech, content creation, marketing
```

### **Support Information**
```
Support URL: https://video-generation-app-dar3.onrender.com/support
Privacy Policy URL: https://video-generation-app-dar3.onrender.com/privacy
```

---

## 💰 **In-App Purchases Setup**

### **1. Create IAP Products**
In App Store Connect → Features → In-App Purchases:

```
Product 1:
- Reference Name: Basic Credits Pack
- Product ID: basic_credits_500
- Type: Consumable
- Price: $9.99 (Tier 10)
- Display Name: 500 Credits
- Description: Generate up to 500 AI avatar videos

Product 2:
- Reference Name: Starter Credits Pack  
- Product ID: starter_credits_1300
- Type: Consumable
- Price: $24.99 (Tier 25)
- Display Name: 1300 Credits
- Description: Generate up to 1300 AI avatar videos with bonus credits

Product 3:
- Reference Name: Pro Credits Pack
- Product ID: pro_credits_4000  
- Type: Consumable
- Price: $69.99 (Tier 69)
- Display Name: 4000 Credits
- Description: Professional pack for heavy users - 4000 credits

Product 4:
- Reference Name: Business Credits Pack
- Product ID: business_credits_9000
- Type: Consumable  
- Price: $149.99 (Tier 149)
- Display Name: 9000 Credits
- Description: Business solution with maximum credits - 9000 credits
```

### **2. Tax & Banking**
- Complete tax information in App Store Connect
- Add banking details for payment processing
- Fill out tax forms (W-9 for US, or appropriate forms for your country)

---

## 🔨 **Build & Upload Process**

### **1. Update Version (if needed)**
```yaml
# In pubspec.yaml
version: 1.0.1+12  # Already set correctly
```

### **2. Build Archive**
```bash
# Clean and build
flutter clean
flutter pub get

# Build iOS archive
flutter build ipa --release

# Alternative: Build in Xcode
cd ios
open Runner.xcworkspace
# Product → Archive in Xcode
```

### **3. Upload to App Store Connect**
```bash
# Option 1: Using Xcode
# After archive, click "Distribute App" → "App Store Connect"

# Option 2: Using Command Line
xcrun altool --upload-app -f build/ios/ipa/video_gen_app.ipa -u YOUR_APPLE_ID -p YOUR_APP_PASSWORD

# Option 3: Using Transporter App
# Download from Mac App Store, drag IPA file
```

---

## ✅ **Pre-Submission Checklist**

### **Technical Requirements**
- [ ] App builds without errors in Release mode
- [ ] All required icons are present (1024x1024 App Store icon)
- [ ] Privacy permissions are properly described
- [ ] No example bundle identifiers (fixed ✅)
- [ ] Development team is set (needs your Team ID)
- [ ] App doesn't crash on launch
- [ ] In-app purchases work correctly

### **App Store Requirements**  
- [ ] Screenshots for all required device sizes
- [ ] App description follows guidelines
- [ ] Privacy policy is accessible
- [ ] Support contact information provided
- [ ] Age rating is appropriate
- [ ] No restricted content
- [ ] Follows App Store Review Guidelines

### **Legal Requirements**
- [ ] Tax information completed
- [ ] Banking information added  
- [ ] App Store agreements signed
- [ ] Export compliance documented

---

## 🚀 **Submission Process**

### **1. TestFlight (Recommended)**
1. Upload build to App Store Connect
2. Add to TestFlight for internal testing
3. Test all functionality thoroughly
4. Get feedback from team members

### **2. App Store Review**
1. Add build to App Store version
2. Complete all metadata
3. Submit for review
4. Typical review time: 24-48 hours
5. Respond to any reviewer feedback

### **3. Launch**
1. Once approved, release immediately or schedule
2. Monitor crash reports and user feedback
3. Respond to user reviews
4. Track download and revenue metrics

---

## 🔧 **Common Issues & Solutions**

### **Build Errors**
```bash
# If CocoaPods issues:
cd ios && pod install && cd ..

# If signing issues:
# Open Xcode, go to Signing & Capabilities
# Select your team and enable "Automatically manage signing"

# If version conflicts:
flutter clean
flutter pub get
```

### **App Store Rejection Reasons**
1. **Missing screenshots** → Add all required sizes
2. **Privacy policy missing** → Add valid URL
3. **IAP not working** → Test purchases thoroughly
4. **Crashes on launch** → Test on physical devices
5. **Misleading description** → Be accurate about features

---

## 📞 **Support During Process**

### **If You Need Help**
1. **Apple Developer Support**: developer.apple.com/contact
2. **App Store Review**: Contact through App Store Connect
3. **Technical Issues**: Flutter/Firebase documentation
4. **IAP Problems**: Test with sandbox accounts first

---

## 🎯 **Expected Timeline**

```
Day 1: Complete Apple Developer Account setup
Day 2: Configure Xcode signing and build archive  
Day 3: Upload to App Store Connect, create app record
Day 4: Add screenshots and metadata
Day 5: Set up in-app purchases
Day 6: Submit for review
Day 7-8: App Store review process
Day 9: Launch! 🎉
```

---

## ✨ **Your App is Ready!**

Your CloneX app has all the technical requirements for App Store submission. The main remaining tasks are:

1. **Get Apple Developer Account** ($99)
2. **Add your Team ID** to Xcode configuration  
3. **Create app record** in App Store Connect
4. **Take screenshots** for all device sizes
5. **Upload build** and submit for review

**You're very close to launching on the App Store! 🚀**
