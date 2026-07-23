-- Admin Dashboard เมนู tab needs to edit prices/availability and add new items directly.
-- anon already has select-only (20260706040000/20260706050000) — this adds a *separate*,
-- higher privilege level for authenticated (staff/admin), same two-layer rule as always.

grant insert, update on table menu_items to authenticated;
create policy "authenticated can insert menu items" on menu_items for insert to authenticated with check (true);
create policy "authenticated can update menu items" on menu_items for update to authenticated using (true) with check (true);

grant insert, update on table bean_options to authenticated;
create policy "authenticated can insert bean options" on bean_options for insert to authenticated with check (true);
create policy "authenticated can update bean options" on bean_options for update to authenticated using (true) with check (true);

notify pgrst, 'reload schema';
