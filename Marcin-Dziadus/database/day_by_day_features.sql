create or replace function init_revenues_table(varchar, int, int) returns void as
$$
declare
  low varchar := concat($2, 'days');
  up varchar := concat($3, 'days');
  query varchar := 'create temp table %s as
                    select conversions.user_id, sum(price*quantity) as %s
                    from conversions
                    join users
                    on conversions.user_id=users.user_id
                       and conversions.timestamp - users.signup_time >= %s
                       and conversions.timestamp - users.signup_time < %s
                    group by conversions.user_id;';
begin
   execute format(query, $1, $1, quote_literal(low),quote_literal(up));
end;
$$
language plpgsql;

create or replace function init_views_table(varchar, int, int) returns void as
$$
declare
  low varchar := concat($2, 'days');
  up varchar := concat($3, 'days');
  query varchar := 'create temp table %s as
		    select views.user_id, count(views.user_id) as %s
		    from views
                    join users
                    on views.user_id=users.user_id
                       and views.timestamp - users.signup_time >= %s
                       and views.timestamp - users.signup_time < %s
                    group by views.user_id;';
begin
   execute format(query, $1, $1, quote_literal(low),quote_literal(up));
end;
$$
language plpgsql;

create or replace function create_column(varchar) returns void as $$
declare
  query_create varchar := 'alter table days_features add column %s float;';
begin
  execute format(query_create, $1);
end;
$$
language plpgsql;

create or replace function update_column(varchar) returns void as
$$
declare
  query varchar := 'update days_features set %s = %s.%s from %s where days_features.user_id = %s.user_id';
begin
   execute format(query, $1,$1,$1,$1,$1);
end;
$$
language plpgsql;

create or replace function normalize_revenues(varchar) returns void as
$$
declare
  query varchar := 'update days_features set %s = round(coalesce(%s,0)::numeric,3)';
begin
   execute format(query, $1, $1);
end;
$$
language plpgsql;

create or replace function normalize_views(varchar) returns void as
$$
declare
  query varchar := 'update days_features set %s = coalesce(%s,0)';
begin
   execute format(query, $1, $1);
end;
$$
language plpgsql;

create or replace function create_features(low int, up int) returns void as
$$
declare
  col_name varchar;
  revenues_name varchar;
  views_name varchar;
begin
  execute 'drop table if exists days_features';
  execute 'create temp table days_features as select user_id from features';
  for i in low..up loop
    col_name := concat('day', i);
    views_name := concat('view_', col_name);
    revenues_name := concat('revenue_', col_name);
    begin
	raise notice 'robie iteracje';
  --    execute format('drop table if exists %s', revenues_name);
--      execute format('drop table if exists %s', views_name);
--	raise notice 'robie cos';

  --    execute init_revenues_table(revenues_name, i-1, i);
      execute init_views_table(col_name, i-1, i);
--	raise notice 'robie cos';

   --   execute create_column(views_name);
  --    execute create_column(revenues_name);
--	raise notice 'robie cos';

   --   execute update_column(views_name);
     -- execute update_column(revenues_name);
	raise notice 'robie cos';

   --   execute normalize_views(views_name);
  --    execute normalize_revenues(revenues_name);
    end;
  end loop;
end;
$$
language plpgsql;

select create_features(1,7);
\copy (select days_features.*, features.month_revenue from features join days_features on features.user_id=days_features.user_id) to '/tmp/data.csv' with CSV header;

