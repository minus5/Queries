insert into @results([database], [type], [schema], [name], [parent_name])
	select 
		db_name() [database],
		case when o.type in ('TF', 'IF', 'FN') then 'functions'
			when o.type in ('P') then 'procedures'
			when o.type in ('V') then 'views'
			when o.type in ('U') then 'tables'
			when o.type in ('TR') then 'triggers'
			else '???'
		end type,
		s.name [schema],
		o.name,
		coalesce(po.name, '') parent_name
	from sys.objects o
	inner join sys.schemas s on o.schema_id = s.schema_id
	left outer join sys.objects po on po.object_id = o.parent_object_id
	where 
		o.type in ( 'TF', 'IF', 'FN', 'P', 'V', 'U', 'TR') 
		and o.is_ms_shipped = 0
	order by 
		case when o.schema_id = 1 then 0 else 1 end, --prvo dbo schema
		case when o.type in ('TF', 'IF', 'FN') then 4
			when o.type in ('P') then 3
			when o.type in ('V') then 2
			when o.type in ('U') then 1
			else 100
		end,		
		s.name, o.name
