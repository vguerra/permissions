-- Using recursivity for some site_nodes functionality
-- Victor Guerra (vguerra@wu.ac.at)

select define_function_args('site_node__url_recursive','node_id');

create or replace function site_node__url_recursive(a_node_id integer)
returns varchar as $$
begin
    return ( With RECURSIVE site_nodes_recursion(parent_id, path, directory_p, node_id) as (
    select parent_id, ARRAY[name || CASE WHEN directory_p THEN '/' ELSE ' ' END]::text[] as path, directory_p, node_id
    from site_nodes where node_id = a_node_id
    UNION ALL
    select sn.parent_id, sn.name::text || snr.path , sn.directory_p, snr.parent_id
    from site_nodes sn join site_nodes_recursion snr on sn.node_id = snr.parent_id 
    where snr.parent_id is not null    
    ) select array_to_string(path,'/') from site_nodes_recursion where parent_id is null
);
end; $$ language plpgsql stable; 

alter function site_node__url(integer) rename to site_node__url_old;

select define_function_args('site_node__url','node_id');

create or replace function site_node__url(node_id integer)
returns varchar as $$
begin   
    return site_node__url_recursive(node_id);
end; $$ language plpgsql stable;
