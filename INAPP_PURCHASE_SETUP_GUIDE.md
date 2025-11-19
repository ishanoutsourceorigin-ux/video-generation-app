# 🛒 In-App Purchase Setup Guide - CloneX AI

## 📋 **Overview**
This guide covers complete In-App Purchase setup for CloneX AI avatar video generation app in App Store Connect.

---

## 🎯 **Credit Packages to Create**

### **Package 1: Basic Pack**
```
Type: Consumable
Reference Name: Basic Credits Pack
Product ID: basic_credits_500
Price: $9.99 (Tier 10)
Credits: 500
```

### **Package 2: Starter Pack** 
```
Type: Consumable
Reference Name: Starter Credits Pack
Product ID: starter_credits_1300
Price: $24.99 (Tier 25)
Credits: 1300
```

### **Package 3: Pro Pack**
```
Type: Consumable
Reference Name: Pro Credits Pack
Product ID: pro_credits_4000
Price: $69.99 (Tier 70)
Credits: 4000
```

### **Package 4: Business Pack**
```
Type: Consumable
Reference Name: Business Credits Pack
Product ID: business_credits_9000
Price: $149.99 (Tier 150)
Credits: 9000
```

---

## 🔧 **Step-by-Step Setup Process**

### **Step 1: Navigate to In-App Purchases**
```
App Store Connect → Apps → CloneX AI → Features → In-App Purchases → "+"
```

### **Step 2: Create New In-App Purchase**
1. Click **"+"** button
2. Select **"Consumable"** type
3. Fill in basic information

### **Step 3: Fill Required Information**

#### **Basic Information:**
```
Type: Consumable
Reference Name: [From packages above]
Product ID: [From packages above]
```

#### **Availability:**
```
☑️ All countries or regions selected
☐ Remove from sale (leave unchecked)
```

#### **Price Schedule:**
```
Click "Add Pricing"
Select appropriate tier:
- Basic: Tier 10 ($9.99)
- Starter: Tier 25 ($24.99)
- Pro: Tier 70 ($69.99)
- Business: Tier 150 ($149.99)

Start Date: Today
End Date: Leave blank (ongoing)
```

#### **App Store Localization:**
Click "Add Localization" → Select "English (U.S.)"

**For Basic Pack (500 Credits):**
```
Display Name: 500 Credits

Description:
Generate up to 500 AI avatar videos! Perfect for getting started with CloneX. Each credit generates one personalized avatar video from your photos and text.

✓ 500 video generation credits
✓ High-quality AI avatars  
✓ Unlimited downloads
✓ Credits never expire
✓ Great starter value
```

**For Starter Pack (1300 Credits):**
```
Display Name: 1300 Credits

Description:
Generate up to 1300 AI avatar videos with bonus credits! Most popular choice for regular users and content creators.

✓ 1300 video generation credits
✓ High-quality AI avatars
✓ Unlimited downloads  
✓ Credits never expire
✓ Best value for regular users
✓ 300 bonus credits included
```

**For Pro Pack (4000 Credits):**
```
Display Name: 4000 Credits

Description:
Professional pack for heavy users - 4000 credits for serious content creators. Generate thousands of high-quality AI avatar videos.

✓ 4000 video generation credits
✓ High-quality AI avatars
✓ Unlimited downloads
✓ Credits never expire
✓ Perfect for professionals
✓ Maximum savings per credit
```

**For Business Pack (9000 Credits):**
```
Display Name: 9000 Credits

Description:
Business solution with maximum credits - 9000 credits for enterprises and power users. Create unlimited content for your business needs.

✓ 9000 video generation credits
✓ High-quality AI avatars
✓ Unlimited downloads
✓ Credits never expire
✓ Best value per credit
✓ Enterprise-level package
```

#### **Screenshot (1024x1024px):**
Create images for each package with:
- Large credit number (e.g., "100", "500", "1000", "2500")
- Package name (e.g., "STARTER PACK")
- CloneX branding
- Clean, professional design

#### **Review Information:**
```
Review Notes:
CloneX AI uses a credit-based system for avatar video generation:

• 1 credit = 1 AI avatar video (up to 60 seconds)
• Users upload photos to create personalized avatars
• Users enter text, AI generates avatar speaking it
• Credits consumed only when videos are successfully created
• No subscription required - pay-per-use model
• Credits never expire after purchase

HOW IT WORKS:
1. User uploads photo for avatar creation
2. User types text message
3. User spends 1 credit to generate video
4. AI creates avatar speaking the text
5. User downloads/shares the video

TEST ACCOUNT:
Email: reviewdemo@clonexai.com
Password: AppleReview2025!
Pre-loaded with credits for testing purchases in sandbox mode.

All purchases processed through Apple's secure payment system.
```

#### **Tax Category:**
```
Leave as "Match to parent app"
```

---

## 📸 **Screenshot Creation Guide**

### **Image Specifications:**
- Size: 1024x1024 pixels
- Format: PNG or JPG
- Clean, professional design
- Include credit amount prominently

### **Design Elements:**
```
For 500 Credits (Basic Pack):
- Large "500" number
- "BASIC PACK" subtitle
- CloneX logo/branding
- Clean background

For 1300 Credits (Starter Pack):
- Large "1300" number
- "STARTER PACK" subtitle
- "Most Popular" badge
- CloneX branding

For 4000 Credits (Pro Pack):
- Large "4000" number
- "PRO PACK" subtitle
- "Professional" badge
- CloneX branding

For 9000 Credits (Business Pack):
- Large "9000" number
- "BUSINESS PACK" subtitle
- "Best Value" badge
- CloneX branding
```

---

## 🔄 **Submission Process**

### **Important: First IAP Submission Rule**
```
⚠️ Your first in-app purchase MUST be submitted with your app version
⚠️ Cannot submit IAPs separately before app approval
⚠️ Must upload app binary first
```

### **Correct Submission Steps:**
```
1. Create all in-app purchases (save as "Ready to Submit")
2. Complete your app version submission  
3. Add IAPs to your app version:
   App Store → [Version] → In-App Purchases and Subscriptions → "+"
4. Select your created IAPs
5. Submit app version (IAPs included automatically)
```

### **After First Approval:**
```
✅ Additional IAPs can be submitted independently
✅ No need for new app versions
✅ Can add more credit packages anytime
```

---

## 📋 **Pre-Submission Checklist**

### **For Each In-App Purchase:**
```
☐ Type: Consumable selected
☐ Product ID matches exactly: basic_credits_500, starter_credits_1300, pro_credits_4000, business_credits_9000
☐ Reference Name is descriptive
☐ Pricing tier selected and saved ($9.99, $24.99, $69.99, $149.99)
☐ English localization added with display name and description
☐ 1024x1024px screenshot uploaded
☐ Review notes completed with testing instructions
☐ Tax category set (match to parent app)
☐ Status shows "Ready to Submit"
```

### **Before App Submission:**
```
☐ All 4 credit packages created (Basic, Starter, Pro, Business)
☐ All IAPs show "Ready to Submit" status
☐ App binary uploaded successfully
☐ IAPs added to app version
☐ App description mentions credit system
☐ Demo account has credits for testing
☐ Product IDs match exactly with Flutter app code
```

---

## 🎯 **Testing Guidelines**

### **Sandbox Testing:**
```
1. Use TestFlight for IAP testing
2. Create sandbox test accounts
3. Test all credit packages
4. Verify credit allocation after purchase
5. Test video generation with credits
6. Confirm purchase restoration
```

### **Test Account Setup:**
```
Apple ID: Create separate test Apple ID
Region: Same as your app's primary market
Payment: Use Apple's test payment methods
Credits: Pre-load demo account with credits
```

---

## 🚨 **Common Issues & Solutions**

### **"Missing Metadata" Error:**
```
Problem: Required fields not completed
Solution: Add pricing and localization
```

### **"Cannot Submit IAP" Error:**
```
Problem: Trying to submit IAP before app
Solution: Submit with app version first
```

### **Product ID Already Exists:**
```
Problem: ID used in another app/account
Solution: Use unique product IDs with your bundle identifier
```

### **Screenshot Upload Failed:**
```
Problem: Wrong image size or format
Solution: Use exactly 1024x1024px PNG/JPG
```

---

## 📞 **Support Information**

### **If Issues Occur:**
```
1. Check Apple Developer Documentation
2. Contact App Store Connect Support
3. Review In-App Purchase guidelines
4. Test in sandbox environment first
```

### **Important Resources:**
```
- App Store Connect Help
- In-App Purchase Programming Guide  
- StoreKit Documentation
- App Store Review Guidelines (3.1 Payments)
```

---

## ✅ **Final Notes**

### **Key Points:**
- Product IDs must match exactly: basic_credits_500, starter_credits_1300, pro_credits_4000, business_credits_9000
- Screenshots are required for approval (1024x1024px)
- First IAP must be submitted with app version
- Test thoroughly in sandbox before submission
- Keep descriptions clear and benefit-focused
- Use tier pricing: $9.99, $24.99, $69.99, $149.99

### **Success Metrics:**
- All 4 IAPs approved with app
- Purchase flow works smoothly
- Credits allocated correctly (500, 1300, 4000, 9000)
- Users can generate videos with purchased credits
- Backend properly verifies purchases

---

**🎉 Your CloneX AI app will have a complete, professional in-app purchase system ready for the App Store!**

**Last Updated:** November 19, 2025  
**Created for:** CloneX AI Avatar Video Generator  
**Version:** 1.0.1 (Build 12)
