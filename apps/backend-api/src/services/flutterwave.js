/**
 * Flutterwave payment service
 *
 * Integrates with Flutterwave's Standard API for mobile money top-ups
 * (Airtel Money, MTN MoMo) in Zambian Kwacha (ZMW).
 *
 * When FLW_SECRET_KEY is configured, real API calls are made against
 * Flutterwave (sandbox with the test key). When not configured — i.e. in
 * local development / demo environments without provider credentials — the
 * service falls back to a clearly-labelled simulated payment mode so the
 * full top-up → webhook → credit → spend flow remains demonstrable.
 */

const FLW_BASE_URL = process.env.FLW_BASE_URL || 'https://api.flutterwave.com/v3';
const FLW_SECRET_KEY = process.env.FLW_SECRET_KEY || '';

const isLiveMode = () => Boolean(FLW_SECRET_KEY);

/**
 * Initiate a mobile money top-up charge.
 *
 * @param {object} params
 * @param {string} params.txRef        - Unique reference for this charge
 * @param {number} params.amount       - Amount in ZMW
 * @param {string} params.phoneNumber  - Customer mobile money phone number
 * @param {string} params.network      - 'AIRTEL' | 'MTN'
 * @param {string} params.redirectUrl  - Where Flutterwave redirects after payment
 * @returns {Promise<{mode: 'live'|'simulated', status: string, link?: string, processorResponse?: string}>}
 */
async function initiateMobileMoneyCharge({ txRef, amount, phoneNumber, network, redirectUrl }) {
  if (!isLiveMode()) {
    // ── Simulated mode (no provider credentials configured) ──
    return {
      mode: 'simulated',
      status: 'pending',
      processorResponse: 'Simulated charge created (no FLW_SECRET_KEY configured)',
    };
  }

  const payload = {
    tx_ref: txRef,
    amount,
    currency: 'ZMW',
    network: (network || 'AIRTEL').toUpperCase(),
    email: 'customer@smartbudgetzm.com',
    phone_number: phoneNumber,
    redirect_url: redirectUrl,
  };

  const response = await fetch(`${FLW_BASE_URL}/charges?type=mobile_money_zambia`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${FLW_SECRET_KEY}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(payload),
  });

  const data = await response.json().catch(() => ({}));

  if (!response.ok || (data.status && data.status !== 'success')) {
    const err = new Error(data.message || 'Flutterwave charge initiation failed');
    err.statusCode = 502;
    err.code = 'PAYMENT_PROVIDER_ERROR';
    throw err;
  }

  return {
    mode: 'live',
    status: data.data?.status || 'pending',
    link: data.data?.link || null,
    processorResponse: data.data?.processor_response || null,
  };
}

/**
 * Verify a transaction with Flutterwave by transaction id.
 * Only used in live mode; the webhook already carries verified status.
 */
async function verifyTransaction(transactionId) {
  if (!isLiveMode()) {
    return { mode: 'simulated', verified: true, status: 'successful' };
  }

  const response = await fetch(`${FLW_BASE_URL}/transactions/${transactionId}/verify`, {
    headers: { Authorization: `Bearer ${FLW_SECRET_KEY}` },
  });
  const data = await response.json().catch(() => ({}));

  return {
    mode: 'live',
    verified: data.status === 'success' && data.data?.status === 'successful',
    status: data.data?.status || 'unknown',
    amount: data.data?.amount,
    currency: data.data?.currency,
    txRef: data.data?.tx_ref,
  };
}

module.exports = {
  isLiveMode,
  initiateMobileMoneyCharge,
  verifyTransaction,
};
