select * from wydot_speed_unprocessed w
where w.utc > '2018-01-01'
ORDER BY w.utc DESC
limit 10;
