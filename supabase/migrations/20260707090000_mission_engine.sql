-- Mission engine v1 (Admin Dashboard Badge/Mission tab, scoped down from the full wireframe
-- vision — see PROJECT_OVERVIEW.md §9 for the reasoning). This migration only gets missions
-- to "the trigger correctly detects completion." It deliberately does NOT award reward_point
-- automatically, and there's no Buddy Book UI to view/claim missions yet — missions_progress
-- already has a 3-state status (in_progress/completed/claimed) implying a claim step, and
-- claiming (+ awarding points at that moment) is customer-facing work for the next round.

-- target_count: how many qualifying purchases complete the mission (daily/weekly repeats,
-- so we need this to be configurable rather than always "1").
alter table missions add column target_count integer not null default 1;

-- period_start: distinguishes "today's" completion from "yesterday's" for repeating
-- missions — the original schema had no way to do this at all.
alter table missions_progress add column period_start date not null default current_date;
alter table missions_progress add constraint missions_progress_member_mission_period_key unique (member_id, mission_id, period_start);

grant select, insert, update, delete on table missions to authenticated;
create policy "authenticated can manage missions" on missions for all to authenticated using (true) with check (true);

grant select on table missions_progress to authenticated;
create policy "authenticated can read missions_progress" on missions_progress for select to authenticated using (true);

-- Same menu_item_id-is-not-null guard as check_badge_unlocks() (20260707060000) — only
-- real purchases count, not manual point adjustments or birthday bonuses.
create or replace function check_mission_progress()
returns trigger
language plpgsql
security definer
as $$
declare
  m record;
  v_period_start date;
  v_count integer;
begin
  if new.menu_item_id is null then
    return new;
  end if;

  for m in select id, type, target_count from missions where active = true loop
    v_period_start := case
      when m.type = 'weekly' then date_trunc('week', new.created_at)::date
      else new.created_at::date
    end;

    select count(*) into v_count
      from points_transactions
      where member_id = new.member_id
        and menu_item_id is not null
        and (
          (m.type = 'weekly' and date_trunc('week', created_at)::date = v_period_start)
          or (m.type = 'daily' and created_at::date = v_period_start)
        );

    if v_count >= m.target_count then
      insert into missions_progress (member_id, mission_id, period_start, status)
      values (new.member_id, m.id, v_period_start, 'completed')
      on conflict (member_id, mission_id, period_start)
      do update set status = 'completed' where missions_progress.status = 'in_progress';
    else
      insert into missions_progress (member_id, mission_id, period_start, status)
      values (new.member_id, m.id, v_period_start, 'in_progress')
      on conflict (member_id, mission_id, period_start) do nothing;
    end if;
  end loop;

  return new;
end;
$$;

create trigger trg_check_mission_progress
after insert on points_transactions
for each row
execute function check_mission_progress();

notify pgrst, 'reload schema';
