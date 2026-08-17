# הפעלת התראות מייל

1. ב-Resend ודא דומיין שולח והגדר כתובת שולח, לדוגמה `התראות <alerts@your-domain.co.il>`.
2. ב-Supabase Dashboard פתח **Edge Functions** וצור פונקציה בשם `send-notification`. הדבק את הקוד מ-`functions/send-notification/index.ts` והפעל אותה עם **Verify JWT כבוי**.
3. ב-Edge Functions → Secrets הגדר:
   - `RESEND_API_KEY` — מפתח ה-API של Resend.
   - `NOTIFICATION_EMAIL` — `goshen.r@gmail.com`.
   - `RESEND_FROM_EMAIL` — כתובת השולח המאומתת ב-Resend.
   - `WEBHOOK_SECRET` — ערך אקראי ארוך שתשמור גם בוובהוקים.
4. ב-Database → Webhooks צור שני Webhooks מסוג `INSERT`, אל כתובת:
   `https://umiaegyddytwxdnjscps.supabase.co/functions/v1/send-notification`
   - `new_service_request` על הטבלה `service_requests`
   - `new_professional_application` על הטבלה `professional_applications`
   הוסף Header: `x-webhook-secret` עם הערך של `WEBHOOK_SECRET`.
5. שלח בקשת בדיקה מכל טופס. במייל אמורה להגיע התראה עם פרטי הבקשה.

אין לשמור מפתחות API בקוד, ב-GitHub או בדפדפן.
