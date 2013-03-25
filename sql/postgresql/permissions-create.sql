-- Using recursivity for checking permissions
-- Victor Guerra (vguerra@wu.ac.at)

select define_function_args('acs_permission__permission_p_recursive','a_object_id,a_party_id,a_privilege');

create or replace function acs_permission__permission_p_recursive(a_object_id integer, a_party_id integer, a_privilege varchar)
returns boolean as $$
begin
    return exists (With RECURSIVE object_context(object_id, context_id) AS (
            SELECT a_object_id, a_object_id from acs_objects where object_id = a_object_id
            Union ALL
                SELECT ao.object_id,
                CASE WHEN (ao.security_inherit_p = 'f' or ao.context_id is null)  THEN acs__magic_object_id('security_context_root')
                ELSE ao.context_id END
                FROM object_context oc, acs_objects ao
                where ao.object_id = oc.context_id
                and ao.object_id != acs__magic_object_id('security_context_root')
        ), privilege_ancestors(privilege, child_privilege) AS (
           SELECT a_privilege, a_privilege
           Union ALL
             SELECT aph.privilege, aph.child_privilege
             FROM privilege_ancestors pa JOIN acs_privilege_hierarchy aph
             ON aph.child_privilege = pa.privilege
        ) SELECT
          1
          FROM
          acs_permissions p
          join  party_approved_member_map pap on pap.party_id   =  p.grantee_id
          join  privilege_ancestors pa  on  pa.privilege  =  p.privilege
          join  object_context oc on  p.object_id =  oc.context_id	
	  where pap.member_id = a_party_id
        );
 end; $$ language plpgsql stable;


-- now we rename the original acs_permission__permission_p

alter function acs_permission__permission_p(integer,integer,varchar) rename to acs_permission__permission_p_old;

create or replace function acs_permission__permission_p(a_object_id integer, a_party_id integer, a_privilege varchar)
returns boolean as $$
begin   
    return acs_permission__permission_p_recursive(a_object_id, a_party_id, a_privilege);
end; $$ language plpgsql stable;


-- for tsearch

select define_function_args('acs_permission__permission_p_recursive_array','a_objects,a_party_id,a_privilege');

create or replace function acs_permission__permission_p_recursive_array(a_objects integer[],a_party_id integer, a_privilege varchar)
returns table (object_id integer, orig_object_id integer) as $$
begin
    return query With RECURSIVE object_context(object_id, context_id, orig_object_id) AS (
            SELECT unnest(a_objects), unnest(a_objects), unnest(a_objects)
            Union ALL
                SELECT ao.object_id,
                CASE WHEN (ao.security_inherit_p = 'f' or ao.context_id is null)  THEN acs__magic_object_id('security_context_root')
                ELSE ao.context_id END, oc.orig_object_id
                FROM object_context oc, acs_objects ao
                where ao.object_id = oc.context_id
                and ao.object_id != acs__magic_object_id('security_context_root')
        ), privilege_ancestors(privilege, child_privilege) AS (
           SELECT a_privilege, a_privilege
           Union ALL
             SELECT aph.privilege, aph.child_privilege
             FROM privilege_ancestors pa JOIN acs_privilege_hierarchy aph
             ON aph.child_privilege = pa.privilege
        ) SELECT
          p.object_id, oc.orig_object_id
          FROM
          acs_permissions p
          join  party_approved_member_map pap on pap.party_id   =  p.grantee_id
          join  privilege_ancestors pa  on  pa.privilege  =  p.privilege
          join  object_context oc on  p.object_id =  oc.context_id
	  where pap.member_id = a_party_id
      ;
 end; $$ language plpgsql stable;


-- some recursive site_nodes functions
\i site-nodes-create.sql