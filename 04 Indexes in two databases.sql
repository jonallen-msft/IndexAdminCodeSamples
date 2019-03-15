/*
Concerning the statement that there are indexes appearing in two databases.

This is not the case. The results supplied are due to a small piece of TSQL syntax missing in 
the query that generated the information.

*/

-- There are a variety of system objects that contain information about indexes in SQL Server.
-- The primary object is [sys].[indexes]
-- This a system view in each and every database on a SQL Server
-- it can be queried as below
select top 3 * from sys.indexes

-- it contains information about all indexes in the current database 
--	(ie the database context that is in use by the current connection)
-- the object_id column is  unique id for each index in that database but 
-- that uniqueness is NOT guaranteed outside the scope of the current database
-- It is wholly possible that an object_id value is used in more than one database on any
-- single SQL Server

-- when working with indexes in SQL Server it is a regular activity to monitor
-- client query usage of indexes, their fragmentation status, or the internal activities taking place within the index
-- this information is recorded by SQL Server in a variety of system object
-- so to gather this information a database administrator will need to query objects such as 
-- [sys].[dm_db_index_operational_stats], [sys].[dm_db_index_physical_stats], and [sys].[dm_db_index_usage_stats]
-- all of these object are STORED IN MSDB and contain information for indexes across the whole SQL Instance
-- and each of them therefore contains the database id for each record so that it is possible to identify where
-- 
-- [sys].[dm_db_index_operational_stats] and [sys].[dm_db_index_physical_stats] are system table valued functions
-- while [sys].[dm_db_index_usage_stats] is a system view

-- the functions need parameters supplied
declare @databaseID int = (select database_id from sys.databases where name = 'adventureworks2016')
select top 10 * from [sys].[dm_db_index_operational_stats](@databaseID, null, null, null)
select top 10 * from [sys].[dm_db_index_physical_stats](@databaseID, null, null, null, null)

-- the view will return results from a simple select statement with no parameters
select top 10 * from [sys].[dm_db_index_usage_stats] 

-- as the two functions need a database id parameter it is important that the right value is used for the 
-- database that we want to work on

-- as [dm_db_index_usage_stats] needs no parameter it will return information about indexes in all 
-- databases by default

-- for these reasons it is very important to pay attention to your current database context by using the 
-- USE <databasename> command when joining their information to data from sys.indexes.
use AdventureWorks2016
go
select * from [sys].[dm_db_index_usage_stats] as ddius
right join sys.indexes as i
on i.object_id = ddius.object_id
and i.index_id = ddius.index_id