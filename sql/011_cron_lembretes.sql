-- =====================================================================
-- ReqLab — agenda o envio diário dos lembretes (push de fundo)
-- Pré-requisitos:
--   1) extensões pg_cron e pg_net ligadas (Dashboard → Database → Extensions)
--   2) função 'enviar-lembretes' publicada (Edge Functions)
--   3) secrets VAPID_PUBLIC e VAPID_PRIVATE configurados na função
-- Rodar no SQL editor do Supabase.
-- =====================================================================

create extension if not exists pg_cron;
create extension if not exists pg_net;

-- remove agendamento anterior (se houver) para não duplicar
do $$
begin
  perform cron.unschedule('reqlab-lembretes');
exception when others then null;
end $$;

-- todo dia às 11:00 UTC (08:00 horário de Brasília)
select cron.schedule('reqlab-lembretes', '0 11 * * *', $cron$
  select net.http_post(
    url := 'https://vbpdvkxoatbpycwppypd.supabase.co/functions/v1/enviar-lembretes',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZicGR2a3hvYXRicHljd3BweXBkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODIyMjk5ODksImV4cCI6MjA5NzgwNTk4OX0.5P0VnRoI6hOGy0gPWQco1BshdYCK7XekIinvWNTsesI'
    ),
    body := '{}'::jsonb
  );
$cron$);

-- conferência: deve listar o job
select jobname, schedule from cron.job where jobname = 'reqlab-lembretes';
