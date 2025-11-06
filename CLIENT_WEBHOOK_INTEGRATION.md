# Client Website Payment Integration

This document explains how to integrate client websites with the Video Generator App's automatic user creation system using Stripe webhooks.

## Overview

The system allows clients to run ads/campaigns that direct users to their landing pages. When users make payments through the client's website, the system automatically:

1. **Creates Firebase authentication account** with random password
2. **Creates MongoDB user record** with complete profile
3. **Calculates and adds credits** based on payment amount
4. **Sends welcome email** with login credentials and app download links
5. **Tracks client source** for analytics and commission tracking

## Architecture

```
Client Website → Stripe Payment → Webhook → Video Gen Backend → Firebase + MongoDB + Email
```

### Flow Diagram

```
User clicks ad → Client landing page → Payment form → Stripe processes → 
Webhook fired → Backend processes → Account created → Welcome email sent
```

## Webhook Integration

### Endpoint Details

**URL:** `POST https://your-backend-domain.com/api/payments/webhook/client-payment`

**Headers Required:**
- `stripe-signature`: Stripe webhook signature for verification
- `x-client-source`: (Optional) Identifier for the client source
- `content-type`: `application/json`

### Webhook Setup in Client's Stripe Account

1. **Go to Stripe Dashboard** → Webhooks → Add endpoint
2. **Endpoint URL:** `https://your-backend-domain.com/api/payments/webhook/client-payment?client=your-client-name`
3. **Events to send:**
   - `payment_intent.succeeded`
   - `payment_intent.payment_failed`
4. **Copy webhook secret** for environment configuration

### Environment Variables

Add to your backend `.env` file:

```env
# Client Website Integration
CLIENT_STRIPE_WEBHOOK_SECRET=whsec_your_client_webhook_secret_here

# Email Service (for welcome emails)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_SECURE=false
SMTP_USER=your-email@gmail.com
SMTP_PASS=your-app-password
EMAIL_FROM_NAME=Video Generator App
```

## Payment Intent Requirements

For automatic user creation, the payment intent must include:

### Required Metadata

```javascript
const paymentIntent = await stripe.paymentIntents.create({
  amount: 2999, // $29.99 in cents
  currency: 'usd',
  receipt_email: 'customer@example.com', // REQUIRED: Customer email
  metadata: {
    customer_name: 'John Doe', // REQUIRED: Customer name
    customer_email: 'customer@example.com', // Backup email
    client_source: 'landing-page-1', // Optional: Specific source tracking
    campaign_id: 'summer-2024', // Optional: Campaign tracking
    // Add any other custom metadata
  },
  automatic_payment_methods: {
    enabled: true,
  },
});
```

### Alternative: Using Customer Object

```javascript
// Option 1: Create customer first
const customer = await stripe.customers.create({
  email: 'customer@example.com',
  name: 'John Doe',
  metadata: {
    source: 'client-website'
  }
});

// Then create payment intent with customer
const paymentIntent = await stripe.paymentIntents.create({
  amount: 2999,
  currency: 'usd',
  customer: customer.id,
  receipt_email: 'customer@example.com',
  // ... rest of configuration
});
```

## Credit Calculation

The system automatically calculates credits based on payment amount:

```javascript
// Default rate: 50 credits per dollar
const creditsPerDollar = 50;
const credits = Math.floor(amountInDollars * creditsPerDollar);
const minimumCredits = 10; // Minimum for any payment

// Examples:
// $9.99 = 499 credits
// $24.99 = 1,249 credits
// $49.99 = 2,499 credits
```

## User Account Creation Process

### 1. Firebase Authentication
- **Email:** From payment intent
- **Password:** Auto-generated 12-character secure password
- **Display Name:** From customer name or email prefix
- **Email Verified:** `false` (user must verify)

### 2. MongoDB User Record
```javascript
{
  uid: "firebase-uid-here",
  email: "customer@example.com",
  name: "John Doe",
  availableCredits: 1249, // Calculated from payment
  credits: 1249, // Legacy field sync
  totalPurchased: 1249,
  clientAccount: {
    isClientUser: true,
    clientSource: "client-website-name",
    paymentSource: "stripe-webhook",
    automaticallyCreated: true,
    clientPaymentId: "pi_xxx",
    welcomeEmailSent: true
  },
  metadata: {
    signupSource: "client-website",
    clientWebhookData: { /* original webhook data */ }
  }
}
```

### 3. Welcome Email
Automatically sent with:
- **Login credentials** (email + generated password)
- **Credit balance** information
- **App download links** (Android/iOS)
- **Getting started** instructions
- **Support contact** information

## Client Integration Examples

### Frontend Payment Form

```html
<!DOCTYPE html>
<html>
<head>
    <title>Get Video Credits</title>
    <script src="https://js.stripe.com/v3/"></script>
</head>
<body>
    <form id="payment-form">
        <input type="email" id="email" placeholder="Your Email" required>
        <input type="text" id="name" placeholder="Your Name" required>
        <select id="package">
            <option value="999">Starter - $9.99 (500 credits)</option>
            <option value="2499">Pro - $24.99 (1,250 credits)</option>
            <option value="4999">Business - $49.99 (2,500 credits)</option>
        </select>
        <button type="submit">Purchase Credits</button>
    </form>

    <script>
        const stripe = Stripe('pk_test_your_client_publishable_key');

        document.getElementById('payment-form').addEventListener('submit', async (e) => {
            e.preventDefault();
            
            const email = document.getElementById('email').value;
            const name = document.getElementById('name').value;
            const amount = document.getElementById('package').value;

            // Create payment intent on your server
            const response = await fetch('/create-payment-intent', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    amount: parseInt(amount),
                    email: email,
                    name: name
                })
            });

            const { client_secret } = await response.json();

            // Confirm payment with Stripe
            const { error } = await stripe.confirmCardPayment(client_secret, {
                payment_method: {
                    card: cardElement,
                    billing_details: {
                        name: name,
                        email: email
                    }
                }
            });

            if (!error) {
                // Payment successful - webhook will handle account creation
                window.location.href = '/success';
            }
        });
    </script>
</body>
</html>
```

### Backend Payment Intent Creation

```javascript
// Client's backend endpoint
app.post('/create-payment-intent', async (req, res) => {
    const { amount, email, name } = req.body;

    try {
        const paymentIntent = await stripe.paymentIntents.create({
            amount: amount, // Amount in cents
            currency: 'usd',
            receipt_email: email,
            metadata: {
                customer_email: email,
                customer_name: name,
                client_source: 'your-client-identifier',
                package_type: getPackageType(amount),
                created_at: new Date().toISOString()
            },
            automatic_payment_methods: {
                enabled: true,
            },
        });

        res.json({
            client_secret: paymentIntent.client_secret
        });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

function getPackageType(amount) {
    switch(amount) {
        case 999: return 'starter';
        case 2499: return 'pro';
        case 4999: return 'business';
        default: return 'custom';
    }
}
```

## Webhook Response Handling

### Success Response
```json
{
  "received": true,
  "processed": true,
  "userCreated": true,
  "creditsAdded": 1249,
  "paymentId": "pi_xxx",
  "userId": "firebase-uid"
}
```

### Error Response
```json
{
  "received": true,
  "processed": false,
  "error": "Customer email required for account creation",
  "paymentId": "pi_xxx"
}
```

## Testing

### Test Webhook Endpoint
```bash
POST /api/payments/test-client-webhook
```

Use this endpoint in development to test the user creation flow with sample data.

### Webhook Testing with Stripe CLI
```bash
stripe listen --forward-to localhost:5000/api/payments/webhook/client-payment
stripe trigger payment_intent.succeeded
```

## Monitoring & Analytics

### Client User Statistics
```bash
GET /api/payments/admin/client-users
```

Returns analytics on client users including:
- Total users per client source
- Credit allocation statistics
- Recent user creation data
- Revenue tracking per client

### Example Response:
```json
{
  "success": true,
  "stats": [
    {
      "_id": "client-website-1",
      "totalUsers": 45,
      "clientUsers": 45,
      "totalCreditsAllocated": 56250,
      "totalSpent": 1125.55
    }
  ],
  "recentUsers": [
    {
      "email": "user@example.com",
      "name": "John Doe",
      "availableCredits": 1249,
      "createdAt": "2024-01-15T10:30:00Z",
      "clientAccount": {
        "clientSource": "client-website-1",
        "automaticallyCreated": true
      }
    }
  ]
}
```

## Security Considerations

### 1. Webhook Signature Verification
Always verify Stripe webhook signatures to prevent fraud:

```javascript
const sig = req.headers['stripe-signature'];
const event = stripe.webhooks.constructEvent(req.body, sig, webhookSecret);
```

### 2. Environment Secrets
- Store webhook secrets securely in environment variables
- Use different webhook secrets for each client if needed
- Rotate secrets periodically

### 3. Email Security
- Use app-specific passwords for SMTP authentication
- Consider using dedicated email service (SendGrid, etc.) for production
- Implement rate limiting on welcome emails

### 4. User Data Protection
- Generated passwords are cleared after email is sent
- Store only necessary customer data
- Implement data retention policies

## Error Handling

### Common Issues and Solutions

1. **Missing Customer Email**
   - Ensure `receipt_email` or `metadata.customer_email` is provided
   - Add validation on client payment form

2. **Webhook Signature Verification Failed**
   - Check webhook secret configuration
   - Ensure raw body parsing for webhook endpoint

3. **Firebase User Creation Failed**
   - Handle duplicate email addresses gracefully
   - Check Firebase project permissions

4. **Email Delivery Failed**
   - Verify SMTP credentials and configuration
   - Check spam filters and email provider limits

## Support & Troubleshooting

For integration support:
- **Email:** developer-support@videogenapp.com
- **Documentation:** This guide + API references
- **Test Environment:** Use webhook test endpoints for development

## Version History

- **v1.0.0:** Initial client webhook integration
- **v1.0.1:** Added comprehensive email templates and error handling
- **v1.0.2:** Enhanced user analytics and monitoring features