-- RETIRED SAFETY STUB
--
-- This entrypoint previously selected a fixed database name and then sourced
-- 01_schema.sql, which drops the current M1/M2 tables. That made a copy-paste
-- command capable of resetting an existing database without confirmation.
--
-- Use scripts/ci/mysql-smoke.ps1 with a fresh explicit -DbName instead. To
-- reset an existing disposable database, that script additionally requires
-- the explicit -AllowDestructiveImport switch.

SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = '00_all_in_one.sql is retired; use scripts/ci/mysql-smoke.ps1 with an explicit safe database name';
