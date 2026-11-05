create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  role text not null default 'customer' check (role in ('customer', 'admin'))
);

alter table public.profiles enable row level security;
revoke all on table public.profiles from anon, authenticated;
grant select on public.profiles to authenticated;

drop policy if exists "Users can read own profile" on public.profiles;
create policy "Users can read own profile"
  on public.profiles for select to authenticated
  using (id = auth.uid());

create or replace function public.handle_new_user_profile()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, role)
  values (
    new.id,
    case when new.raw_app_meta_data ->> 'role' = 'admin'
      then 'admin' else 'customer' end
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created_profile on auth.users;
create trigger on_auth_user_created_profile
  after insert on auth.users
  for each row execute function public.handle_new_user_profile();

insert into public.profiles (id, role)
select id,
  case when raw_app_meta_data ->> 'role' = 'admin'
    then 'admin' else 'customer' end
from auth.users
on conflict (id) do nothing;

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'admin'
  );
$$;

revoke all on function public.is_admin() from public, anon;
grant execute on function public.is_admin() to authenticated;

create table if not exists public.products (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  house text not null,
  price integer not null check (price > 0),
  family text not null check (family in ('Floral', 'Woody', 'Fresh', 'Amber')),
  image text not null,
  tint text not null default 'FFE6DFD2' check (tint ~ '^[0-9A-Fa-f]{8}$'),
  description text not null,
  notes text[] not null default '{}',
  longevity text not null,
  label text
);

alter table public.products enable row level security;

grant select, insert, update, delete on public.products to authenticated;

-- Remove older broad mutation policies first. RLS combines permissive policies
-- with OR, so a leftover policy could otherwise bypass the admin checks.
do $$
declare
  existing_policy record;
begin
  for existing_policy in
    select policyname
    from pg_policies
    where schemaname = 'public'
      and tablename = 'products'
      and cmd in ('INSERT', 'UPDATE', 'DELETE', 'ALL')
  loop
    execute format(
      'drop policy %I on public.products', existing_policy.policyname
    );
  end loop;
end
$$;

drop policy if exists "Authenticated users can view products" on public.products;
create policy "Authenticated users can view products"
  on public.products for select to authenticated
  using (true);

drop policy if exists "Admins can add products" on public.products;
create policy "Admins can add products"
  on public.products for insert to authenticated
  with check (public.is_admin());

drop policy if exists "Admins can update products" on public.products;
create policy "Admins can update products"
  on public.products for update to authenticated
  using (public.is_admin())
  with check (public.is_admin());

drop policy if exists "Admins can remove products" on public.products;
create policy "Admins can remove products"
  on public.products for delete to authenticated
  using (public.is_admin());

insert into public.products
  (name, house, price, family, image, tint, description, notes, longevity, label)
values
  ('Santal 33', 'LE LABO', 9500, 'Woody', 'photo-1594035910387-fea47794261f', 'FFD5C9B7', 'A smoky, leathery blend that feels like open air and warm skin.', array['Cardamom', 'Australian sandalwood', 'Leather'], '8+ hours', 'BESTSELLER'),
  ('Rose of No Man’s Land', 'BYREDO', 9000, 'Floral', 'photo-1541643600914-78b084683601', 'FFE6D7D1', 'A tender tribute to the quiet strength of the Damask rose.', array['Pink pepper', 'Turkish rose', 'White amber'], '6–8 hours', null),
  ('Wood Sage & Sea Salt', 'JO MALONE LONDON', 6200, 'Fresh', 'photo-1592945403244-b3fbafd7f539', 'FFD8DED8', 'A windswept escape, alive with mineral freshness and soft woods.', array['Ambrette seeds', 'Sea salt', 'Sage'], '4–6 hours', 'NEW ARRIVAL'),
  ('Mojave Ghost', 'BYREDO', 8800, 'Fresh', 'photo-1615634260167-c8cdede054de', 'FFE1DCD1', 'A luminous, soft-woody scent inspired by the desert in bloom.', array['Nesberry', 'Magnolia', 'Cedarwood'], '6–8 hours', null),
  ('Vanilla Powder', 'MATIÈRE PREMIÈRE', 8500, 'Amber', 'photo-1595425970377-c9703cf48b6d', 'FFE6DFD2', 'A modern, soft-focus vanilla wrapped in creamy palo santo.', array['Almond', 'Vanilla', 'Palo santo'], '8+ hours', 'EDITOR’S PICK'),
  ('Libre', 'YVES SAINT LAURENT', 6500, 'Floral', 'photo-1587017539504-67cfbddac569', 'FFE7D9C7', 'A bold meeting of lavender and orange blossom, made for a free spirit.', array['Mandarin', 'Orange blossom', 'Madagascar vanilla'], '8+ hours', 'ICONIC'),
  ('Black Orchid', 'TOM FORD', 7800, 'Amber', 'photo-1592945403244-b3fbafd7f539', 'FFD2C6B9', 'A dark, sensual blend of black orchid and rich, warm accords.', array['Black truffle', 'Black orchid', 'Patchouli'], '10+ hours', null),
  ('Gypsy Water', 'BYREDO', 8700, 'Woody', 'photo-1615634260167-c8cdede054de', 'FFD9D4C8', 'A dreamy woodland trail of fresh pine, soft smoke, and vanilla.', array['Bergamot', 'Pine needles', 'Vanilla'], '6–8 hours', null),
  ('English Pear & Freesia', 'JO MALONE LONDON', 5800, 'Floral', 'photo-1541643600914-78b084683601', 'FFE4DED2', 'The crisp sweetness of ripe pear softened by white freesia.', array['King William pear', 'Freesia', 'Patchouli'], '4–6 hours', null),
  ('Neroli Portofino', 'TOM FORD', 10000, 'Fresh', 'photo-1594035910387-fea47794261f', 'FFD8E0DA', 'A sparkling Mediterranean escape with citrus and luminous neroli.', array['Italian bergamot', 'Neroli', 'Amber'], '4–6 hours', 'CITRUS FAVORITE'),
  ('Chance Eau Tendre', 'CHANEL', 6800, 'Floral', 'photo-1596462502278-27bfdc403348', 'FFE8D9D7', 'A delicate, joyful floral-fruity trail with a soft, luminous finish.', array['Grapefruit', 'Jasmine', 'White musk'], '6–8 hours', 'SOFT FLORAL'),
  ('L’Interdit', 'GIVENCHY', 6900, 'Floral', 'photo-1585386959984-a4155224a1ad', 'FFE1D4C8', 'White florals meet a daring, dark accord for an elegant contrast.', array['Orange blossom', 'Tuberose', 'Vetiver'], '8+ hours', null),
  ('My Way', 'GIORGIO ARMANI', 6400, 'Floral', 'photo-1608571423902-eed4a5ad8108', 'FFE6D9D5', 'A bright bouquet of white flowers with a warm, embracing base.', array['Bergamot', 'Tuberose', 'Vanilla'], '8+ hours', 'FLORAL FAVORITE'),
  ('Dylan Blue', 'VERSACE', 5000, 'Fresh', 'photo-1616949755610-8c9bbc08f138', 'FFD4DFE1', 'A crisp, modern composition with fresh citrus and aromatic woods.', array['Bergamot', 'Black pepper', 'Musk'], '6–8 hours', null),
  ('Aqua Allegoria Mandarine Basilic', 'GUERLAIN', 6100, 'Fresh', 'photo-1563170351-be82bc888aa4', 'FFE8DFCC', 'Juicy mandarin and aromatic basil evoke a sunlit garden in summer.', array['Mandarin', 'Basil', 'Green tea'], '4–6 hours', 'CITRUS & FRESH')
on conflict (name) do nothing;
