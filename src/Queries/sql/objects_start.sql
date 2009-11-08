declare @results table(
	id varchar(255) primary key,
	parent_id varchar(255),
	name varchar(255),		
	type varchar(2),
	ident int identity)

declare @section_name varchar(255)	