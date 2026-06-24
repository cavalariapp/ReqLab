// ReqLab — Edge Function: o orientador cria um login de orientado (pelo app).
// A chave de administrador (service_role) fica SÓ aqui no servidor, nunca no app.
// Deploy: painel do Supabase → Edge Functions → Deploy a new function →
//   nome "criar-orientado" → cole este arquivo → Deploy.
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};
const json = (status: number, body: unknown) =>
  new Response(JSON.stringify(body), { status, headers: { ...cors, "Content-Type": "application/json" } });

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  try {
    const url = Deno.env.get("SUPABASE_URL")!;
    const anon = Deno.env.get("SUPABASE_ANON_KEY")!;
    const service = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const authHeader = req.headers.get("Authorization") || "";

    // quem está chamando?
    const asUser = createClient(url, anon, { global: { headers: { Authorization: authHeader } } });
    const { data: { user } } = await asUser.auth.getUser();
    if (!user) return json(401, { error: "Não autenticado." });

    const admin = createClient(url, service);
    const { data: perfil } = await admin.from("reqlab_perfis").select("papel").eq("user_id", user.id).single();
    if (!perfil || perfil.papel !== "orientador") return json(403, { error: "Apenas o orientador pode criar usuários." });

    const { email, password, nome } = await req.json();
    if (!email || !password) return json(400, { error: "Informe e-mail e senha." });
    if (String(password).length < 6) return json(400, { error: "A senha precisa ter ao menos 6 caracteres." });

    const { data: created, error } = await admin.auth.admin.createUser({
      email, password, email_confirm: true, user_metadata: { name: nome || email },
    });
    if (error) return json(400, { error: error.message });

    await admin.from("reqlab_perfis").upsert({ user_id: created.user.id, nome: nome || email, papel: "orientado" });
    return json(200, { ok: true, id: created.user.id });
  } catch (e) {
    return json(500, { error: String((e as Error)?.message || e) });
  }
});
