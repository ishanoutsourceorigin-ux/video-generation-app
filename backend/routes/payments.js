const express = require('express');
const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);
const authMiddleware = require('../middleware/auth');

const router = express.Router();

// Create payment intent
router.post('/create-payment-intent', authMiddleware, async (req, res) => {
  try {
    const { amount, currency = 'usd', metadata = {} } = req.body;

    // Validation
    if (!amount || amount < 50) { // Minimum $0.50
      return res.status(400).json({
        error: 'Amount must be at least $0.50'
      });
    }

    // Create payment intent
    const paymentIntent = await stripe.paymentIntents.create({
      amount: Math.round(amount * 100), // Convert to cents
      currency: currency,
      metadata: {
        userId: req.user.uid,
        ...metadata
      },
      automatic_payment_methods: {
        enabled: true,
      },
    });

    res.json({
      clientSecret: paymentIntent.client_secret,
      paymentIntentId: paymentIntent.id
    });

  } catch (error) {
    console.error('Create payment intent error:', error);
    res.status(500).json({
      error: error.message || 'Failed to create payment intent'
    });
  }
});

// Get payment status
router.get('/payment-intent/:id', authMiddleware, async (req, res) => {
  try {
    const { id } = req.params;
    
    const paymentIntent = await stripe.paymentIntents.retrieve(id);
    
    // Verify this payment belongs to the authenticated user
    if (paymentIntent.metadata.userId !== req.user.uid) {
      return res.status(404).json({
        error: 'Payment not found'
      });
    }

    res.json({
      id: paymentIntent.id,
      status: paymentIntent.status,
      amount: paymentIntent.amount / 100,
      currency: paymentIntent.currency,
      created: paymentIntent.created,
      metadata: paymentIntent.metadata
    });

  } catch (error) {
    console.error('Get payment intent error:', error);
    res.status(500).json({
      error: error.message || 'Failed to retrieve payment'
    });
  }
});

// Stripe webhook endpoint
router.post('/webhook', express.raw({type: 'application/json'}), async (req, res) => {
  const sig = req.headers['stripe-signature'];

  let event;

  try {
    event = stripe.webhooks.constructEvent(req.body, sig, process.env.STRIPE_WEBHOOK_SECRET);
  } catch (err) {
    console.error('Webhook signature verification failed:', err.message);
    return res.status(400).send(`Webhook Error: ${err.message}`);
  }

  // Handle the event
  switch (event.type) {
    case 'payment_intent.succeeded':
      const paymentIntent = event.data.object;
      console.log('Payment succeeded:', paymentIntent.id);
      
      // TODO: Add credits to user account or handle successful payment
      // You can add your business logic here
      
      break;
    
    case 'payment_intent.payment_failed':
      const failedPayment = event.data.object;
      console.log('Payment failed:', failedPayment.id);
      break;
    
    default:
      console.log(`Unhandled event type: ${event.type}`);
  }

  res.json({received: true});
});

// Get Stripe publishable key
router.get('/config', async (req, res) => {
  res.json({
    publishableKey: process.env.STRIPE_PUBLISHABLE_KEY
  });
});

// Create customer
router.post('/create-customer', authMiddleware, async (req, res) => {
  try {
    const { email, name } = req.body;

    const customer = await stripe.customers.create({
      email: email || req.user.email,
      name: name || req.user.name,
      metadata: {
        userId: req.user.uid
      }
    });

    res.json({
      customerId: customer.id
    });

  } catch (error) {
    console.error('Create customer error:', error);
    res.status(500).json({
      error: error.message || 'Failed to create customer'
    });
  }
});

// Get customer payment methods
router.get('/customer/:customerId/payment-methods', authMiddleware, async (req, res) => {
  try {
    const { customerId } = req.params;

    const paymentMethods = await stripe.paymentMethods.list({
      customer: customerId,
      type: 'card',
    });

    res.json({
      paymentMethods: paymentMethods.data.map(pm => ({
        id: pm.id,
        card: {
          brand: pm.card.brand,
          last4: pm.card.last4,
          expMonth: pm.card.exp_month,
          expYear: pm.card.exp_year,
        },
        created: pm.created
      }))
    });

  } catch (error) {
    console.error('Get payment methods error:', error);
    res.status(500).json({
      error: error.message || 'Failed to retrieve payment methods'
    });
  }
});

module.exports = router;