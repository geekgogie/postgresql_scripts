#!/bin/bash

while true
do

	date;
	echo '***** 192.168.30.40: MASTER *****'
	PGPASSWORD=dbapgadmin psql -h192.168.30.40 -Udbapgadmin -c " select * from pg_stat_replication;" postgres -x;

	PGPASSWORD=dbapgadmin psql -h192.168.30.40 -Udbapgadmin -x postgres <<EOF
	select
	pid,
	application_name,
	pg_last_wal_replay_lsn(),
	sent_lsn,
	flush_lsn,
	replay_lsn,
	pg_wal_lsn_diff(pg_current_wal_lsn(), sent_lsn) sending_lag,
	pg_wal_lsn_diff(sent_lsn, flush_lsn) receiving_lag,
	pg_wal_lsn_diff(flush_lsn, replay_lsn) replaying_lag,
	pg_wal_lsn_diff(pg_current_wal_lsn(), replay_lsn) total_lag
	from pg_stat_replication;
EOF

	echo '***** pslchi5ppgsql10: SLAVE *****'

	PGPASSWORD=dbapgadmin psql -U dbapgadmin -h 192.168.30.50 -x postgres << EOF
	SELECT
	CASE WHEN pg_last_wal_receive_lsn() = pg_last_wal_replay_lsn()
	THEN 0
	ELSE EXTRACT (EPOCH FROM now() - pg_last_xact_replay_timestamp())
	END AS log_delay, now();

	select pg_is_in_recovery(),pg_is_wal_replay_paused(), pg_last_wal_receive_lsn(), pg_last_wal_replay_lsn(), pg_last_xact_replay_timestamp();
	select pg_last_wal_receive_lsn(), pg_last_wal_replay_lsn(), pg_wal_lsn_diff(pg_last_wal_receive_lsn(),pg_last_wal_replay_lsn());
	select * from pg_stat_wal_receiver;

EOF

	echo '******************************************';
	sleep 15;
done;
