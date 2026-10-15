set echo off
set verify off
set feedback off
set serveroutput on
set define on
whenever sqlerror exit sql.sqlcode rollback

accept gc_app_password char prompt 'GC_APP: 12-30 caracteres, maj/min/chiffre, symbole parmi !@#$%^*_-+=?. : ' hide
accept apex_password char prompt 'APEX hakhalid: 12-30 caracteres, maj/min/chiffre, symbole parmi !@#$%^*_-+=?. : ' hide

alter session set container = ORCLPDB;

declare
  l_schema_password varchar2(30) := '&&gc_app_password';
  l_apex_password varchar2(30) := '&&apex_password';
  l_security_group_id number;
  l_existing_user_count pls_integer;
begin
  if length(l_schema_password) < 12
    or not regexp_like(l_schema_password, '^[A-Za-z0-9!@#$%^*_+=?.-]+$')
     or not regexp_like(l_schema_password, '[A-Z]')
     or not regexp_like(l_schema_password, '[a-z]')
     or not regexp_like(l_schema_password, '[0-9]')
    or not regexp_like(l_schema_password, '[!@#$%^*_+=?.-]') then
    raise_application_error(-20001, 'GC_APP password does not meet the required format.');
  end if;

  if length(l_apex_password) < 12
    or not regexp_like(l_apex_password, '^[A-Za-z0-9!@#$%^*_+=?.-]+$')
     or not regexp_like(l_apex_password, '[A-Z]')
     or not regexp_like(l_apex_password, '[a-z]')
     or not regexp_like(l_apex_password, '[0-9]')
    or not regexp_like(l_apex_password, '[!@#$%^*_+=?.-]') then
    raise_application_error(-20002, 'APEX password does not meet the required format.');
  end if;

  l_security_group_id := apex_util.find_security_group_id(
    p_workspace => 'GESTION_COMMERCIALE'
  );
  if l_security_group_id is null then
    raise_application_error(-20003, 'GESTION_COMMERCIALE workspace was not found.');
  end if;

  select count(*)
    into l_existing_user_count
    from apex_workspace_apex_users
   where workspace_id = l_security_group_id
     and upper(user_name) = 'HAKHALID';
  if l_existing_user_count > 0 then
    raise_application_error(-20004, 'APEX user hakhalid already exists; refusing to overwrite it.');
  end if;

  execute immediate 'alter user GC_APP identified by "' || l_schema_password || '" account unlock';

  apex_util.set_security_group_id(p_security_group_id => l_security_group_id);
  apex_util.create_user(
    p_user_name => 'hakhalid',
    p_email_address => 'hakhalid@gmail.com',
    p_web_password => l_apex_password,
    p_developer_privs => 'ADMIN:CREATE:DATA_LOADER:EDIT:HELP:MONITOR:SQL',
    p_default_schema => 'GC_APP',
    p_allow_access_to_schemas => 'GC_APP',
    p_change_password_on_first_use => 'N',
    p_allow_app_building_yn => 'Y',
    p_allow_sql_workshop_yn => 'Y',
    p_allow_websheet_dev_yn => 'N'
  );

  dbms_output.put_line('GC_APP password updated and APEX developer hakhalid created.');
end;
/

undefine gc_app_password
undefine apex_password
exit success