--// This Sample Code is provided for the purpose of illustration only and is not intended 
--// to be used in a production environment.
--// THIS SAMPLE CODE AND ANY RELATED INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND,
--// EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF 
--// MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.
--// We grant You a non-exclusive, royalty-free right to use and modify the Sample Code and 
--// to reproduce and distribute the object code form of the Sample Code, provided that You agree:
--// (i) to not use Our name, logo, or trademarks to market Your software product in which 
--// the Sample Code is embedded;
--// (ii) to include a valid copyright notice on Your software product in which the Sample Code is embedded;
--// (iii) to indemnify, hold harmless, and defend Us and Our suppliers from and against any claims or lawsuits,
--// including attorney's fees, that arise or result from the use or distribution of the Sample
--// Code.
--// Please note: None of the conditions outlined in the disclaimer above will supersede the terms and
--// conditions contained within the Premier Customer Services Description.

-- demo workload from C:\Users\jonallen\OneDrive - Microsoft\Documents\SQL Server Management Studio\Workload.ps1
USE AdventureWorks2014
GO


-- index stats
--***************
-- index usage stats - what indexes are queries using and 
-- how are they being used?
SELECT *
FROM sys.dm_db_index_usage_stats AS ddius
WHERE ddius.database_id = db_id();

-- 1154103152




SELECT TOP 100 
object_schema_name(ddius.object_id) + '.' + OBJECT_NAME(ddius.object_id) AS [table_name],
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
right join  sys.indexes as i 
	on ddius.object_id = i.object_id 
	and ddius.index_id = i.index_id

WHERE ddius.database_id = db_id() 

	AND (user_seeks + user_scans + user_lookups) < 100
	--AND 	user_updates > 0
ORDER BY user_seeks + user_scans + user_lookups DESC;







-- how the indexes are being used to respond to queries
SELECT object_name(ddios.[object_id]) as [object_name],
	ddios.*
FROM sys.dm_db_index_operational_stats(db_id(), NULL, NULL, NULL) as ddios
where object_id > 5000




-- index physical condition
-- LIMITED, SAMPLED and DETAILED are options. read the help about the way they work. they have a different hit to performance, especially on big indexes
SELECT ddips.* 
FROM sys.dm_db_index_physical_stats(db_id(), NULL, NULL, NULL, 'SAMPLED') as ddips
order by avg_fragmentation_in_percent desc


SELECT 
	db_name(ddips.database_id ) as DBName, 
	object_schema_name(ddips.object_id) + '.' + object_name(ddips.object_id) as Tablename, 
	i.name,
	ddips.index_type_desc,
	ddips.avg_fragmentation_in_percent as [Frag pct],
	ddips.avg_page_space_used_in_percent as [page used pct]
FROM sys.dm_db_index_physical_stats(db_id(), NULL, NULL, NULL, 'SAMPLED') as ddips
inner join sys.indexes as i
on i.object_id = ddips.object_id
and i.index_id = ddips.index_id
where ddips.page_count > 5
and ddips.avg_fragmentation_in_percent > 60
order by avg_fragmentation_in_percent desc;




