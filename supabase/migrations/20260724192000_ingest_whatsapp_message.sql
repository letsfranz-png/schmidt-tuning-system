-- Atomic ingestion of one inbound WhatsApp message
-- Idempotent by Meta external_message_id

create or replace function public.ingest_whatsapp_message(
  p_external_message_id text,
  p_phone_e164 text,
  p_whatsapp_wa_id text,
  p_customer_name text,
  p_message_type text,
  p_body text,
  p_message_timestamp text,
  p_raw_payload jsonb
)
returns table (
  customer_id uuid,
  conversation_id uuid,
  message_id uuid,
  message_created boolean
)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_customer_id uuid;
  v_conversation_id uuid;
  v_message_id uuid;
  v_created boolean := false;
  v_timestamp timestamptz;
begin
  if p_whatsapp_wa_id is null or btrim(p_whatsapp_wa_id) = '' then
    raise exception 'whatsapp_wa_id is required';
  end if;

  if p_external_message_id is null or btrim(p_external_message_id) = '' then
    raise exception 'external_message_id is required';
  end if;

  begin
    v_timestamp := to_timestamp(nullif(p_message_timestamp, '')::double precision);
  exception when others then
    v_timestamp := now();
  end;

  insert into public.customers (
    whatsapp_wa_id,
    phone_e164,
    display_name,
    source
  )
  values (
    p_whatsapp_wa_id,
    nullif(p_phone_e164, ''),
    nullif(p_customer_name, ''),
    'whatsapp'
  )
  on conflict (whatsapp_wa_id)
  do update set
    phone_e164 = coalesce(excluded.phone_e164, public.customers.phone_e164),
    display_name = coalesce(excluded.display_name, public.customers.display_name),
    updated_at = now()
  returning id into v_customer_id;

  select c.id
  into v_conversation_id
  from public.conversations c
  where c.customer_id = v_customer_id
    and c.channel = 'whatsapp'
    and c.status <> 'closed'
  order by c.last_message_at desc nulls last, c.created_at desc
  limit 1;

  if v_conversation_id is null then
    insert into public.conversations (
      customer_id,
      channel,
      status,
      last_message_at
    )
    values (
      v_customer_id,
      'whatsapp',
      'open',
      v_timestamp
    )
    returning id into v_conversation_id;
  else
    update public.conversations
    set last_message_at = greatest(
      coalesce(last_message_at, v_timestamp),
      v_timestamp
    )
    where id = v_conversation_id;
  end if;

  insert into public.messages (
    conversation_id,
    customer_id,
    external_message_id,
    direction,
    message_type,
    body,
    message_timestamp,
    raw_payload
  )
  values (
    v_conversation_id,
    v_customer_id,
    p_external_message_id,
    'inbound',
    coalesce(nullif(p_message_type, ''), 'unknown'),
    p_body,
    v_timestamp,
    coalesce(p_raw_payload, '{}'::jsonb)
  )
  on conflict (external_message_id) do nothing
  returning id into v_message_id;

  if v_message_id is null then
    select m.id
    into v_message_id
    from public.messages m
    where m.external_message_id = p_external_message_id;
  else
    v_created := true;
  end if;

  return query
  select v_customer_id, v_conversation_id, v_message_id, v_created;
end;
$$;

revoke all on function public.ingest_whatsapp_message(
  text, text, text, text, text, text, text, jsonb
) from public, anon, authenticated;

grant execute on function public.ingest_whatsapp_message(
  text, text, text, text, text, text, text, jsonb
) to service_role;

comment on function public.ingest_whatsapp_message(
  text, text, text, text, text, text, text, jsonb
) is 'Atomically upserts customer and conversation, then idempotently stores one inbound WhatsApp message';
