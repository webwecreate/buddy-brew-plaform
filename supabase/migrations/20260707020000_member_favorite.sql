-- Star/favorite flag for members, so Admin Dashboard สมาชิก tab can pin regulars/VIPs
-- to the top regardless of list size. Shared across staff (not per-staff), same as
-- staff_note/staff_photo_url — column-level grant follows the same pattern.

alter table members add column is_favorite boolean not null default false;

grant update (is_favorite) on members to authenticated;

notify pgrst, 'reload schema';
