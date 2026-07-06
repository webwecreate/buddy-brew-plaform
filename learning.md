# Learning log

อ่านก่อนเริ่มทุก session เพื่อกันทำผิดซ้ำ
เมื่อทำผิดแล้วแก้ได้ ให้บันทึกที่นี่ทันที

รูปแบบ: **[อาการที่เจอ]** → *สาเหตุจริง* → **วิธีแก้ที่ได้ผล**

---

## Entries

- **สร้าง LIFF app ผ่าน Messaging API channel ไม่ได้** → *LINE เปลี่ยนกฎ ต้องสร้าง LIFF ผ่าน LINE Login channel เท่านั้น* → สร้าง LINE Login channel แยก แล้วเพิ่ม LIFF app ในนั้นแทน
- **เปิด GitHub Pages ฟรีไม่ได้** → *repo เป็น Private, GitHub Pages ฟรีใช้ได้แค่ repo Public* → เปลี่ยน repo เป็น Public (ปลอดภัยเพราะไม่เคย commit secret ลง repo)
- **Edge Function ตอบ 500 / log โชว์แค่ "booted" แล้ว "shutdown: EarlyDrop" ไม่มี error จริง** → *สองสาเหตุรวมกัน: (1) ตารางที่ query ไม่มีอยู่จริงในโปรเจกต์ที่สร้างใหม่ (ลืมรัน migration) (2) `import ... from "https://esm.sh/@supabase/supabase-js@2"` ทำให้ boot fail เงียบๆ* → เช็คว่ารัน migration ครบก่อน + เปลี่ยน import เป็น `npm:@supabase/supabase-js@2`
- **Supabase GitHub Integration ไม่ deploy Edge Function ให้ ทั้งที่ deploy migration ให้เอง** → *Integration หลัก (Project Settings → Integrations) ครอบคลุมแค่ database migrations ไม่รวม Edge Functions* → ตั้ง GitHub Actions แยก (`.github/workflows/deploy-functions.yml`) ใช้ `supabase/setup-cli` + secret `SUPABASE_ACCESS_TOKEN`, ใช้ `supabase functions deploy` (ไม่ระบุชื่อ) เพื่อ deploy ทุกฟังก์ชันพร้อมกัน
- **"permission denied for table X" แม้ใช้ service_role key** → *ตอนสร้างโปรเจกต์ปิด "Automatically expose new tables" ไว้ ตารางที่สร้างผ่าน raw SQL migration เลยไม่มี GRANT ให้ role ไหนเลยแม้แต่ service_role* → เพิ่ม `grant select, insert, update, delete on table X to service_role;` เอง แล้วสั่ง `notify pgrst, 'reload schema';` ต่อท้ายทุกครั้งที่ grant ใหม่ (บังคับ PostgREST รีเฟรช cache ทันที)
- **`grant select ... to anon` แล้วแต่ query ได้ array ว่างเปล่า (ไม่ error)** → *ตารางเปิด RLS อยู่ grant สิทธิ์ระดับตารางอย่างเดียวไม่พอ ต้องมี RLS policy ด้วย ไม่งั้น RLS filter ทุกแถวออกหมด (default-deny)* → เพิ่ม `create policy "..." on table_name for select to anon using (true);` เสมอคู่กับ grant — **grant = มีสิทธิ์แตะตารางไหม, policy = เห็นแถวไหนบ้าง ต้องผ่านทั้งสองชั้น**
- **QR ที่สแกนด้วยกล้องมือถือทั่วไปเปิดเบราว์เซอร์นอก LINE บังคับ login ใหม่** → *QR encode เป็น URL ตรงของเว็บ (GitHub Pages) แทนที่จะเป็น URL พิเศษของ LINE* → encode เป็น `https://liff.line.me/{liffId}?token=...` แทน ทำให้สแกนแล้ว deep-link เข้าแอป LINE ที่ login ค้างอยู่ทันที
