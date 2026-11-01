export default async function handler(req, res) {
  // CORS Headers
  res.setHeader('Access-Control-Allow-Credentials', true);
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET,OPTIONS,PATCH,DELETE,POST,PUT');
  res.setHeader('Access-Control-Allow-Headers', 'X-CSRF-Token, X-Requested-With, Accept, Accept-Version, Content-Length, Content-MD5, Content-Type, Date, X-Api-Version');

  if (req.method === 'OPTIONS') { res.status(200).end(); return; }
  if (req.method !== 'POST') { return res.status(405).json({ error: 'Method not allowed' }); }

  try {
    const { to, subject, html, client_email, tracking_number, status, htmlBody } = req.body;
    const recipient    = to || client_email;
    const emailSubject = subject || `Shipment Update: ${tracking_number} — ${status}`;
    const emailHtml    = html || htmlBody;

    if (!recipient || !emailHtml) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    // Brevo (Sendinblue) API — reliable, no domain verification issues
    const BREVO_API_KEY = process.env.BREVO_API_KEY || "PASTE_BREVO_KEY_HERE";

    const response = await fetch("https://api.brevo.com/v3/smtp/email", {
      method: "POST",
      headers: {
        "api-key": BREVO_API_KEY,
        "Content-Type": "application/json"
      },
      body: JSON.stringify({
        sender: { name: "OntracShippingCompany", email: "info@ontracshippingcompany.com" },
        to: Array.isArray(recipient) ? recipient.map(e => ({ email: e })) : [{ email: recipient }],
        subject: emailSubject,
        htmlContent: emailHtml
      })
    });

    const data = await response.json().catch(() => ({}));

    if (!response.ok) {
      console.error('[MGT] Brevo Error:', data);
      return res.status(response.status).json({ error: data.message || 'Failed to send email', details: data });
    }

    console.log('[MGT] Email sent via Brevo:', data.messageId);
    return res.status(200).json({ success: true, id: data.messageId });

  } catch (error) {
    console.error('[MGT] Server Error:', error);
    return res.status(500).json({ error: 'Internal Server Error', message: error.message });
  }
}
