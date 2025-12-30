const functions = require('firebase-functions');
const admin = require('firebase-admin');
const cors = require('cors')({ origin: true });

// Initialize Firebase Admin
admin.initializeApp();

// Stripe configuration - use environment variable or Firebase config
// To set this, run: firebase functions:config:set stripe.secret="YOUR_STRIPE_SECRET_KEY"
const stripeSecretKey = functions.config().stripe ? functions.config().stripe.secret : process.env.STRIPE_SECRET_KEY;
const stripe = require('stripe')(stripeSecretKey);

/**
 * createPaymentIntent
 * HTTPS function to create a Stripe Payment Intent securely on the server.
 */
exports.createPaymentIntent = functions.https.onRequest((req, res) => {
  return cors(req, res, async () => {
    // Only allow POST requests
    if (req.method !== 'POST') {
      return res.status(405).send({ error: 'Method Not Allowed' });
    }

    // Optional: Verify Firebase ID Token for security
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).send({ error: 'Unauthorized: Missing token' });
    }

    const idToken = authHeader.split('Bearer ')[1];
    try {
      await admin.auth().verifyIdToken(idToken);
    } catch (error) {
      console.error('Error verifying ID token:', error);
      return res.status(401).send({ error: 'Unauthorized: Invalid token' });
    }

    try {
      const { amount, currency } = req.body;

      if (!amount) {
        return res.status(400).send({ error: 'Amount is required' });
      }

      // Create a PaymentIntent with the order amount and currency
      // Amount should be in cents (e.g., $10.00 is 1000)
      const paymentIntent = await stripe.paymentIntents.create({
        amount: parseInt(amount),
        currency: currency || 'usd',
        payment_method_types: ['card'],
        metadata: {
          integration_check: 'accept_a_payment',
        },
      });

      // Send back the clientSecret and paymentIntentId
      res.status(200).send({
        clientSecret: paymentIntent.client_secret,
        paymentIntentId: paymentIntent.id,
      });
    } catch (error) {
      console.error('Stripe Error:', error);
      res.status(500).send({ error: error.message });
    }
  });
});

/**
 * onOrderStatusUpdate
 * Triggers when an order document is updated to notify the user of status changes.
 */
exports.onOrderStatusUpdate = functions.firestore
  .document('orders/{orderId}')
  .onUpdate(async (change, context) => {
    const newData = change.after.data();
    const oldData = change.before.data();

    // If status hasn't changed, do nothing
    if (newData.status === oldData.status) return null;

    const userId = newData.userId;
    const userDoc = await admin.firestore().collection('users').doc(userId).get();

    if (!userDoc.exists) return null;

    const fcmToken = userDoc.data().fcmToken;
    if (!fcmToken) return null;

    const statusMap = {
      'PROCESSING': 'Your order is being processed!',
      'SHIPPED': 'Exciting news! Your order has been shipped.',
      'DELIVERED': 'Your watch has been delivered. Enjoy!',
      'CANCELLED': 'Your order has been cancelled.',
    };

    const message = {
      notification: {
        title: 'Order Status Update',
        body: statusMap[newData.status] || `Your order status is now ${newData.status}`,
      },
      token: fcmToken,
      data: {
        orderId: context.params.orderId,
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
      },
    };

    try {
      await admin.messaging().send(message);
      console.log('Notification sent successfully for order:', context.params.orderId);
    } catch (error) {
      console.error('Error sending notification:', error);
    }
    return null;
  });

/**
 * onNewOrder
 * Triggers when a new order is created to send a confirmation notification.
 */
exports.onNewOrder = functions.firestore
  .document('orders/{orderId}')
  .onCreate(async (snapshot, context) => {
    const orderData = snapshot.data();
    const userId = orderData.userId;

    const userDoc = await admin.firestore().collection('users').doc(userId).get();
    if (!userDoc.exists) return null;

    const fcmToken = userDoc.data().fcmToken;
    if (!fcmToken) return null;

    const message = {
      notification: {
        title: 'Order Confirmed! 🎉',
        body: `Thank you for your purchase! Your order #${context.params.orderId.substring(0, 8)} is confirmed.`,
      },
      token: fcmToken,
      data: {
        orderId: context.params.orderId,
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
      },
    };

    try {
      await admin.messaging().send(message);
      console.log('Confirmation notification sent for order:', context.params.orderId);
    } catch (error) {
      console.error('Error sending confirmation notification:', error);
    }
    return null;
  });
