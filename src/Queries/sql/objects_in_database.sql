--root		
insert into @results(id, parent_id, name)
select db_name(), '', db_name()
           
--tables
set @section_name = 'tables'
insert into @results(id, parent_id, name, type)
	select db_name() + '.' + @section_name + '.' + s.name + '.' + o.name name, db_name() + '.' + @section_name, s.name + '.' + o.name name, type 
	from sys.tables o
	inner join sys.schemas s on o.schema_id = s.schema_id
	where is_ms_shipped = 0
	order by case when o.schema_id = 1 then 0 else 1 end, s.name, o.name 
if @@rowcount > 0                        
	insert into @results(id, parent_id, name) 
	select db_name() + '.' + @section_name, db_name(), @section_name 

--views
set @section_name = 'views'
insert into @results(id, parent_id, name, type)
	select db_name() + '.' + @section_name + '.' + s.name + '.' + o.name, db_name() + '.' + @section_name, s.name + '.' + o.name, type 
	from sys.views o
	inner join sys.schemas s on o.schema_id = s.schema_id
	where is_ms_shipped = 0
	order by case when o.schema_id = 1 then 0 else 1 end, s.name, o.name 
if @@rowcount > 0                        
	insert into @results(id, parent_id, name) 
	select db_name() + '.' + @section_name, db_name(), @section_name

--procedures
set @section_name = 'procedures'
insert into @results(id, parent_id, name, type)
	select db_name() + '.' + @section_name + '.' + s.name + '.' + o.name, db_name() + '.' + @section_name, s.name + '.' + o.name, type 
	from sys.procedures o
	inner join sys.schemas s on o.schema_id = s.schema_id
	where is_ms_shipped = 0
	order by case when o.schema_id = 1 then 0 else 1 end, s.name, o.name 
if @@rowcount > 0                        
	insert into @results(id, parent_id, name) 
	select db_name() + '.' + @section_name, db_name(), @section_name 

--functions   
set @section_name = 'functions'
insert into @results(id, parent_id, name, type)
	select db_name() + '.' + @section_name + '.' + s.name + '.' + o.name, db_name() + '.' + @section_name, s.name + '.' + o.name, type
	from sys.objects o
	inner join sys.schemas s on o.schema_id = s.schema_id
	where 
		type in ( 'TF', 'IF', 'FN') 
	order by case when o.schema_id = 1 then 0 else 1 end, s.name, o.name       
if @@rowcount > 0                        
	insert into @results(id, parent_id, name) 
	select db_name() + '.' + @section_name, db_name(), @section_name

--users
set @section_name = 'users'   
insert into @results(id, parent_id, name, type)
	select db_name() + '.' + @section_name+ '.' + name, db_name() + '.' + @section_name, name, type	
	from sys.database_principals
	where principal_id > 4 and type in ('G', 'S', 'U') 
	order by name    
if @@rowcount > 0                        
	insert into @results(id, parent_id, name) 
	select db_name() + '.' + @section_name, db_name(), @section_name	