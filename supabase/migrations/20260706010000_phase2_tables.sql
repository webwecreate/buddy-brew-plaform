-- Phase 2: reward engine tables (points ledger, badges, missions, rewards, coupons, referrals, delivery claim, promotions)

create table points_transactions (
  id uuid primary key default gen_random_uuid(),
  member_id uuid not null references members(id),
  point_change integer not null,
  menu_item_id uuid references menu_items(id),
  bean_option_id uuid references bean_options(id),
  final_price numeric,           -- ราคาที่ลูกค้าจ่ายจริง เก็บไว้ดูยอดขาย ไม่ใช้คิดแต้ม
  channel text not null default 'in_store',  -- in_store / delivery_grab / delivery_lineman
  reason text,                   -- ใช้ตอนไม่ใช่การซื้อเมนู เช่น birthday_field_bonus, manual_adjustment: ...
  created_at timestamptz not null default now()
);

create table badges (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  condition text not null,       -- คำอธิบายเงื่อนไข (logic คำนวณจริงอยู่ใน Reward Engine)
  icon text,                     -- ชื่อ tabler icon เช่น 'ti-coffee'
  active boolean not null default true
);

create table badges_earned (
  id uuid primary key default gen_random_uuid(),
  member_id uuid not null references members(id),
  badge_id uuid not null references badges(id),
  earned_at timestamptz not null default now(),
  unique (member_id, badge_id)
);

create table missions (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  type text not null,             -- daily / weekly
  reward_point integer not null,
  active boolean not null default true
);

create table missions_progress (
  id uuid primary key default gen_random_uuid(),
  member_id uuid not null references members(id),
  mission_id uuid not null references missions(id),
  status text not null default 'in_progress',   -- in_progress / completed / claimed
  updated_at timestamptz not null default now()
);

create table rewards (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  point_cost integer not null,
  active boolean not null default true
);

create table coupons (
  id uuid primary key default gen_random_uuid(),
  member_id uuid not null references members(id),
  reward_id uuid references rewards(id),
  code text not null unique,
  status text not null default 'active',   -- active / used / expired
  source text not null,                    -- birthday / points_redemption / manual
  expires_at timestamptz,
  created_at timestamptz not null default now()
);

create table referrals (
  id uuid primary key default gen_random_uuid(),
  referrer_id uuid not null references members(id),
  referred_id uuid not null references members(id) unique,
  created_at timestamptz not null default now()
);

create table order_claim_tokens (
  id uuid primary key default gen_random_uuid(),
  token text not null unique,
  channel text not null,          -- grab / lineman / other
  point_value integer not null,
  status text not null default 'pending',   -- pending / claimed
  claimed_by uuid references members(id),
  claimed_at timestamptz,
  created_at timestamptz not null default now(),
  expires_at timestamptz not null
);

create table promotions (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text,
  tag text,
  start_at timestamptz,
  end_at timestamptz,
  active boolean not null default true
);

-- RLS + service_role grants (จำจากบั๊กตอนสร้าง members ครั้งแรก: auto-expose ปิดไว้ ต้อง grant เอง)
alter table points_transactions enable row level security;
alter table badges enable row level security;
alter table badges_earned enable row level security;
alter table missions enable row level security;
alter table missions_progress enable row level security;
alter table rewards enable row level security;
alter table coupons enable row level security;
alter table referrals enable row level security;
alter table order_claim_tokens enable row level security;
alter table promotions enable row level security;

grant select, insert, update, delete on table points_transactions to service_role;
grant select, insert, update, delete on table badges to service_role;
grant select, insert, update, delete on table badges_earned to service_role;
grant select, insert, update, delete on table missions to service_role;
grant select, insert, update, delete on table missions_progress to service_role;
grant select, insert, update, delete on table rewards to service_role;
grant select, insert, update, delete on table coupons to service_role;
grant select, insert, update, delete on table referrals to service_role;
grant select, insert, update, delete on table order_claim_tokens to service_role;
grant select, insert, update, delete on table promotions to service_role;

notify pgrst, 'reload schema';
