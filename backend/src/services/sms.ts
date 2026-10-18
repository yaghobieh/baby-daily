/**
 * Real SMS Gateway Service (Twilio / Custom Gateway)
 *
 * To send real cellular SMS to physical mobile devices:
 * Provide TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN, and TWILIO_PHONE_NUMBER in backend/.env.
 * If credentials are not set, it returns clear status and logs the message.
 */

export interface SmsSendResult {
  sent: boolean;
  provider: 'twilio' | 'simulated';
  error?: string;
  to: string;
}

export async function sendRealSms(rawPhone: string, message: string): Promise<SmsSendResult> {
  const accountSid = process.env.TWILIO_ACCOUNT_SID;
  const authToken = process.env.TWILIO_AUTH_TOKEN;
  const fromNumber = process.env.TWILIO_PHONE_NUMBER;

  // Format to E.164 (e.g. 0544481412 -> +972544481412)
  let e164 = rawPhone.trim().replace(/[^\d+]/g, '');
  if (e164.startsWith('0')) {
    e164 = `+972${e164.substring(1)}`;
  } else if (!e164.startsWith('+')) {
    e164 = `+${e164}`;
  }

  if (accountSid && authToken && fromNumber) {
    try {
      const url = `https://api.twilio.com/2010-04-01/Accounts/${accountSid}/Messages.json`;
      const bodyParams = new URLSearchParams({
        To: e164,
        From: fromNumber,
        Body: message,
      });

      const res = await fetch(url, {
        method: 'POST',
        headers: {
          'Authorization': `Basic ${Buffer.from(`${accountSid}:${authToken}`).toString('base64')}`,
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: bodyParams.toString(),
      });

      const data = (await res.json()) as Record<string, any>;
      if (res.ok) {
        console.log(`[REAL CELLULAR SMS DELIVERED via Twilio] To: ${e164}, SID: ${data.sid}`);
        return { sent: true, provider: 'twilio', to: e164 };
      } else {
        console.error(`[Twilio SMS error]: ${data.message || res.statusText}`);
        return { sent: false, provider: 'twilio', error: data.message || res.statusText, to: e164 };
      }
    } catch (err) {
      console.error('[Twilio network error]:', err);
      return { sent: false, provider: 'twilio', error: (err as Error).message, to: e164 };
    }
  }

  // Gateway not configured in .env -> Simulated
  console.log(`[SIMULATED SMS - No Gateway Credentials in .env] To: ${e164}, Message: "${message}"`);
  return {
    sent: false,
    provider: 'simulated',
    error: 'No cellular SMS gateway credentials found in backend/.env (set TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN, TWILIO_PHONE_NUMBER for telecom SIM delivery)',
    to: e164,
  };
}
