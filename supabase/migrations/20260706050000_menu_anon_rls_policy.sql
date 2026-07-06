-- แก้บั๊ก: grant ตารางไปแล้วแต่ลืมสร้าง RLS policy จริง ทำให้ anon อ่านได้แต่โดน RLS กรองเหลือ 0 แถวเสมอ
create policy "anon can read menu items" on menu_items for select to anon using (true);
create policy "anon can read bean options" on bean_options for select to anon using (true);
notify pgrst, 'reload schema';
