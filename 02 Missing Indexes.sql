
--------------------------------------------------------------------------------
-- MISSING INDEXES
-- gathering together details on missing indexes from all the missing index dmvs
USE AdventureWorks2014
GO

SELECT 
	--left(dmid.[statement], patindex('%.%', dmid.[statement])-1) as DBName,
	SUBSTRING(dmid.[statement], patindex('%.%', dmid.[statement])+1, 99) as Tablename,
	--dmid.[statement],
	dmigs.group_handle AS [Index Group],
	dmid.equality_columns,
	dmid.inequality_columns,
	dmid.included_columns,
	dmigs.unique_compiles,
	dmigs.user_seeks,
	dmigs.user_scans,
	dmigs.avg_total_user_cost,
	dmigs.avg_user_impact,
	cast(dmigs.avg_user_impact * dmigs.unique_compiles as INT) AS [benefit] -- used to indicate relative potential value of index
FROM sys.dm_db_missing_index_details AS dmid
INNER JOIN sys.dm_db_missing_index_groups AS dmig ON dmid.index_handle = dmig.index_handle
INNER JOIN sys.dm_db_missing_index_group_stats AS dmigs ON dmig.index_group_handle = dmigs.group_handle
--cross apply sys.dm_db_missing_index_columns(dmid.index_handle) as dmic
where dmid.database_id = DB_ID()
ORDER BY benefit DESC;
go

--	drop index pto_IX_ProductID on adventureworks2014.sales.salesorderdetail
create index pto_IX_ProductID 
on adventureworks2014.sales.salesorderdetail (productid)


-- review usage of the new index
SELECT TOP 100 object_schema_name(ddius.object_id) + '.' + OBJECT_NAME(ddius.object_id) AS [table_name],
	isnull(i.name,'HEAP') as Indexname,
	ddius.index_id,
	ddius.user_seeks,
	ddius.user_scans,
	ddius.user_lookups,
	ddius.user_updates,
	ddius.last_user_seek,
	ddius.last_user_scan,
	ddius.last_user_lookup,
	ddius.last_user_update
FROM sys.dm_db_index_usage_stats AS ddius
inner join  sys.indexes as i 
	on ddius.object_id = i.object_id 
	and ddius.index_id = i.index_id
where i.name in ( 'pto_IX', 'IX_PTO2')

--	drop index pto_IX_OrderQty on adventureworks2012.sales.salesorderdetail 
create index pto_IX_OrderQty 
on adventureworks2012.sales.salesorderdetail 
(OrderQty)
include ([ProductID], unitprice);

-- review usage of the new index
SELECT TOP 100 object_schema_name(ddius.object_id) + '.' + OBJECT_NAME(ddius.object_id) AS [table_name],
	isnull(i.name,'HEAP') as Indexname,
	ddius.index_id,
	ddius.user_seeks,
	ddius.user_scans,
	ddius.user_lookups,
	ddius.user_updates,
	ddius.last_user_seek,
	ddius.last_user_scan,
	ddius.last_user_lookup,
	ddius.last_user_update
FROM sys.dm_db_index_usage_stats AS ddius
inner join  sys.indexes as i 
	on ddius.object_id = i.object_id 
	and ddius.index_id = i.index_id
where i.name = 'pto_IX_UnitPrice'
or i.name = 'pto_IX_OrderQty';

-- what indexes are missing?
SELECT dmid.[statement],
	dmigs.group_handle AS [Index Group],
	dmid.equality_columns,
	dmid.inequality_columns,
	dmid.included_columns,
	dmigs.unique_compiles,
	dmigs.user_seeks,
	dmigs.user_scans,
	dmigs.avg_total_user_cost,
	dmigs.avg_user_impact,
	cast(dmigs.avg_user_impact * dmigs.unique_compiles as INT) AS [benefit] -- used to indicate relative potential value of index
FROM sys.dm_db_missing_index_details AS dmid
INNER JOIN sys.dm_db_missing_index_groups AS dmig ON dmid.index_handle = dmig.index_handle
INNER JOIN sys.dm_db_missing_index_group_stats AS dmigs ON dmig.index_group_handle = dmigs.group_handle
--cross apply sys.dm_db_missing_index_columns(dmid.index_handle) as dmic
ORDER BY benefit DESC;


-- how useful is the new index? Look for seeks more than scans...
SELECT TOP 100 object_schema_name(ddius.object_id) + '.' + OBJECT_NAME(ddius.object_id) AS [table_name],
	isnull(i.name,'HEAP') as Indexname,
	ddius.index_id,
	ddius.user_seeks,
	ddius.user_scans,
	ddius.user_lookups,
	ddius.user_updates,
	ddius.last_user_seek,
	ddius.last_user_scan,
	ddius.last_user_lookup,
	ddius.last_user_update
FROM sys.dm_db_index_usage_stats AS ddius
inner join  sys.indexes as i 
	on ddius.object_id = i.object_id 
	and ddius.index_id = i.index_id
where i.name = 'pto_IX_UnitPrice'
or i.name = 'pto_IX_OrderQty';


go

drop index pto_IX_UnitPrice 
on adventureworks2012.sales.salesorderdetail;
go

drop index pto_IX_OrderQty 
on adventureworks2012.sales.salesorderdetail;
go
