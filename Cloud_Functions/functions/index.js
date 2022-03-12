const functions = require('firebase-functions');
const admin = require('firebase-admin');
const stripe = require('stripe')(functions.config().stripe.secret);

admin.initializeApp({ projectId: 'harvest-app-a6e48' });
const db = admin.firestore();
const FieldValue = admin.firestore.FieldValue;

/**
 * When a customer is inserted, generate stripe_customer_id
 * and stripe_setup_secret
 */
exports.createStripeCustomer = functions.firestore
    .document('customers/{userId}')
    .onCreate(async (snap, context) => {
      try {
        // Create customer and setup intent
        const customer = await stripe.customers.create({ email: snap.data().email });
        const intent = await stripe.setupIntents.create({
          customer: customer.id,
        });
        // Update document
        await snap.ref.set({
          stripe_customer_id: customer.id,
          stripe_setup_secret: intent.client_secret,
        }, { merge: true });
        return;
      } catch (error) {
        await snap.ref.set({ error: userFacingMessage(error) }, { merge: true });
        console.log(context.params.userId, error);
        return;
      }
    });

/**
 * When adding the payment method ID on the client,
 * this function is triggered to retrieve the payment method details.
 */
exports.addPaymentMethodDetails = functions.firestore
    .document('customers/{userId}/payment_methods/{pushId}')
    .onCreate(async (snap, context) => {
      try {
        // Add detail to payment method
        const paymentMethodId = snap.data().id;
        const paymentMethod = await stripe.paymentMethods.retrieve(
            paymentMethodId,
        );
        functions.logger.info(`PaymentMethod create: ${paymentMethod}`);
        await snap.ref.set(paymentMethod);
        // Set current is_default to true and change other to false
        await snap.ref.update({ is_default: true });
        const allPaymentMethods = await snap.ref.parent.get();
        allPaymentMethods.forEach(async (doc) => {
          if (doc.id != context.params.pushId && doc.data().is_default == true) {
            await snap.ref.parent.doc(doc.id).update({ is_default: false });
          }
        });
        // Create a new setup intent
        const intent = await stripe.setupIntents.create({
          customer: paymentMethod.customer,
        });
        // Update customer document
        await snap.ref.parent.parent.set(
            {
              stripe_setup_secret: intent.client_secret,
            },
            { merge: true },
        );
        return;
      } catch (error) {
        await snap.ref.set({ error: userFacingMessage(error) }, { merge: true });
        functions.logger.error(context.params.userId, error);
        return;
      }
    });

/**
 * When a payment method is deleted, update the default payment methods
 */
exports.deletePaymentMethod = functions.firestore
    .document('customers/{userId}/payment_methods/{pushId}')
    .onDelete(async (snap, context) => {
      const deletedValue = snap.data();
      try {
        // Checks whether current payment method is default
        if (deletedValue.is_default == true) {
          // Choose a new default payment method
          const allPaymentMethods = await snap.ref.parent.limit(1).get();
          allPaymentMethods.forEach(async (doc) => {
            // Will only be executed once
            await snap.ref.parent.doc(doc.id).update({ is_default: true });
          });
        }
        // Detach payment method from stripe customer
        await stripe.paymentMethods.detach(deletedValue.id);
        return;
      } catch (error) {
        functions.logger.error(uid, error);
        return;
      }
    });

/**
 * When a new order is created, create a stripe payment
 */
exports.createStripePayment = functions.firestore
    .document('orders/{orderId}')
    .onCreate(async (snap, context) => {
      // Get customer info
      const uid = snap.data().customer;
      const orderId = context.params.orderId;
      const userRef = db.collection('customers').doc(uid);
      try {
        // Get stripe customer and stripe payment method
        const stripeCustomerId = (await userRef.get()).data().stripe_customer_id;
        const paymentMethodSnap = await userRef.collection('payment_methods').where('is_default', '==', true).limit(1).get();
        if (paymentMethodSnap.size == 0) {
          // No payment methods available
          functions.logger.error('Creating a payment without payment methods attached.');
          return;
        }
        const stripePaymentMethodId = paymentMethodSnap.docs[0].id;
        // TODO: Calculate payment details
        let amount = 0;
        snap.data().farm_total_cost.forEach(farm => {
          amount += formatAmountForStripe(farm.cost);
        });
        // Use idempotency key to protect against double chargess
        const idempotencyKey = orderId;
        const payment = await stripe.paymentIntents.create({
          amount: amount,
          currency: 'usd',
          customer: stripeCustomerId,
          confirm: true,
          off_session: false,
          payment_method: stripePaymentMethodId,
          confirmation_method: 'manual',
          transfer_group: orderId,
        }, { idempotencyKey });
        // If successful, write to customer's payment collection
        await userRef.collection('payments').add({
          order_id: orderId,
          transfer_group: orderId,
          payment,
        });
        return;
      } catch (error) {
        functions.logger.error(uid, error);
        await snap.ref.set({ error: userFacingMessage(error) }, { merge: true });
        await userRef.collection('payments').add({
          order_id: orderId,
          error: userFacingMessage(error),
        });
        return;
      }
    });

/**
 * When 3D Secure is performed, reconfirm the payment after authentication
 */
exports.confirmStripePayment = functions.firestore
    .document('customers/{userId}/payments/{paymentId}')
    .onUpdate(async (change, context) => {
      if (change.after.data().payment.status === 'requires_confirmation') {
        const payment = await stripe.paymentIntents.confirm(
          change.after.data().payment.id
        );
        change.after.ref.update({ payment: payment });
      }
    });

/**
 * Create Stripe Connect account and generate account link.
 * Returns the account onboarding url.
 */
exports.retrieveStripeOnboardingLink = functions.https.onCall(async (data, context) => {
  // Check if authenticated
  if (!context.auth) {
    throw new functions.https.HttpsError('failed-precondition', 'The function must be called ' +
        'while authenticated.');
  }
  const uid = context.auth.uid;
  const doc = await db.collection('farms').doc(uid).get();
  // Validate database info
  if (!doc.exists) {
    throw new functions.https.HttpsError('failed-precondition', 'The function must be called ' +
        'with a farm document.');
  } else if (doc.data().stripe_account_id != null) {
    throw new functions.https.HttpsError('failed-precondition', 'The account already exists.');
  }
  const email = context.auth.token.email;
  const redirectUrl = 'https://us-central1-harvest-app-a6e48.cloudfunctions.net/checkAccountDetail';
  try {
    const account = await stripe.accounts.create({
      type: 'express',
      country: 'US',
      email: email,
      metadata: {
        uid: uid,
      },
    });
    const accountLink = await stripe.accountLinks.create({
      account: account.id,
      refresh_url: redirectUrl,
      return_url: redirectUrl,
      type: 'account_onboarding',
    });
    return { url: accountLink.url };
  } catch (error) {
    throw new functions.https.HttpsError('account-creation-failed', 'Failed to create account.');
  }
});

/**
 * Check detail of the new connect account after redirected from Stripe.
 * Redirect to custom URL scheme of the app.
 */
exports.checkAccountDetail = functions.https.onRequest((req, res) => {
  res.send('<p>Please return to app for further setup.</p>');  // TODO: need more detail
});

/**
 * Handle Connect webhooks.
 */
exports.handleStripeConnectWebhooks = functions.https.onRequest(async (req, res) => {
  const sig = req.headers['stripe-signature'];
  const endpointSecret = functions.config().stripe.connect_endpoint_secret;
  // Construct the event
  let event;
  try {
    event = stripe.webhooks.constructEvent(req.rawBody, sig, endpointSecret);
  } catch (err) {
    functions.logger.error(err);
    return res.status(400).end();
  }
  // Handle the event
  switch (event.type) {
    case 'account.updated':
      functions.logger.info('Received account.updated');
      await handleAccountUpdated(event);
      break;
    default:
      functions.logger.warn(`Unhandled event type ${event.type}`);
  }
  res.status(200).end();
});

/**
 * Handle account.updated webhook event.
 */
async function handleAccountUpdated(event) {
  const stripeAccountId = event.account;
  const account = event.data.object;
  const uid = account.metadata.uid;
  const docRef = db.collection('farms').doc(uid);
  functions.logger.info(`Checking detail of account ${stripeAccountId} and uid ${uid}.`);
  // Check if account details are submitted
  if (account.details_submitted) {
    // Save account to database and remove error
    await docRef.update({
      stripe_account_id: stripeAccountId,
      stripe_onboarding_error: FieldValue.delete(),
    });
  } else {
    // Set error
    await docRef.update({
      // stripe_account_id: FieldValue.delete(),
      stripe_onboarding_error: 'Details not submitted.',
    });
  }
}

/**
 * Whenever a delivery session is created, retrieve all orders and add to subcollection
 */
exports.addDeliverySessionDetails = functions.firestore
    .document('drivers/{driverId}/delivery_sessions/{sessionId}')
    .onCreate(async (snap, context) => {
      try {
        // Loop through 'order_ids' and add all to subcollection 'orders'
        snap.data().order_ids.forEach(async (orderId, i) => {
          const order = (await db.collection('orders').doc(orderId).get()).data();
          const customer = (await db.collection('customers').doc(order.customer).get()).data();
          // Save order and customer info into subcollection
          await snap.ref.collection('orders').doc(orderId).set({
            order: order,
            index: i,
            customer_active_address: customer.active_address,
            customer_first_name: customer.first_name,
            customer_last_name: customer.last_name,
            customer_phone_num: customer.phone_num,
            customer_image_url: customer.image_url,
          });
        });
        // Retrieve market information and update fields
        const marketId = snap.data().market_id;
        const market = (await db.collection('markets').doc(marketId).get()).data();
        await snap.ref.set({
          market_address: market.address,
          market_name: market.name,
        }, { merge: true });
        return;
      } catch (error) {
        functions.logger.error(error);
        return;
      }
    });

/**
 * Sanitize the error message for the user.
 */
function userFacingMessage(error) {
  return error.type ?
    error.message :
    'An error occurred, developers have been alerted';
}

/**
 * Format amount for stripe using cents
 */
function formatAmountForStripe(amount) {
  return Math.round(amount * 100);
}
