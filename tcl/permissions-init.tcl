# Here we rewrite the body of dotlrn::set_can_browse

#rename ::dotlrn::set_can_browse ::dotlrn::set_can_browse_old

ad_proc -public dotlrn::set_can_browse {
    {-user_id ""}
    {-can_browse:boolean}
} {
    sets whether a user can browse communities
} {
    eval dotlrn::toggle_can_browse -user_id $user_id [expr {$can_browse_p ? "-can_browse" : ""}]
}


#rename ::permission::permission_p_not_cached ::permission::permission_p_not_cached_old

ad_proc -private permission::permission_p_not_cached {
    {-no_cache:boolean}
    {-party_id ""}
    {-object_id:required}
    {-privilege:required}
} {
    does party X have privilege Y on object Z
    
    @see permission::permission_p
} {
    if {$no_cache_p} {
	return [permissions::permission_p_not_cached_recursive -no_cache -party_id $party_id \
		    -object_id $object_id -privilege $privilege]
    } else {
	return [permissions::permission_p_not_cached_recursive -party_id $party_id \
		    -object_id $object_id -privilege $privilege]
    }
}
