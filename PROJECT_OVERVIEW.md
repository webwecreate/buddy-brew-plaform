# Buddy Brew Member Platform — Project Overview

สรุปรวมทุกอย่างที่ตัดสินใจไว้ในการวางแผนระบบสมาชิก ใช้เป็น backup อ้างอิง ไม่ต้องไล่อ่านแชทเก่าซ้ำ

---

## 1. เป้าหมาย

สร้างระบบสมาชิกของร้าน Buddy Brew ที่เป็นทรัพย์สินของร้านเอง ทำงานผ่าน LINE OA + LIFF
ไม่ใช่แค่ระบบแต้ม แต่ต่อยอดเป็น Tier, Badge, Mission, Coupon, Referral ได้ในอนาคต

---

## 2. Tech stack

| ส่วน | ใช้อะไร | เหตุผล |
|---|---|---|
| ช่องทางลูกค้า | LINE OA + LIFF | ลูกค้าไม่ต้องลงแอปใหม่ ใช้ LINE ที่มีอยู่แล้ว |
| Backend | Supabase (Postgres + Data API + Edge Functions) | ตั้งค่าเร็ว หน้าตา Table Editor คล้ายสเปรดชีตที่คุ้นเคยอยู่แล้ว ไม่ต้องเขียน backend เองทั้งหมดแบบ WordPress plugin |
| Staff Panel / Admin Dashboard | เว็บ (ไม่ใช่แอป) | เปิดจากมือถือ/โน้ตบุ๊คได้ทันที ไม่ต้องผ่าน App Store |
| ปริ้นเตอร์ (สำหรับเคส delivery) | Wongnai 58IIH (ESC/POS) เครื่องสำรองที่มีอยู่แล้ว ผูกเป็นเครื่องเฉพาะของ Buddy Brew | ปริ้นเตอร์ Bluetooth ที่ต่อกับ GrabMerchant แชร์กับระบบอื่นพร้อมกันไม่ได้ (Bluetooth Classic ต่อได้ทีละอุปกรณ์) |

---

## 3. Architecture

```
ลูกค้า (LINE App) ──┐                      พนักงาน (POS/แท็บเล็ต) ──┐
                    ▼                                              ▼
        ┌── LINE Platform ──┐                    ┌── Buddy Platform (Supabase) ──┐
        │ LINE OA · Messaging API │──────────────▶│ Data API (auto REST)          │
        │ LIFF หน้าสมาชิก         │               │ Edge Functions (Reward Engine) │
        └────────────────────┘                    │ Staff Panel + Admin Dashboard  │
                    │                              └────────────────────────────────┘
                    └──────────────────┬──────────────────────┘
                                       ▼
                              Database (Postgres)
                         members · points · badges · coupons
```

- LIFF page เป็นหน้าเว็บ HTML/JS ธรรมดา เรียก Supabase ผ่าน Edge Function เท่านั้น ไม่แตะตารางตรงๆ
- Staff Panel และ Admin Dashboard เป็นเว็บเดียวกัน แยกมุมมองตาม role หลัง login (ดูข้อ 6)

---

## 4. Database schema

### `members` (สร้างแล้วใน Phase 1)

```sql
create table members (
  id uuid primary key default gen_random_uuid(),
  line_user_id text unique not null,
  display_name text not null,
  picture_url text,
  tier text not null default 'sip',       -- sip / drink / slurpp
  point integer not null default 0,
  birthday date,
  staff_photo_url text,                    -- อัพโดยพนักงาน เห็นเฉพาะ staff/admin
  staff_note text,                         -- จำหน้า-นิสัย-ชื่อเล่น เห็นเฉพาะ staff/admin
  created_at timestamptz not null default now()
);
alter table members enable row level security;  -- ไม่มี policy = เข้าได้แค่ทาง edge function เท่านั้น
```

### ตารางที่จะเพิ่มใน Phase 2

```
points_transactions (id, member_id FK, point_change, reason, created_at)
badges (id, name, condition)
badges_earned (id, member_id FK, badge_id FK, earned_at)
missions (id, title, type, reward_point)
missions_progress (id, member_id FK, mission_id FK, status)
rewards (id, name, point_cost)
coupons (id, member_id FK, reward_id FK, code, status, expires_at)
referrals (id, referrer_id FK, referred_id FK, created_at)
order_claim_tokens (id, token, channel, point_value, status, claimed_by, claimed_at, expires_at)
  -- สำหรับเคส delivery (Grab/LINEMAN) ดูข้อ 5
```

---

## 5. Flow หลัก

**User flow (สะสมแต้มหน้าร้าน)**
1. ลูกค้าชำระเงินที่ POS Wongnai ตามปกติ (ไม่แตะต้อง POS)
2. ลูกค้าเปิด LINE แสดง QR สมาชิกจาก LIFF
3. พนักงานสแกน QR ด้วยมือถือ (Staff Scanner แบบเว็บ)
4. พนักงานกรอกยอด/จำนวนแก้ว กดยืนยัน
5. ระบบอัปเดตแต้ม + แจ้งเตือนกลับทาง LINE ทันที

**Delivery flow (Grab/LINEMAN — ไม่มีจังหวะเจอหน้าลูกค้า)**
1. พนักงานแพ็คออเดอร์ตามปกติ
2. เปิด Staff Panel → กรอกยอด → ระบบสร้าง QR/รหัส **ใช้ได้ครั้งเดียว** (token สุ่ม ไม่ใช่ static QR)
3. แปะสติกเกอร์ติดถุง (หรือเขียนรหัส 6 หลักด้วยมือถ้ายังไม่มีระบบปริ้นอัตโนมัติ)
4. ลูกค้าได้รับของ สแกน/กรอกรหัส → login LINE (ถ้ายังไม่เคย)
5. ระบบเช็ค token แบบ atomic (เคลมซ้ำไม่ได้) → เพิ่มแต้มให้บัญชีที่ login อยู่
6. ข้อจำกัดที่ต้องยอมรับ: adoption ต่ำกว่าหน้าร้านเพราะต้องพึ่งลูกค้าเปิดแอปมาเคลมเอง ไม่ใช่ 100%

**Admin/Staff access — ตัดสินใจแล้ว: Option A (เว็บธรรมดา)**
- เข้า URL หลังบ้านเดียวกันจากเบราว์เซอร์ (มือถือ/โน้ตบุ๊ค) ไม่ใช่แอป ไม่ใช่ LIFF กด "เพิ่มลงหน้าจอโฮม" ให้หน้าตาเหมือนแอปได้
- Login ด้วย email+รหัสผ่านของ Supabase เอง ไม่ผูกกับ LINE account ส่วนตัวของพนักงาน
- เหตุผล: เร็วกว่า ไม่ต้องสร้าง allowlist LINE user ID + ไม่ต้องสร้าง LIFF channel เพิ่มอีก 2 ตัว (พิจารณา migrate เป็น LIFF ทีหลังได้ ตาม option B ใน ci-guide ถ้าต้องการ)
- Login แล้วแยกมุมมองตาม role อัตโนมัติ

---

## 6. Role & Permissions

| ข้อมูล | ลูกค้า (LIFF) | พนักงาน (Staff Panel) | เจ้าของ (Admin Dashboard) |
|---|---|---|---|
| แต้ม/Tier/QR ตัวเอง | เห็น | เห็น (ตอนสแกน) | เห็น |
| รูป+โน้ตจำลูกค้า (staff_photo_url, staff_note) | **ไม่เห็นเด็ดขาด** | เห็นเต็ม | เห็นเต็ม |
| ตั้งค่า mission/badge/รายงาน | ไม่เห็น | ไม่เห็น | เห็น |

กติกาสำคัญ: ฟิลด์ `staff_photo_url`/`staff_note` ต้องกรองออกตั้งแต่ระดับ REST endpoint (endpoint ที่ลูกค้าเรียกจาก LIFF ไม่ส่งสองฟิลด์นี้กลับมาเลย) ไม่ใช่แค่ซ่อนที่หน้าจอ

ปรับสิทธิ์นี้ทีหลังได้เสมอ (เช่น เพิ่ม role "ผู้จัดการ") เพราะเช็ค role ที่ชั้น API ไม่ได้ฝังตายตัวในโครงสร้าง

---

## 7. Brand / Design guideline

- **สีหลัก**: แดง `#B32324` — ใช้เป็น accent (ปุ่ม, progress bar, Tier badge) บนพื้นขาว/ครีม
- **โลโก้/มาสคอต**: เส้น hand-drawn สีแดงล้วน ตัวการ์ตูนคู่บัดดี้หน้ายิ้ม ไฟล์ต้นทางอยู่ที่ `Artwork/transparent-logo.png` (ไม่มีตัวหนังสือ) และ `Artwork/buddy-brew-logo.svg` (เต็มพร้อมชื่อร้าน)
- **Tone**: เป็นกันเอง เหมือนเพื่อนคุย ไม่เป็นทางการ (เช่น "เหลืออีก 20 แต้มถึง Slurpp Tier แล้วนะ")
- **Tier ที่ใช้จริง**: Sip / Drink / Slurpp (ไม่ใช่ Bronze/Silver/Gold — อันนั้นเป็นแค่ demo graphic เดิม)
- **Channel icon (LINE Login channel / LIFF)**: มีระบบพร้อมแล้วใน `Artwork/ci-guide.png` — ใช้แบบที่ 1 (Badge มุมขวาบน) โลโก้หลัก + badge สีเขียวสำหรับ LIFF (Customer)
- **Naming convention (จาก ci-guide)**:
  - Provider: Buddy Brew
  - Messaging API channel: Buddy Brew Messaging
  - LINE Login channel: Buddy Brew Member
  - LIFF app (Customer): **Buddy Book** ← ใช้ชื่อนี้ตอนสร้าง LIFF app (เลือกแทน Buddy Passport เพราะโทนอบอุ่นกว่า เข้ากับมาสคอต)
  - (Staff/Admin ไม่ใช้ LIFF แล้วตามการตัดสินใจ Option A — ชื่อ Buddy Staff/Buddy Admin ใน ci-guide เก็บสำรองไว้เผื่ออนาคต)

---

## 8. สถานะปัจจุบัน (Phase 1)

- [x] ตัดสินใจ tech stack: LINE OA + LIFF + Supabase
- [x] ออกแบบ schema `members` + ตารางอนาคต
- [x] สร้าง Supabase project (Singapore region)
- [x] รัน `schema.sql` สร้างตาราง `members`
- [x] เขียน Edge Function `create-or-get-member` (verify LINE ID token + upsert)
- [x] เขียนหน้า LIFF login แรก (`liff/index.html`)
- [x] สร้าง Provider "Buddy Brew" ใน LINE Developers
- [x] Enable Messaging API บน OA เดิมผ่าน LINE Official Account Manager
- [x] สร้าง LINE Login channel + LIFF app (เพราะ LINE เปลี่ยนกฎ ต้องสร้างผ่าน LINE Login channel ไม่ใช่ Messaging API channel แล้ว)
- [ ] เอา LIFF ID มาใส่ในโค้ด
- [ ] Deploy Edge Function จริง (ตั้งค่า secret `LIFF_CHANNEL_ID`)
- [ ] หา hosting ให้หน้า LIFF (ต้องมี HTTPS URL จริงถึงจะทดสอบ LIFF ได้เต็มรูปแบบ)
- [ ] ทดสอบ login ครั้งแรกจริงจากมือถือ

## Phase 2 (ยังไม่เริ่ม)
Tier graphic ใหม่ (Sip/Drink/Slurpp), Staff Panel (สแกน+กรอกแต้ม+อัพรูปลูกค้า), Reward Engine, Badge/Mission, Referral, Delivery QR claim, เชื่อม printer 58IIH

## Phase 3 (ยังไม่เริ่ม)
Lucky Wheel, Leaderboard, Seasonal Event, Coffee Passport, Personalized Offer
