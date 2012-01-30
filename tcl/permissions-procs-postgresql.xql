<?xml version="1.0"?>

<queryset>
    <fullquery name="permissions::permission_p_not_cached_recursive.select_permission_p">
        <querytext>
	select acs_permission__permission_p_recursive(:object_id, :party_id, :privilege) from dual
        </querytext>
    </fullquery>

</queryset>
