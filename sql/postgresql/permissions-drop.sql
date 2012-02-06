drop function if exists acs_permission__permission_p(integer,integer,varchar);
alter function acs_permission__permission_p_old(integer,integer,varchar) rename to acs_permission__permission_p;
drop function if exists acs_permission__permission_p_recursive(a_object_id integer, a_party_id integer, a_privilege varchar);

\i site-nodes-drop.sql 