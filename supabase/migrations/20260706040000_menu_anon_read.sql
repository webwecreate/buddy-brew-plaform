-- Staff Panel (เว็บธรรมดา ยังไม่มี staff-login) ต้องอ่านเมนู/ราคาได้เพื่อแสดงปุ่มให้กด
-- ปลอดภัย เพราะเป็นแค่ชื่อเมนู/ราคา ไม่ใช่ข้อมูลลูกค้า และให้แค่ select อย่างเดียว (อ่านได้ แก้ไม่ได้)
grant select on table menu_items to anon;
grant select on table bean_options to anon;
notify pgrst, 'reload schema';
