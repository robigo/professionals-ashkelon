// Supabase Edge Function: sends an admin email for new leads and pro applications.
// Required secrets: RESEND_API_KEY, WEBHOOK_SECRET, NOTIFICATION_EMAIL, RESEND_FROM_EMAIL.

type WebhookPayload = {
  table?: string;
  record?: Record<string, unknown>;
};

const requiredSecret = Deno.env.get('WEBHOOK_SECRET');
const resendKey = Deno.env.get('RESEND_API_KEY');
const recipient = Deno.env.get('NOTIFICATION_EMAIL');
const sender = Deno.env.get('RESEND_FROM_EMAIL');

const text = (value: unknown) => String(value ?? '').replace(/[<>]/g, '');

Deno.serve(async (request) => {
  if (request.method !== 'POST') return new Response('Method not allowed', { status: 405 });
  if (!requiredSecret || request.headers.get('x-webhook-secret') !== requiredSecret) {
    return new Response('Unauthorized', { status: 401 });
  }
  if (!resendKey || !recipient || !sender) return new Response('Email service is not configured', { status: 500 });

  const payload = await request.json() as WebhookPayload;
  const row = payload.record ?? {};
  const isApplication = payload.table === 'professional_applications';
  const subject = isApplication ? 'בעל מקצוע חדש ממתין לאישור' : 'ליד חדש במקצוענים בישראל';
  const title = isApplication ? 'בקשת הצטרפות חדשה' : 'בקשת שירות חדשה';
  const details = isApplication
    ? `שם: ${text(row.full_name)}\nמקצוע: ${text(row.service)}\nאזור ועיר: ${text(row.region)} · ${text(row.city)}\nטלפון: ${text(row.phone)}\nניסיון: ${text(row.experience)}`
    : `לקוח: ${text(row.customer_name)}\nשירות: ${text(row.service)}\nאזור ועיר: ${text(row.region)} · ${text(row.city)}\nטלפון: ${text(row.phone)}\nתיאור: ${text(row.description)}`;

  const response = await fetch('https://api.resend.com/emails', {
    method: 'POST',
    headers: { Authorization: `Bearer ${resendKey}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({ from: sender, to: [recipient], subject, text: `${title}\n\n${details}` }),
  });
  if (!response.ok) return new Response(await response.text(), { status: 502 });
  return Response.json({ ok: true });
});
