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
