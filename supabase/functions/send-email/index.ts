// PrimeTrackCargo — Email Edge Function (Brevo)

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }

  try {
    // Brevo API — stable, no domain verification issues
    const BREVO_API_KEY = Deno.env.get("BREVO_API_KEY") || "PASTE_BREVO_KEY_HERE";

    const body = await req.json();
    const { to, subject, html } = body;

    if (!to || !subject || !html) {
      return new Response(
        JSON.stringify({ error: "Missing required fields: to, subject, html" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const recipients = Array.isArray(to) ? to.map(e => ({ email: e })) : [{ email: to }];

    const brevoResponse = await fetch("https://api.brevo.com/v3/smtp/email", {
      method: "POST",
      headers: {
        "api-key": BREVO_API_KEY,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        sender: { name: "PrimeTrackCargo", email: "contact@primetrackcargo.com" },
        to: recipients,
        subject,
        htmlContent: html,
      }),
    });

    const data = await brevoResponse.json().catch(() => ({}));

    if (!brevoResponse.ok) {
      console.error("[MGT] Brevo error:", JSON.stringify(data));
      return new Response(
        JSON.stringify({ error: data?.message || "Brevo API error", details: data }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    console.log("[MGT] Email sent via Brevo:", data.messageId);
    return new Response(
      JSON.stringify({ success: true, id: data.messageId }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );

  } catch (err) {
    console.error("[MGT] Unexpected error:", err);
    return new Response(
      JSON.stringify({ error: String(err) }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
