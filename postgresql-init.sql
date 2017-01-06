\set ON_ERROR_STOP on
CREATE USER hiveuser WITH PASSWORD 'mypassword';
CREATE DATABASE metastore;
\c metastore;
\cd /usr/lib/hive/scripts/metastore/upgrade/postgres/
\i hive-schema-1.1.0.postgres.sql
\c metastore
\pset tuples_only on
\o /tmp/grant-privs
  SELECT 'GRANT SELECT,INSERT,UPDATE,DELETE ON "'  || schemaname || '". "' ||tablename ||'" TO hiveuser ;'
  FROM pg_tables
  WHERE tableowner = CURRENT_USER and schemaname = 'public';
\o
\pset tuples_only off
\i /tmp/grant-privs
