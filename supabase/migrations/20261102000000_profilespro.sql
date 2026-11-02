create table if not exists public.profilespro (
  id uuid not null,
  full_name text not null,
  phone text not null,
  address text null,
  created_at timestamp with time zone null default now(),
  constraint profiles_pkey primary key (id),
  constraint profiles_phone_key unique (phone),
  constraint profiles_id_fkey foreign key (id)
    references auth.users (id) on delete cascade
);

alter table public.savemeal_profiles
  alter column email drop not null;

alter table public.profilespro enable row level security;

revoke all on public.profilespro from anon, authenticated;
grant select on public.profilespro to authenticated;

drop policy if exists profilespro_read_self on public.profilespro;
create policy profilespro_read_self
  on public.profilespro
  for select
  to authenticated
  using ((select auth.uid()) = id);

create or replace function public.profilespro_create_auth_profile()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  profile_name text;
  profile_phone text;
begin
  profile_name := nullif(pg_catalog.btrim(new.raw_user_meta_data ->> 'full_name'), '');
  profile_phone := coalesce(
    nullif(pg_catalog.btrim(new.phone), ''),
    nullif(pg_catalog.btrim(new.raw_user_meta_data ->> 'phone'), '')
  );

  if profile_name is null or profile_phone is null then
    return new;
  end if;

  insert into public.profilespro (id, full_name, phone, address)
  values (
    new.id,
    profile_name,
    profile_phone,
    nullif(pg_catalog.btrim(new.raw_user_meta_data ->> 'address'), '')
  )
  on conflict (id) do update
    set full_name = excluded.full_name,
        phone = excluded.phone,
        address = excluded.address;

  return new;
end;
$$;

revoke all on function public.profilespro_create_auth_profile()
  from public, anon, authenticated;

drop trigger if exists profilespro_auth_user_created on auth.users;
create trigger profilespro_auth_user_created
  after insert on auth.users
  for each row execute function public.profilespro_create_auth_profile();
