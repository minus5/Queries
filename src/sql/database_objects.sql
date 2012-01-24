begin try
	drop table #tmpObjects
end try
begin catch
end catch 

create table #tmpObjects (database_name varchar(255), schema_name varchar(255), object_name varchar(255), type varchar(255))
declare @sql nvarchar(4000)
declare @database_id int, @database_name varchar(255)
set @database_id = 0


while @database_id is not null 
begin
	select top 1 
		@database_id = database_id,
		@database_name = name
	from master.sys.databases 
	where database_id > @database_id and [state] = 0 --and owner_sid != 01
	order by database_id

	if @@rowcount > 0
	begin 
		set @sql = replace('
		insert into #tmpObjects (database_name , schema_name, object_name, type)
		select 
			''pubs'' database_name,
			schemas.name schema_name,
			objects.name object_name,
			case
				when objects.type = ''P'' then ''procedures''
				when objects.type = ''U'' then ''tables''
				when objects.type = ''V'' then ''views''
				when objects.type in (''TF'', ''IF'', ''FN'') then ''functions'' 
				else objects.type 
			end
		from pubs.sys.objects 
			inner join pubs.sys.schemas on schemas.schema_id = objects.schema_id
		where 
			type in (''U'', ''V'', ''P'', ''TF'', ''IF'', ''FN'') 
			and not (type = ''P''	and objects.name like ''dt_%'') --hide ms source safe procedures
		', 'pubs', @database_name)

		exec sp_executesql @sql
		--print @sql
	end
	else
		select @database_id = null
	
end

--select * from #tmpObjects order by database_name, schema_name

declare @results table(
	id varchar(255) primary key,
	parent_id varchar(255),
	display_name varchar(255),		
	full_name varchar(255),
	database_name varchar(255),
	type varchar(255),
	ident int identity)
	
insert into @results(id, parent_id, display_name)
select 
	database_name id,
	'' parent_id,
	database_name
from #tmpObjects
group by database_name
order by database_name

insert into @results(id, parent_id, display_name)
select
	database_name + '.' + schema_name id, 
	database_name parent_id,
	schema_name
from #tmpObjects
group by database_name, schema_name
order by database_name, schema_name

insert into @results(id, parent_id, display_name)
select
	database_name + '.' + schema_name + '.' + type id, 
	database_name + '.' + schema_name parent_id,
	type 
from #tmpObjects
group by database_name, schema_name, type
order by database_name, schema_name, 
	case 
		when type = 'tables' then 0
		when type = 'views' then 1
		when type = 'procedures' then 2
		when type = 'functions' then 3
	else 4
	end

insert into @results(id, parent_id, display_name, full_name, database_name, type)
select
	database_name + '.' + schema_name + '.' + type + '.' + object_name id, 
	database_name + '.' + schema_name + '.' + type parent_id,
	object_name,
	'[' + schema_name + '].[' + object_name + ']' full_name,
	'[' + database_name + ']',
	type		
from #tmpObjects
order by database_name, schema_name, type, object_name

select * from @results order by ident

drop table #tmpObjects 			