-- ╔══════════════════════════════════════════════════════════════════╗
-- ║  Panha Brick Factory — Supabase Schema                          ║
-- ║  Run this in Supabase SQL Editor to set up all tables.          ║
-- ╚══════════════════════════════════════════════════════════════════╝

-- Enable UUID extension
create extension if not exists "uuid-ossp";

-- ── Settings (one global row) ──────────────────────────────────────────────
create table if not exists settings (
  id text primary key default 'global',
  "companyName" text default 'Panha Brick Factory',
  "companyNameKh" text default 'រោងចក្រឥដ្ឋផ្នហា',
  address text default '',
  "addressKh" text default '',
  phone text default '',
  email text default '',
  "brickPriceDefault" numeric default 0.10,
  "carCapacity" integer default 30000,
  currency text default 'USD',
  "currencySymbol" text default '$',
  "nextInvoiceNum" integer default 1
);

-- ── Brick Types ────────────────────────────────────────────────────────────
create table if not exists brick_types (
  id uuid primary key default uuid_generate_v4(),
  name text not null,
  name_kh text default '',
  description text default '',
  created_at timestamptz default now()
);

alter table brick_types enable row level security;
create policy "Allow all for anon" on brick_types for all to anon using (true) with check (true);

-- seed defaults (idempotent)
insert into brick_types (id, name, name_kh) values
  ('00000000-0000-0000-0000-000000000001', 'Normal', 'ឥដ្ឋធម្មតា'),
  ('00000000-0000-0000-0000-000000000002', 'Burnt',  'ឥដ្ឋខ្លោច')
on conflict (id) do nothing;

-- ── Brick Categories ───────────────────────────────────────────────────────
create table if not exists brick_categories (
  id uuid primary key default uuid_generate_v4(),
  name text not null,
  name_kh text default '',
  description text default '',
  created_at timestamptz default now()
);

alter table brick_categories enable row level security;
create policy "Allow all for anon" on brick_categories for all to anon using (true) with check (true);

-- seed defaults (idempotent)
insert into brick_categories (id, name, name_kh) values
  ('00000000-0000-0000-0001-000000000001', 'Hol', 'ប្រហោង'),
  ('00000000-0000-0000-0001-000000000002', 'Sol', 'ពាន់')
on conflict (id) do nothing;

-- ── Clients ────────────────────────────────────────────────────────────────
create table if not exists clients (
  id uuid primary key,
  name text not null,
  "nameKh" text default '',
  address text default '',
  "addressKh" text default '',
  phone text default '',
  notes text default '',
  "createdAt" timestamptz default now()
);

-- ── Workers ────────────────────────────────────────────────────────────────
create table if not exists workers (
  id uuid primary key,
  name text not null,
  "nameKh" text default '',
  phone text default '',
  role text default 'loader',
  "idCard" text default '',
  notes text default '',
  "createdAt" timestamptz default now()
);

-- ── Cars ───────────────────────────────────────────────────────────────────
create table if not exists cars (
  id uuid primary key,
  "plateNumber" text not null,
  capacity integer default 30000,
  description text default '',
  notes text default ''
);

-- ── Vendors (neighbor vendors) ─────────────────────────────────────────────
create table if not exists vendors (
  id uuid primary key,
  name text not null,
  "nameKh" text default '',
  address text default '',
  phone text default '',
  notes text default '',
  "createdAt" timestamptz default now()
);

-- ── Borrows (borrowed bricks from vendors) ─────────────────────────────────
create table if not exists borrows (
  id uuid primary key,
  "vendorId" uuid references vendors(id) on delete set null,
  "invoiceId" uuid,
  date date not null,
  quantity integer not null,
  "unitPrice" numeric not null,
  "totalAmount" numeric not null,
  status text default 'owed',
  "paymentDate" date,
  notes text default '',
  "createdAt" timestamptz default now()
);

-- ── Invoice Items ─────────────────────────────────────────────────────────
create table if not exists invoice_items (
  id uuid primary key,
  invoice_id uuid references invoices(id) on delete cascade,
  brick_type_id uuid,
  quantity integer not null default 0,
  unit_price numeric not null default 0,
  total numeric not null default 0,
  price_type text default 'normal',
  brick_category text default 'hol',
  created_at timestamptz default now()
);

alter table invoice_items enable row level security;
create policy "Allow all for anon" on invoice_items for all to anon using (true) with check (true);

-- ── Invoices ───────────────────────────────────────────────────────────────
create table if not exists invoices (
  id uuid primary key,
  number text not null,
  date date not null,
  "clientId" uuid references clients(id) on delete set null,
  "carId" uuid references cars(id) on delete set null,
  "workerIds" jsonb default '[]',
  items jsonb default '[]',
  subtotal numeric default 0,
  total numeric default 0,
  "borrowId" uuid,
  notes text default '',
  status text default 'draft',
  "createdAt" timestamptz default now(),
  "updatedAt" timestamptz
);

-- ── Row Level Security (RLS) ───────────────────────────────────────────────
-- For now, allow anon access (no auth).
-- Later you can restrict to authenticated users.

alter table settings enable row level security;
alter table clients enable row level security;
alter table workers enable row level security;
alter table cars enable row level security;
alter table vendors enable row level security;
alter table borrows enable row level security;
alter table invoices enable row level security;

-- Allow all operations for anon key (single-user, internal app)
create policy "Allow all for anon" on settings for all to anon using (true) with check (true);
create policy "Allow all for anon" on clients for all to anon using (true) with check (true);
create policy "Allow all for anon" on workers for all to anon using (true) with check (true);
create policy "Allow all for anon" on cars for all to anon using (true) with check (true);
create policy "Allow all for anon" on vendors for all to anon using (true) with check (true);
create policy "Allow all for anon" on borrows for all to anon using (true) with check (true);
create policy "Allow all for anon" on invoices for all to anon using (true) with check (true);

-- ══════════════════════════════════════════════════════════════════════
-- MIGRATIONS — run these in Supabase SQL Editor if the tables already exist
-- ══════════════════════════════════════════════════════════════════════

-- brick_types: category column
alter table brick_types add column if not exists category text default '';

-- invoices: add deposit (required for save to work)
alter table invoices add column if not exists deposit numeric default 0;

-- invoice_items: standalone table for invoice line items
-- (replaces the jsonb 'items' column approach)
create table if not exists invoice_items (
  id uuid primary key,
  invoice_id uuid references invoices(id) on delete cascade,
  brick_type_id uuid,
  quantity integer not null default 0,
  unit_price numeric not null default 0,
  total numeric not null default 0,
  price_type text default 'normal',
  brick_category text default 'hol',
  created_at timestamptz default now()
);

-- RLS for invoice_items
do $$ begin
  if not exists (
    select 1 from pg_policies
    where tablename = 'invoice_items' and policyname = 'Allow all for anon'
  ) then
    alter table invoice_items enable row level security;
    create policy "Allow all for anon" on invoice_items for all to anon using (true) with check (true);
  end if;
end $$;

-- invoice_items: add price_type / brick_category if table already existed
alter table invoice_items add column if not exists price_type text default 'normal';
alter table invoice_items add column if not exists brick_category text default 'hol';

-- Fix FK constraints to cascade-delete when an invoice is deleted
-- Run these if deleting invoices fails with foreign key violations

alter table invoice_items
  drop constraint if exists invoice_items_invoice_id_fkey;
alter table invoice_items
  add constraint invoice_items_invoice_id_fkey
    foreign key (invoice_id) references invoices(id) on delete cascade;

alter table delivery_items
  drop constraint if exists delivery_items_invoice_id_fkey;
alter table delivery_items
  add constraint delivery_items_invoice_id_fkey
    foreign key (invoice_id) references invoices(id) on delete set null;

-- delivery_proofs and borrow_transactions may also reference invoices
alter table delivery_proofs
  drop constraint if exists delivery_proofs_invoice_id_fkey;
alter table borrow_transactions
  drop constraint if exists borrow_transactions_related_invoice_id_fkey;

-- ── brick_categories table (new) ──────────────────────────────────────────
create table if not exists brick_categories (
  id uuid primary key default uuid_generate_v4(),
  name text not null,
  name_kh text default '',
  description text default '',
  created_at timestamptz default now()
);

do $$ begin
  if not exists (
    select 1 from pg_policies
    where tablename = 'brick_categories' and policyname = 'Allow all for anon'
  ) then
    alter table brick_categories enable row level security;
    create policy "Allow all for anon" on brick_categories for all to anon using (true) with check (true);
  end if;
end $$;

insert into brick_categories (id, name, name_kh) values
  ('00000000-0000-0000-0001-000000000001', 'Hol', 'ប្រហោង'),
  ('00000000-0000-0000-0001-000000000002', 'Sol', 'ពាន់')
on conflict (id) do nothing;

-- clean up brick_types: drop unused 'category' column, ensure name_kh exists
alter table brick_types add column if not exists name_kh text default '';
alter table brick_types drop column if exists category;

insert into brick_types (id, name, name_kh) values
  ('00000000-0000-0000-0000-000000000001', 'Normal', 'ឥដ្ឋធម្មតា'),
  ('00000000-0000-0000-0000-000000000002', 'Burnt',  'ឥដ្ឋខ្លោច')
on conflict (id) do nothing;

-- invoices: add payment_status and tax columns
alter table invoices add column if not exists payment_status text default 'unpaid';
alter table invoices add column if not exists tax numeric default 0;

-- settings: add invoice phone fields
alter table settings add column if not exists "invoicePhone1" text default '069 525 576';
alter table settings add column if not exists "invoicePhone2" text default '012 285 532';
