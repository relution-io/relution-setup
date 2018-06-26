-- -------------------------------------------------------------------------------------------------
-- SQL script to convert a MariaDB/MySQL database to utf8mb4
-- -------------------------------------------------------------------------------------------------
--
-- UTF-8 on MariaDB/MySQL uses 3-Byte encoding instead of 4-Byte encoding. This means it cannot
-- encode all possible Unicode characters. To fix this, the database needs to be converted to
-- utf8mb4 (4-Byte UTF-8 Unicode Encoding). This script generates the necessary statements to
-- change the character set to utf8mb4 and the collation to utf8mb4_general_ci.
--
-- Instructions:
--
-- 1. Create a database backup, just in case
-- 2. Execute this script
-- 3. Save its output to a new SQL script
-- 4. Execute the generated script
--

USE information_schema;
SELECT "SET SESSION innodb_strict_mode=ON, NAMES 'utf8mb4'
COLLATE 'utf8mb4_general_ci';" as _sql
UNION
SELECT concat("SET foreign_key_checks = 0;") as _sql
UNION
SELECT concat("ALTER DATABASE `",table_schema,"`
CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci;") as _sql
FROM `TABLES` where table_schema like "relution" group by table_schema
UNION
SELECT concat("ALTER TABLE `",table_schema,"`.`",table_name,"`
ENGINE=InnoDB ROW_FORMAT=COMPRESSED;") as _sql
FROM `TABLES` where table_schema like "relution" group by table_schema, table_name
UNION
SELECT concat("ALTER TABLE `",table_schema,"`.`",table_name,"`
CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;") as _sql
FROM `TABLES` where table_schema like "relution" group by table_schema, table_name
UNION
SELECT concat("ALTER TABLE `",table_schema,"`.`",table_name, "`
CHANGE `",column_name,"` `",column_name,"` ",data_type,"(",character_maximum_length,")
CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;") as _sql
FROM `COLUMNS` where table_schema like "relution" and data_type in ('varchar')
UNION
SELECT concat("ALTER TABLE `",table_schema,"`.`",table_name, "`
CHANGE `",column_name,"` `",column_name,"` ",data_type,"
CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;") as _sql
FROM `COLUMNS` where table_schema like "relution"
and data_type in ('text','tinytext','mediumtext','longtext')
UNION
SELECT concat("SET foreign_key_checks = 1;") as _sql;