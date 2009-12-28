insert into @results([database], [type], [schema], [name])
	select 
		db_name() [database],
		case when type in ('TF', 'IF', 'FN') then 'functions'
			when type in ('P') then 'procedures'
			when type in ('V') then 'views'
			when type in ('U') then 'tables'
			else '???'
		end type,
		s.name [schema],
		o.name
	from sys.objects o
	inner join sys.schemas s on o.schema_id = s.schema_id
	where 
		type in ( 'TF', 'IF', 'FN', 'P', 'V', 'U') 
		and is_ms_shipped = 0
	order by 
		case when o.schema_id = 1 then 0 else 1 end, --prvo dbo schema
		case when type in ('TF', 'IF', 'FN') then 4
			when type in ('P') then 3
			when type in ('V') then 2
			when type in ('U') then 1
			else '???'
		end,		
		s.name, o.name