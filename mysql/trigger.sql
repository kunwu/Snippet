# demo: triggers to log update/insert/delete on snape_config table

# create log table
drop table if exists log_snape_config;
create table log_snape_config (
`id` int not null auto_increment,
`operation` varchar(32) not null comment 'insert, delete, update',
`snape_config_id` int not null comment 'snape_config.id: new value for insert, old value for delete and update',
`snape_config_key` varchar(100) not null comment 'snape_config.key: new value for insert, old value for delete and update',
`updated_columns` varchar(64) null comment 'columns updated ONLY for update operation',
`data_old` text null comment 'concat columns for old value',
`data_new` text null comment 'concat columns for new value',
created_time timestamp not null default current_timestamp,
primary key (id)
) engine=MyISAM default charset=utf8 comment='change log for snape config';

# prepare test table
create table snape_config_1 like snape_config;
insert into snape_config_1 select * from snape_config;

# create update trigger
delimiter $$
drop trigger if exists trigger_snape_config_upd$$
create trigger trigger_snape_config_upd after update on snape_config_1 for each row
begin
	set @updatedColumns = '';
	if (new.`id` <> old.`id`) then
		set @updatedColumns = concat(@updatedColumns, ',id');
	end if;
	if (new.`app` <> old.`app`) then
		set @updatedColumns = concat(@updatedColumns, ',app');
	end if;
	if (new.`key` <> old.`key`) then
		set @updatedColumns = concat(@updatedColumns, ',key');
	end if;
	if (new.`ext` <> old.`ext`) then
		set @updatedColumns = concat(@updatedColumns, ',ext');
	end if;
	if (new.`value` <> old.`value`) then
		set @updatedColumns = concat(@updatedColumns, ',value');
	end if;
	if (new.`enabled` <> old.`enabled`) then
		set @updatedColumns = concat(@updatedColumns, ',enabled');
	end if;
	if (new.`description` <> old.`description`) then
		set @updatedColumns = concat(@updatedColumns, ',description');
	end if;

	if (@updatedColumns != '') then
		set @updatedColumns = substr(@updatedColumns, 2);
		insert into log_snape_config values
		(default, 'update', old.id, old.key, @updatedColumns,
			concat(old.id, '\t', old.app, '\t', old.`key`, '\t', old.ext, '\t', old.`value`, '\t', old.enabled, '\t', old.description),
			concat(new.id, '\t', new.app, '\t', new.`key`, '\t', new.ext, '\t', new.`value`, '\t', new.enabled, '\t', new.description),
			default
		);
	else
		set @updatedColumns = null;
	end if;

end$$
delimiter ;

# create insert trigger
delimiter $$
drop trigger if exists trigger_snape_config_ins$$
create trigger trigger_snape_config_ins after insert on snape_config_1 for each row
begin
	insert into log_snape_config values
	(default, 'insert', new.id, new.key, null, null,
		concat(new.id, '\t', new.app, '\t', new.`key`, '\t', new.ext, '\t', new.`value`, '\t', new.enabled, '\t', new.description),
		default
	);
end$$
delimiter ;

# create delete trigger
delimiter $$
drop trigger if exists trigger_snape_config_del$$
create trigger trigger_snape_config_del after delete on snape_config_1 for each row
begin
	insert into log_snape_config values
	(default, 'delete', old.id, old.key, null,
		concat(old.id, '\t', old.app, '\t', old.`key`, '\t', old.ext, '\t', old.`value`, '\t', old.enabled, '\t', old.description),
		null,
		default
	);
end$$
delimiter ;

# review
show triggers like '%snape_config%';

# debug & verification
select * from snape_config_1;
select * from log_snape_config order by id desc;
set session sql_safe_updates = 0;
insert into snape_config_1 values (default, 'a', 'k', 0, 'v', 0, 'd');
update snape_config_1 set enabled = 1, value = 'on', ext = 0 where app = 'a';
delete from snape_config_1 where app = 'a';

