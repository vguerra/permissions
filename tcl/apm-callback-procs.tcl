ad_library {

    Tcl procs for the acs permissioning system.

    @author vguerra@wu.ac.at
    @creation-date 2011-07-12
    @cvs-id $Id$

}

namespace eval permissions {}

ad_proc -private permissions::package_install {} {
    
    Every .LRN user when created gets dotlrn_browse permission, 
    that means one entry per .LRN user in acs_permissions. 
    
    Therefore we revoke all those individual permissions and 
    create a group that contains all the .LRN users that 
    can browse. This means the group has direct permissions
    of dotlrn_browse on the dotlrn package id. 
    
} {
    if {[set group_id [group::get_id -group_name dotlrn-browsing]] eq ""} {
        set group_id [group::new -group_name dotlrn-browsing]
    }
    set dotlrn_pkg_id [dotlrn::get_package_id]
    
    db_transaction {
        db_list migrate_dotlrn_users {
            select membership_rel__new(:group_id, s.grantee_id) from 
            ( select grantee_id 
              from acs_permissions 
              where object_id = :dotlrn_pkg_id
              and privilege = 'dotlrn_browse' 
              and grantee_id not in 
              ( select member_id from group_approved_member_map where group_id = :group_id )
              ) as s 
        }
        
        db_dml delete_privileges {delete from acs_permissions where object_id = :dotlrn_pkg_id and privilege = 'dotlrn_browse'}
        
        permission::grant -party_id $group_id \
            -object_id [dotlrn::get_package_id] -privilege dotlrn_browse
        
    } 
}
