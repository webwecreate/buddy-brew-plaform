create table menu_items (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  category text not null,          -- signature / coffee / matcha / non_coffee / special
  base_price numeric not null,     -- ราคาใช้เมล็ด/วัตถุดิบมาตรฐาน
  has_bean_choice boolean not null default false,
  active boolean not null default true
);
alter table menu_items enable row level security;
grant select, insert, update, delete on table menu_items to service_role;

create table bean_options (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  extra_price numeric not null default 0,   -- 0 = มาตรฐาน, +20 = special beans
  active boolean not null default true
);
alter table bean_options enable row level security;
grant select, insert, update, delete on table bean_options to service_role;

insert into bean_options (name, extra_price) values
  ('มาตรฐาน', 0),
  ('Special Beans (Osmanthus)', 20);

insert into menu_items (name, category, base_price, has_bean_choice) values
  ('Caramel Dirty', 'signature', 70, true),
  ('Birthday Cake Latte', 'signature', 80, true),
  ('Black Strawberry Frizz', 'signature', 75, true),
  ('Americano', 'coffee', 55, true),
  ('Espresso', 'coffee', 55, true),
  ('Latte', 'coffee', 60, true),
  ('Cappuccino', 'coffee', 60, true),
  ('Mocha', 'coffee', 70, true),
  ('Caramel Latte', 'coffee', 75, true),
  ('Earl Grey Latte', 'coffee', 70, true),
  ('French Vanilla Latte', 'coffee', 70, true),
  ('Orange Espresso', 'coffee', 70, true),
  ('Coconut Espresso', 'coffee', 75, true),
  ('Es-Yen', 'coffee', 65, true),
  ('Drip Coffee', 'coffee', 100, true),
  ('Clear Matcha', 'matcha', 90, false),
  ('Matcha Latte', 'matcha', 85, false),
  ('Strawberry Matcha', 'matcha', 95, false),
  ('Matcha Dirty', 'matcha', 85, false),
  ('Birthday Cake Matcha', 'matcha', 90, false),
  ('Orange Matcha', 'matcha', 85, false),
  ('Matcha Coco Cloud', 'matcha', 90, false),
  ('Rich Cocoa', 'non_coffee', 60, false),
  ('Strawberry Cocoa', 'non_coffee', 75, false),
  ('Thai Milk Tea', 'non_coffee', 60, false),
  ('Earl Grey Lemon Tea', 'non_coffee', 60, false),
  ('Honey Lemon Soda', 'non_coffee', 55, false),
  ('Acai Lemonade', 'non_coffee', 50, false),
  ('Oreo Milk', 'non_coffee', 50, false),
  ('Taro Milk', 'non_coffee', 50, false),
  ('Strawberry Earl Grey-Sparkling', 'non_coffee', 60, false),
  ('Honey Lemon Cloud', 'special', 100, false);
