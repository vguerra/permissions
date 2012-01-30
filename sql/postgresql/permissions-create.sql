-- Using recursivity for checking permissions
-- Victor Guerra (vguerra@wu.ac.at)
-- TODO: All of the triggers for fedding the binary tables are missing

-- the context binary table --
-- AT THE MOMENT WE AVOID THE USAGE OF THIS context_binary TABLE ---
-- WHICH SAVE US FROM HAVING TRIGGERS ON ACS_OBJECTS FOR UPDATING SUCH TABLE --

-- drop table if exists context_binary;
-- create table context_binary (
--        context_id integer constraint context_binary_context_id_fk
--                   references acs_objects(object_id),
--        object_id  integer constraint context_binary_context_id_fk
--                   references acs_objects(object_id)
-- );

-- create unique index context_binary__context_id_object_id_idx on context_binary (context_id, object_id);
-- create index context_binary__object_id_idx on context_binary(object_id);

-- insert into context_binary select CASE WHEN security_inherit_p = 'f' THEN acs__magic_object_id('security_context_root') 
--         WHEN security_inherit_p = 't' THEN COALESCE(context_id, acs__magic_object_id('security_context_root'))
--         END as context_id , object_id from acs_objects;

-- delete from context_binary where object_id = acs__magic_object_id('security_context_root');

-- create or replace function acs_objects_context_id_in_tr () returns trigger as $$
-- declare
--         security_context_root integer;
-- begin
--   if new.context_id is not null and new.security_inherit_p = 't' then
--     insert into context_binary
--      (new.ancestor_id, new.object_id)
--   else
--     security_context_root = acs__magic_object_id('security_context_root');
--     if new.object_id != security_context_root then
--       insert into acs_object_context_index
--         (object_id, ancestor_id, n_generations)
--       values
--         (security_context_root, new.object_id);
--     end if;
--   end if;

--   return new;

-- end; $$ language plpgsql;

-- create trigger acs_objects_context_id_in_tr after insert on acs_objects
-- for each row execute procedure acs_objects_context_id_in_tr ();

-- create or replace function acs_objects_context_id_up_tr () returns trigger as $$
-- declare
--         security_context_root integer;
-- begin
--   if new.object_id = old.object_id
--      and ((new.context_id = old.context_id)
--       or (new.context_id is null and old.context_id is null))
--      and new.security_inherit_p = old.security_inherit_p then
--     return new;
--   end if;

--   -- Kill all my old ancestors.
--   delete from context_binary
--   where object_id = old.object_id;

--   if new.context_id is not null and new.security_inherit_p = ''t'' then
--     insert into context_binary
--      (new.ancestor_id, new.object_id)
--   else
--     security_context_root = acs__magic_object_id(''security_context_root'');
--     if new.object_id != security_context_root then
--       insert into acs_object_context_index
--         (object_id, ancestor_id, n_generations)
--       values
--         (security_context_root, new.object_id);
--     end if;
--   end if;

--   return new;

-- end; $$ language plpgsql;

-- create trigger acs_objects_context_id_up_tr after update on acs_objects
-- for each row execute procedure acs_objects_context_id_up_tr ();



-- the parties table --
-- drop table if exists parties_binary;
-- create table parties_binary (
--        party_id     integer constraint parties_binary_party_id_fk
--                     references parties(party_id),
--        member_id    integer constraint parties_binary_member_id_fk
--                     references parties(party_id)
-- );

-- create unique index parties_binary__party_id_member_id_idx on parties_binary (party_id, member_id);
-- create index parties_binary__party_id_idx on parties_binary(party_id);

-- insert into parties_binary (select group_id , component_id as member_id from group_component_map
--     UNION
--     select group_id, member_id from group_approved_member_map where container_id = group_id);





-- create or replace function acs_permission__permission_p_recursive (a_object_id integer, a_party_id integer, a_privilege varchar)
-- returns boolean as $$
-- begin
--     return exists (With RECURSIVE member_ancestors(party_id, member_id) AS (
--         SELECT a_party_id, a_party_id from dual
--            Union ALL
--            SELECT pb.party_id, pb.member_id
--            FROM member_ancestors ma JOIN parties_binary pb
--            ON pb.member_id = ma.party_id
--         ), object_context(object_id, context_id) AS (
--            SELECT a_object_id, a_object_id from dual
--            Union ALL
--            SELECT cb.object_id, cb.context_id
--            FROM object_context oc JOIN context_binary cb 
--            ON cb.object_id = oc.context_id 
--         ), privilege_ancestors(privilege, child_privilege) AS (
--            SELECT a_privilege, a_privilege from dual
--            Union ALL
--              SELECT aph.privilege, aph.child_privilege
--              FROM privilege_ancestors pa JOIN acs_privilege_hierarchy aph
--              ON aph.child_privilege = pa.privilege
--         ) SELECT
--           1
--           FROM
--           acs_permissions p
--           join  member_ancestors ma on ma.party_id   =  p.grantee_id
--           join  privilege_ancestors pa  on  pa.privilege  =  p.privilege
--           join  object_context oc on  p.object_id =  oc.context_id
--           limit 1
--         );
--  end; $$ language plpgsql stable;

-- create or replace function acs_permission__permission_p_recursive2 (a_object_id integer, a_party_id integer, a_privilege varchar)
-- returns boolean as $$
-- begin
--     return exists (With RECURSIVE member_ancestors(party_id, member_id) AS (
--         SELECT a_party_id, a_party_id from dual
--            Union ALL
--            SELECT pb.party_id, pb.member_id
--            FROM member_ancestors ma JOIN parties_binary pb
--            ON pb.member_id = ma.party_id
--         ), object_context(object_id, context_id) AS (
--             SELECT a_object_id, a_object_id from dual
--             Union ALL
--                 SELECT ao.object_id, 
--                 CASE WHEN ao.security_inherit_p = 'f' THEN acs__magic_object_id('security_context_root')
--                 ELSE ao.context_id END
--                 FROM object_context oc, acs_objects ao
--                 where ao.object_id = oc.context_id
--                 and ao.object_id != acs__magic_object_id('security_context_root')
--         ), privilege_ancestors(privilege, child_privilege) AS (
--            SELECT a_privilege, a_privilege from dual
--            Union ALL
--              SELECT aph.privilege, aph.child_privilege
--              FROM privilege_ancestors pa JOIN acs_privilege_hierarchy aph
--              ON aph.child_privilege = pa.privilege
--         ) SELECT
--           1
--           FROM
--           acs_permissions p
--           join  member_ancestors ma on ma.party_id   =  p.grantee_id
--           join  privilege_ancestors pa  on  pa.privilege  =  p.privilege
--           join  object_context oc on  p.object_id =  oc.context_id
--           limit 1
--         );
--  end; $$ language plpgsql stable;


-- This version does not use the binary tables but gets
-- the info out of the existing tables. It would have been difficult
-- to add triggers to the group managment model in order to get info 
-- that we might be needed. 

select define_function_args('acs_permission__permission_p_recursive','a_object_id,a_party_id,a_privilege');

-- create or replace function acs_permission__permission_p_recursive(a_object_id integer, a_party_id integer, a_privilege varchar)
-- returns boolean as $$
-- begin
--     return exists (With RECURSIVE member_ancestors(party_id, member_id) AS (
--         SELECT a_party_id, a_party_id
--         Union ALL
--             SELECT gm.group_id, gm.member_id from
--             group_approved_member_map gm, member_ancestors ma
--             where ma.party_id = gm.member_id
--         ), object_context(object_id, context_id) AS (
--             SELECT a_object_id, a_object_id
--             Union ALL
--                 SELECT ao.object_id,
--                 CASE WHEN (ao.security_inherit_p = 'f' or ao.context_id is null)  THEN acs__magic_object_id('security_context_root')
--                 ELSE ao.context_id END
--                 FROM object_context oc, acs_objects ao
--                 where ao.object_id = oc.context_id
--                 and ao.object_id != acs__magic_object_id('security_context_root')
--         ), privilege_ancestors(privilege, child_privilege) AS (
--            SELECT a_privilege, a_privilege
--            Union ALL
--              SELECT aph.privilege, aph.child_privilege
--              FROM privilege_ancestors pa JOIN acs_privilege_hierarchy aph
--              ON aph.child_privilege = pa.privilege
--         ) SELECT
--           1
--           FROM
--           acs_permissions p
--           join  member_ancestors ma on ma.party_id   =  p.grantee_id
--           join  privilege_ancestors pa  on  pa.privilege  =  p.privilege
--           join  object_context oc on  p.object_id =  oc.context_id
--         );
--  end; $$ language plpgsql stable;

create or replace function acs_permission__permission_p_recursive(a_object_id integer, a_party_id integer, a_privilege varchar)
returns boolean as $$
begin
    return exists (With RECURSIVE object_context(object_id, context_id) AS (
            SELECT a_object_id, a_object_id
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

-- create or replace function acs_permission__permission_p_recursive_array(a_objects integer[],a_party_id integer, a_privilege varchar)
-- returns table (object_id integer, orig_object_id integer) as $$
-- begin
--     return query With RECURSIVE member_ancestors(party_id, member_id) AS (
--         SELECT a_party_id, a_party_id
--         Union ALL
--             SELECT gm.group_id, gm.member_id from
--             group_approved_member_map gm, member_ancestors ma
--             where ma.party_id = gm.member_id
--         ), object_context(object_id, context_id, orig_object_id) AS (
--             SELECT unnest(a_objects), unnest(a_objects), unnest(a_objects)
--             Union ALL
--                 SELECT ao.object_id,
--                 CASE WHEN (ao.security_inherit_p = 'f' or ao.context_id is null)  THEN acs__magic_object_id('security_context_root')
--                 ELSE ao.context_id END, oc.orig_object_id
--                 FROM object_context oc, acs_objects ao
--                 where ao.object_id = oc.context_id
--                 and ao.object_id != acs__magic_object_id('security_context_root')
--         ), privilege_ancestors(privilege, child_privilege) AS (
--            SELECT a_privilege, a_privilege
--            Union ALL
--              SELECT aph.privilege, aph.child_privilege
--              FROM privilege_ancestors pa JOIN acs_privilege_hierarchy aph
--              ON aph.child_privilege = pa.privilege
--         ) SELECT
--           p.object_id, oc.orig_object_id
--           FROM
--           acs_permissions p
--           join  member_ancestors ma on ma.party_id   =  p.grantee_id
--           join  privilege_ancestors pa  on  pa.privilege  =  p.privilege
--           join  object_context oc on  p.object_id =  oc.context_id
--       ;
--  end; $$ language plpgsql stable;

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
