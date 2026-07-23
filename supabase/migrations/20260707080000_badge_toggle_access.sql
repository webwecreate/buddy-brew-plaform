-- Admin Dashboard Badge/Mission tab: let authenticated (staff/admin) turn badges on/off.
-- Column-level grant — only `active` is writable, not name/condition/icon (those still
-- need a migration, since editing them changes what the check_badge_unlocks() trigger
-- logic in 20260707060000 is actually checking against).

grant select on table badges to authenticated;
create policy "authenticated can read badges" on badges for select to authenticated using (true);

grant update (active) on table badges to authenticated;
create policy "authenticated can toggle badge active" on badges for update to authenticated using (true) with check (true);

notify pgrst, 'reload schema';
