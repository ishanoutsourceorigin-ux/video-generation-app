# 🎮 Google Play Console Products Setup

## 📍 Complete List of Products to Add

---

## 1️⃣ ONE-TIME PRODUCTS (Credit Top-ups)

### Product #1: 10 Credits
```
Product ID: topup_10credits_10
Name: 10 Credits Top-up
Description: Add 10 credits to your account. Each credit = 1 minute of AI-generated video content. Quick top-up for when you need a few more videos.

Purchase option ID: baseplan
Purchase type: Buy
Price: $10.00 USD
Tags: credits
```

---

### Product #2: 20 Credits (Save $2)
```
Product ID: topup_20credits_18
Name: 20 Credits Top-up
Description: Add 20 credits to your account. Each credit = 1 minute of AI-generated video. Save $2 compared to buying 10 credits twice!

Purchase option ID: baseplan
Purchase type: Buy
Price: $18.00 USD
Tags: credits
```

---

### Product #3: 30 Credits (Save $5 - Most Popular)
```
Product ID: topup_30credits_25
Name: 30 Credits Top-up
Description: Add 30 credits to your account. Each credit = 1 minute of AI-generated video. Save $5! Most popular top-up option.

Purchase option ID: baseplan
Purchase type: Buy
Price: $25.00 USD
Tags: credits
```

---

## 2️⃣ SUBSCRIPTIONS (Monthly Plans)

### Subscription #1: Basic Plan
```
Product ID: subbasic_30videos_27
Subscription name: Basic Monthly Subscription
Description: 30 videos per month (~30 minutes of AI-generated content). Perfect for getting started with CloneX.

Base plan ID: monthlybasic (no hyphens, no underscores!)
Price: $27.00 USD/month (billing handled automatically by Google Play)
Free trial: Optional (recommended 7 days)
Grace period: 3 days
Tags: subscription, basic   
```

---

### Subscription #2: Starter Plan (Most Popular)
```
Product ID: substarter_60videos_47
Subscription name: Starter Monthly Subscription
Description: 60 videos per month (~60 minutes of AI-generated content). Best for regular creators. Most popular choice!

Base plan ID: monthlystarter (no hyphens, no underscores!)
Price: $47.00 USD/month (billing handled automatically by Google Play)
Free trial: Optional (recommended 7 days)
Grace period: 3 days
Tags: subscription, starter, popular
```

---

### Subscription #3: Pro Plan
```
Product ID: subpro_150videos_97
Subscription name: Pro Monthly Subscription
Description: 150 videos per month (~150 minutes of AI-generated content). Ideal for professionals and content agencies.

Base plan ID: monthlypro (no hyphens, no underscores!)
Price: $97.00 USD/month (billing handled automatically by Google Play)
Free trial: Optional (recommended 7 days)
Grace period: 3 days
Tags: subscription, pro
```

---

## 📋 Quick Reference Table

| Type | Product ID | Name | Price | Credits/Videos |
|------|-----------|------|-------|----------------|
| Topup | `topup_10credits_10` | 10 Credits Top-up | $10 | 10 credits |
| Topup | `topup_20credits_18` | 20 Credits Top-up | $18 | 20 credits |
| Topup | `topup_30credits_25` | 30 Credits Top-up | $25 | 30 credits |
| Sub | `subbasic_30videos_27` | Basic Monthly | $27/mo | 30 videos |
| Sub | `substarter_60videos_47` | Starter Monthly | $47/mo | 60 videos |
| Sub | `subpro_150videos_97` | Pro Monthly | $97/mo | 150 videos |

---

## 🎯 Step-by-Step Setup Instructions

### For ONE-TIME PRODUCTS:
1. Go to: **Monetize → Products → One-time products**
2. Click **"Create product"**
3. Fill in:
   - Product ID (exactly as shown above)
   - Name
   - Description
4. Click **"Next"**
5. Fill in:
   - Purchase option ID: `baseplan`
   - Purchase type: `Buy`
   - Price
6. Click **"Save"** and **"Activate"**
7. Repeat for all 3 topup products

---

### For SUBSCRIPTIONS:
1. Go to: **Monetize → Products → Subscriptions**
2. Click **"Create subscription"**
3. Fill in Product details:
   - Product ID (exactly as shown above - e.g., `subbasic_30videos_27`)
   - Subscription name (e.g., "Basic Monthly Subscription")
   - Description
4. Click **"Continue"** or **"Create"**
5. Add Base Plan (this happens automatically or click "Add base plan"):
   - Base plan ID: `monthlybasic` (no hyphens, no underscores, lowercase)
   - The billing period is set by selecting the plan type:
     - Choose **"Monthly"** or the system will auto-detect from your configuration
     - Google Play Console will handle the recurring billing automatically
6. Set Price:
   - Enter price: $27.00 (for Basic plan)
   - Select countries: "All countries" or choose specific ones
   - Google will auto-convert to local currencies
7. Optional settings (Recommended):
   - Free trial: Toggle ON and set to 7 days (if you want to offer trial)
   - Grace period: Toggle ON and set to 3 days (gives users time to fix payment)
   - Account hold: Enable (recommended for better user retention)
8. Review and click **"Activate"**
9. Repeat for all 3 subscription products

**Note:** Google Play Console automatically handles monthly billing. You don't need to manually select billing period - it's configured through the base plan setup.

---

## ⚠️ Important Notes

### Product ID Rules:
- ✅ Must start with lowercase letter or number
- ✅ Can contain: lowercase letters, numbers, underscores
- ❌ Cannot contain: spaces, uppercase, special characters
- ❌ Cannot be changed after creation

### Purchase Option ID Rules:
- ✅ Must start with lowercase letter or number
- ✅ Can contain: lowercase letters, numbers, hyphens
- ❌ Cannot contain: underscores, spaces, uppercase

### Pricing:
- All prices are in USD
- Google Play converts to local currencies automatically
- You can set custom prices per country if needed

### Testing:
- Products must be **ACTIVE** to work
- Use Internal Testing or Closed Testing track first
- Add test accounts in: Settings → License testing

---

## ✅ Completion Checklist

### One-time Products:
- [ ] `topup_10credits_10` created and active
- [ ] `topup_20credits_18` created and active
- [ ] `topup_30credits_25` created and active

### Subscriptions:
- [ ] `subbasic_30videos_27` created and active
- [ ] `substarter_60videos_47` created and active
- [ ] `subpro_150videos_97` created and active

### App Configuration:
- [ ] App uploaded to Internal Testing track
- [ ] Test account added to License testing
- [ ] All 6 products tested successfully

---

## 🔗 Exact Product IDs (Copy/Paste These)

```
topup_10credits_10
topup_20credits_18
topup_30credits_25
subbasic_30videos_27
substarter_60videos_47
subpro_150videos_97
```

---

## 💡 Tips

1. **Create products in order** - Start with topups, then subscriptions
2. **Double-check Product IDs** - They must match your app code exactly
3. **Test thoroughly** - Use Internal Testing before production
4. **Set up properly** - Enable grace periods and account holds for better UX
5. **Monitor purchases** - Check Google Play Console reports regularly

---

## 📞 Need Help?

Common issues:
- **"Product not found"** → Product ID mismatch or not active
- **"Item unavailable"** → Not published to your testing track
- **"Already own this"** → Use different test account or wait 24 hours

---

**Last Updated:** November 15, 2025
**App:** CloneX Video Generator
**Package:** com.clonex.video_gen_app
