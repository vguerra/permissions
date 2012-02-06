ad_library {

    Tcl procs for the acs permissioning system.

    @author vguerras@wu.ac.at
    @creation-date 2011-07-12
    @cvs-id $Id$

}

namespace eval permissions {}

ad_proc -private permissions::permission_p_not_cached_recursive {
    {-no_cache:boolean}
    {-party_id ""}
    {-object_id:required}
    {-privilege:required}
} {
    does party X have privilege Y on object Z
    
    @see permission::permission_p
} {
    #ns_log Warning "PERMISSIONS RECURSIVE: -no_cache:$no_cache_p -party_id $party_id -object_id $object_id -privilege $privilege"
    if { $party_id eq "" } {
        set party_id [ad_conn user_id]
    }
    
    # We have a thread-local cache here
    global permission__permission_p__cache
    if { ![info exists permission__permission_p__cache($party_id,$object_id,$privilege)] } {
        set permission__permission_p__cache($party_id,$object_id,$privilege) [expr {[db_string select_permission_p {}] ? 1 : 0}]
    }
    return $permission__permission_p__cache($party_id,$object_id,$privilege)
}

namespace eval dotlrn {}

# ad_proc -public dotlrn::toggle_can_browse {
#     {-user_id:required}
#     {-can_browse:boolean}
# } {
#         sets whether a user can browse communities
# } {
#     set browsing_group_id [group::get_id -group_name "dotlrn-browsing"]
#     if {$can_browse_p} {
#            group::add_member -group_id $browsing_group_id \
#                -user_id $user_id
#     } else {
#           # we should probably just change the state of the relation here
#           group::remove_member -group_id $browsing_group_id \
#               -user_id $user_id
#       }
# }

