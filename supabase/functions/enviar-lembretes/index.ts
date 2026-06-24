// ReqLab — Edge Function: envia push das tarefas pendentes (hoje/atrasadas).
// Chamada 1x/dia pelo agendador (pg_cron) — ver sql/011_cron_lembretes.sql.
// Deploy: painel do Supabase → Edge Functions → Deploy a new function →
//   nome "enviar-lembretes" → cole este arquivo → Deploy.
// Secrets necessários (Edge Functions → Manage secrets):
//   VAPID_PUBLIC, VAPID_PRIVATE  (a chave privada NUNCA vai no app)
import webpush from "npm:web-push@3.6.7";
import { createClient } from "npm:@supabase/supabase-js@2";

const cors = { "Access-Control-Allow-Origin": "*", "Access-Control-Allow-Headers": "authorization, apikey, content-type" };

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  try {
    const url = Deno.env.get("SUPABASE_URL")!;
    const service = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const pub = Deno.env.get("VAPID_PUBLIC")!;
    const priv = Deno.env.get("VAPID_PRIVATE")!;
    webpush.setVapidDetails("mailto:epona.perinatologia@gmail.com", pub, priv);

    const admin = createClient(url, service);
    const hoje = new Date().toISOString().slice(0, 10);

    // tarefas pendentes com data <= hoje (hoje ou atrasadas)
    const { data: tarefas, error } = await admin
      .from("reqlab_tarefas")
      .select("owner, titulo, data")
      .eq("status", "pendente")
      .not("data", "is", null)
      .lte("data", hoje);
    if (error) throw error;

    const porDono: Record<string, { titulo: string; data: string }[]> = {};
    (tarefas || []).forEach((t: any) => { if (t.owner) (porDono[t.owner] = porDono[t.owner] || []).push(t); });

    let enviados = 0;
    for (const owner of Object.keys(porDono)) {
      const { data: subs } = await admin.from("reqlab_push_subs").select("subscription, endpoint").eq("user_id", owner);
      const n = porDono[owner].length;
      const atrasadas = porDono[owner].filter((t) => t.data < hoje).length;
      const payload = JSON.stringify({
        title: "ReqLab — tarefas pendentes",
        body: `${n} tarefa(s) para hoje${atrasadas ? ` · ${atrasadas} atrasada(s)` : ""}.`,
      });
      for (const s of (subs || [])) {
        try { await webpush.sendNotification((s as any).subscription, payload); enviados++; }
        catch (e: any) {
          const code = e?.statusCode;
          if (code === 404 || code === 410) await admin.from("reqlab_push_subs").delete().eq("endpoint", (s as any).endpoint);
        }
      }
    }
    return new Response(JSON.stringify({ ok: true, enviados }), { headers: { ...cors, "Content-Type": "application/json" } });
  } catch (e) {
    return new Response(JSON.stringify({ error: String((e as Error)?.message || e) }), { status: 500, headers: { ...cors, "Content-Type": "application/json" } });
  }
});
