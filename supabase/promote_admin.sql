-- Run this in the Supabase SQL Editor as a trusted project administrator.
-- Set exactly one of target_email or target_user_id below; set the other to NULL.
-- Never run admin promotion from the client app.

do $$
declare
  target_email text := null;
  target_user_id uuid := null;
  promoted_user_id uuid;
begin
  if (target_email is not null and target_user_id is not null)
     or (target_email is null and target_user_id is null) then
    raise exception
      'Set exactly one of target_email or target_user_id. Current values: target_email=% target_user_id=%. Example: target_email := ''you@example.com''; or target_user_id := ''<user-uuid>'';',
      target_email,
      target_user_id;
  end if;

  if target_user_id is not null then
    update auth.users
    set raw_app_meta_data =
      coalesce(raw_app_meta_data, '{}'::jsonb) || '{"role":"admin"}'::jsonb
    where id = target_user_id
    returning id into promoted_user_id;
  else
    update auth.users
    set raw_app_meta_data =
      coalesce(raw_app_meta_data, '{}'::jsonb) || '{"role":"admin"}'::jsonb
    where lower(email) = lower(target_email)
    returning id into promoted_user_id;
  end if;

  if promoted_user_id is null then
    raise exception 'No auth user found for email % or user ID %. Update the values near the top of this script and rerun.', target_email, target_user_id;
  end if;

  insert into public.profiles (id, role)
  values (promoted_user_id, 'admin')
  on conflict (id) do update
    set role = 'admin';

  raise notice 'Promoted user % to admin.', promoted_user_id;
end
$$;

-- The user must sign out and sign back in to receive a token with the new role.
