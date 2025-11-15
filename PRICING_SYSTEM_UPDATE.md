# 🎯 Pricing System Update - November 15, 2025

## ✅ Changes Implemented

### **1. New Credit System**
- **1 credit = 1 minute** of avatar-based video
- **Rounded up**: 1 minute 1 second = 2 credits
- **Text-based videos**: Coming Soon (code preserved for future use)

---

## **💳 New Pricing Structure**

### **A. Monthly Subscriptions** (In-App Purchase - Only ONE active at a time)

| Plan | Videos/Month | Price | Description |
|------|-------------|-------|-------------|
| **Basic** | 30 videos | $27/month | ~30 minutes of content |
| **Starter** | 60 videos | $47/month | ~60 minutes of content (Most Popular) |
| **Pro** | 150 videos | $97/month | ~150 minutes of content |

**Product IDs** (must be configured in Google Play Console):
- `subbasic_30videos_27`
- `substarter_60videos_47`
- `subpro_150videos_97`

---

### **B. Credit Top-ups** (Can be purchased anytime, even with active subscription)

| Package | Credits | Price | Savings |
|---------|---------|-------|---------|
| **10 Credits** | 10 | $10 | - |
| **20 Credits** | 20 | $18 | Save $2 |
| **30 Credits** | 30 | $25 | Save $5 (Most Popular) |

**Product IDs** (must be configured in Google Play Console):
- `topup_10credits_10`
- `topup_20credits_18`
- `topup_30credits_25`

---

### **C. Faceless LTD Plans** (Stripe Webhook - from Client Websites)

| Stripe Amount | Videos/Month | Plan |
|--------------|-------------|------|
| **$60** | 30 videos | Faceless Basic |
| **$97** | 60 videos | Faceless Starter |
| **$197** | 150 videos | Faceless Pro |

**How it works:**
1. User pays on client website via Stripe
2. Stripe webhook sends payment to backend
3. Backend auto-creates CloneX account
4. User receives email with login credentials
5. Credits added to account

---

## **📱 Frontend Changes**

### **Files Modified:**

#### **1. `lib/Services/credit_system_service.dart`**
- ✅ Updated credit calculation: `1 credit = 1 minute`
- ✅ Added `subscriptionPlans` map (Basic, Starter, Pro)
- ✅ Added `creditTopups` map (10, 20, 30 credits)
- ✅ Added `facelessLtdPlans` map ($60, $97, $197)
- ✅ New method: `calculateRequiredCredits()` with seconds support
- ✅ New methods: `getAvailableSubscriptions()`, `getAvailableCreditTopups()`
- ✅ New method: `getFacelessPlanByAmount()` for webhook processing

#### **2. `lib/Services/payment_service.dart`**
- ✅ Added `subscriptionProductIds` map
- ✅ Added `topupProductIds` map
- ✅ Combined product IDs for easy lookup
- ✅ Kept legacy product IDs for backward compatibility

#### **3. `lib/Screens/dashboard_screen.dart`**
- ✅ Updated "Buy More Credits" section to "Monthly Subscriptions"
- ✅ Replaced 2x2 grid with column layout
- ✅ Added subscription plans display
- ✅ Added credit top-ups section
- ✅ Updated descriptions to show new credit system

#### **4. `lib/Screens/Settings/credit_purchase_screen.dart`**
- ✅ Split into two sections: Subscriptions and Top-ups
- ✅ Added info box explaining "1 credit = 1 minute"
- ✅ Updated credit usage info (avatar videos: 1 credit/min)
- ✅ Added "Coming Soon" for text-based videos
- ✅ Added `isSubscription` parameter to `_buildCreditPackage()`

#### **5. `lib/Screens/Video/create_video.dart`**
- ✅ Updated avatar video display: "1 credit per minute (rounded up)"
- ✅ Added "Coming Soon" badge for text-based videos
- ✅ Added `comingSoon` parameter to `_buildVideoOption()`
- ✅ Added visual indicators (grayed out) for coming soon features
- ✅ Updated `_checkCreditsAndNavigate()` to support seconds

---

## **🔧 Backend Changes**

### **Files Modified:**

#### **1. `backend/routes/payments.js`**
- ✅ Updated `getPlanCredits()` function with new pricing
  - Subscription plans: 30, 60, 150 videos
  - Credit topups: 10, 20, 30 credits
  - Faceless LTD: 30, 60, 150 videos
- ✅ Updated `getPlanPrice()` function with new prices
  - Subscriptions: $27, $47, $97
  - Topups: $10, $18, $25
  - Faceless LTD: $60, $97, $197
- ✅ Added `getPlanType()` function to determine plan category
- ✅ Added `getFacelessPlanFromAmount()` for webhook processing

#### **2. `backend/services/clientUserService.js`**
- ✅ Updated `calculateCreditsFromPayment()` with new Faceless LTD logic
  - $60 → 30 videos/month
  - $97 → 60 videos/month
  - $197 → 150 videos/month
- ✅ Added fallback calculation for custom amounts (~$2 per video)
- ✅ Updated minimum videos from 10 to 5

---

## **📋 Google Play Console Setup Required**

### **New Products to Create:**

#### **Subscriptions:**
1. **Product ID:** `subbasic_30videos_27`
   - **Name:** Basic Monthly Subscription
   - **Price:** $27.00
   - **Billing:** Monthly
   - **Description:** 30 videos per month (~30 minutes of content)

2. **Product ID:** `substarter_60videos_47`
   - **Name:** Starter Monthly Subscription
   - **Price:** $47.00
   - **Billing:** Monthly
   - **Description:** 60 videos per month (~60 minutes of content)

3. **Product ID:** `subpro_150videos_97`
   - **Name:** Pro Monthly Subscription
   - **Price:** $97.00
   - **Billing:** Monthly
   - **Description:** 150 videos per month (~150 minutes of content)

#### **In-App Products (Top-ups):**
1. **Product ID:** `topup_10credits_10`
   - **Name:** 10 Credits
   - **Price:** $10.00
   - **Type:** Consumable
   - **Description:** 10 additional credits (~10 minutes of videos)

2. **Product ID:** `topup_20credits_18`
   - **Name:** 20 Credits
   - **Price:** $18.00
   - **Type:** Consumable
   - **Description:** 20 additional credits (~20 minutes of videos) - Save $2!

3. **Product ID:** `topup_30credits_25`
   - **Name:** 30 Credits
   - **Price:** $25.00
   - **Type:** Consumable
   - **Description:** 30 additional credits (~30 minutes of videos) - Save $5!

---

## **🔗 Stripe Webhook Configuration**

### **For Faceless LTD Clients:**

**Webhook URL:**
```
https://video-generation-app-dar3.onrender.com/api/payments/webhook/client-payment?client=faceless-ltd
```

**Events to Subscribe:**
- `payment_intent.succeeded`
- `payment_intent.payment_failed`

**Expected Payment Amounts:**
- **$60.00** (6000 cents) → 30 videos/month
- **$97.00** (9700 cents) → 60 videos/month
- **$197.00** (19700 cents) → 150 videos/month

**Required Metadata:**
```javascript
{
  customer_email: "user@example.com",
  customer_name: "John Doe",
  client_source: "faceless-ltd"
}
```

---

## **🎨 User Experience Changes**

### **What Users Will See:**

1. **Dashboard - Credits Section:**
   - "Monthly Subscriptions" header
   - 3 subscription options (Basic, Starter, Pro)
   - "Add Extra Credits" section
   - 3 top-up options (10, 20, 30 credits)
   - Clear pricing and video counts

2. **Credit Purchase Screen:**
   - Info box: "1 credit = 1 minute (1 min 1 sec = 2 credits)"
   - Two sections: Subscriptions and Top-ups
   - "Coming Soon" badge for text-based videos
   - Updated credit usage information

3. **Video Creation:**
   - Text-Based: Shows "COMING SOON" badge (grayed out)
   - Avatar Video: Shows "1 credit per minute (rounded up)"
   - Click avatar option → proceeds normally
   - Click text option → shows coming soon dialog

---

## **💻 Technical Notes**

### **Credit Calculation Logic:**
```dart
// NEW SYSTEM
if (videoType == 'avatar-video') {
  final minutes = durationMinutes ?? 0;
  final seconds = durationSeconds ?? 0;
  
  if (seconds > 0) {
    return minutes + 1; // Round up
  }
  return minutes > 0 ? minutes : 1; // Minimum 1 credit
}
```

**Examples:**
- 1 minute 0 seconds = 1 credit
- 1 minute 1 second = 2 credits
- 2 minutes 30 seconds = 3 credits
- 5 minutes 0 seconds = 5 credits

### **Backward Compatibility:**
- ✅ Legacy `planConfigs` kept for old users
- ✅ Old product IDs stored as `legacyProductIds`
- ✅ Backend handles both old and new pricing
- ✅ Text-based video code preserved (not deleted)

---

## **🚀 Deployment Steps**

### **1. Backend Deployment:**
```bash
cd backend
git add .
git commit -m "Updated pricing system - subscriptions and topups"
git push origin main
# Backend will auto-deploy on Render
```

### **2. Frontend (Flutter App):**
```bash
cd ..
flutter clean
flutter pub get
flutter build appbundle --release
# Upload to Google Play Console
```

### **3. Google Play Console:**
- Create new subscription products
- Create new in-app products (topups)
- Set up Internal Testing with new products
- Test all purchases before production release

### **4. Stripe Webhook:**
- Configure webhook URL with `?client=faceless-ltd`
- Add webhook secret to backend `.env`
- Test webhook with Stripe CLI or test mode

---

## **✅ Testing Checklist**

### **Before Production:**
- [ ] Test Basic subscription purchase ($27)
- [ ] Test Starter subscription purchase ($47)
- [ ] Test Pro subscription purchase ($97)
- [ ] Test 10 credits topup ($10)
- [ ] Test 20 credits topup ($18)
- [ ] Test 30 credits topup ($25)
- [ ] Test avatar video with 1:00 duration (1 credit)
- [ ] Test avatar video with 1:01 duration (2 credits)
- [ ] Test Faceless LTD webhook ($60 → 30 videos)
- [ ] Verify text-based shows "Coming Soon"
- [ ] Check all UI displays correctly
- [ ] Verify credit balance updates

---

## **📝 Notes for Team**

### **Important:**
- Only **ONE subscription** can be active at a time
- Users can **buy top-ups anytime** (even with active subscription)
- **Text-based videos** code is preserved but disabled with "Coming Soon"
- **Faceless LTD** users get accounts via Stripe webhook automatically
- All prices are in **USD**
- Credit system uses **ceiling rounding** (1 min 1 sec = 2 credits)

### **For Future:**
- Text-based video feature can be re-enabled by removing `comingSoon: true`
- Additional subscription tiers can be added easily
- More topup options can be added to the maps
- Faceless LTD pricing can be adjusted in `facelessLtdPlans`

---

## **🎉 Summary**

**Successfully implemented:**
✅ New credit system (1 credit = 1 minute)  
✅ Monthly subscriptions ($27, $47, $97)  
✅ Credit top-ups ($10, $18, $25)  
✅ Faceless LTD webhook integration ($60, $97, $197)  
✅ "Coming Soon" for text-based videos  
✅ Updated all frontend UI  
✅ Updated all backend logic  
✅ Maintained backward compatibility  

**Ready for deployment! 🚀**
