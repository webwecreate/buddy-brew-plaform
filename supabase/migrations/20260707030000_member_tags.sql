-- Free-form tags for members (e.g. กลุ่ม, คู่, บอร์ดเกม, ซื้อกลับ) to segment customer
-- behavior. Plain text[] instead of a separate tags table/join table — the vocabulary is
-- small and managed inline in the member profile for now; revisit as a proper join table
-- (with a management tab) only if it grows enough to need renaming/analytics.

alter table members add column tags text[] not null default '{}';

grant update (tags) on members to authenticated;

notify pgrst, 'reload schema';
