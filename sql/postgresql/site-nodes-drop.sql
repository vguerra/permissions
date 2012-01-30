-- Using recursivity for some site_nodes functionality
-- Victor Guerra (vguerra@wu.ac.at)

drop function if exists site_node__url(integer);
alter function site_node__url_old(integer) rename to site_node__url;
drop function if exists site_node__url_recursive(integer);
