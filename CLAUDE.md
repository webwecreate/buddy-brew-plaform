# Buddy Brew Member Platform

> Hot memory — เก็บให้ LEAN เสมอ. detail อยู่ใน PROJECT_OVERVIEW.md ไม่ใช่ที่นี่

## เริ่มทุก session (ทำก่อนเสมอ)
1. อ่าน PROJECT_OVERVIEW.md — single source of truth ไม่ต้องไล่แชทเก่า
2. อ่าน learning.md — กันทำผิดซ้ำ
3. สรุป scope ของ task รอบนี้ให้ผู้ใช้ยืนยันก่อนลงมือ

## Conventions
- แก้โค้ด/schema → commit → push ทันที (ถือเป็น backup อัตโนมัติ)
- migration ใหม่ทุกตัว: ตรวจว่า enable RLS แล้วต้องมี **policy จริง** ด้วย ไม่ใช่แค่ grant (ดู learning.md ข้อ RLS)
- ก่อนจบ session: อัปเดต PROJECT_OVERVIEW.md (เช็คลิสต์ข้อ 9) + learning.md (ถ้าเจอปัญหาใหม่) แล้ว push

## Stack
Supabase (Postgres + Edge Functions, project ref `xsokynhtoxktazlomsnx`) + LINE OA/LIFF + GitHub Pages (`docs/`) + GitHub Actions (auto-deploy functions)

## Never
- ห้าม commit service_role key / secret key ลง git เด็ดขาด (เก็บเป็น Edge Function secret เท่านั้น)
- ห้ามคำนวณแต้มจากราคา (`base_price`/`final_price`) — ใช้ `menu_items.point_value` เสมอ (ดู PROJECT_OVERVIEW.md ข้อ 6)
