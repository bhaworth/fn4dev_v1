# resource "oci_identity_dynamic_group" "AppDbSrv_DG" {
#   compartment_id = var.tenancy_ocid

#   description   = "Group for App DB Srv in deployment ${local.Fn4_env_name}"
#   # matching_rule = "Any {Any {instance.id = '${local.Fn4AppDb_ids}'}}"
#   name          = "${local.Fn4_env_name}_AppDb"
# }

# resource "oci_identity_policy" "AppDb_Policy" {
#   compartment_id = local.Fn4dev_comp_id

#   description = "Policy for App DB Srv in deployment ${local.Fn4_env_name}"

#   # Need to know what the correct permissions required are  <<CHANGE_ME>>

#   statements = [
#     "Allow dynamic-group ${oci_identity_dynamic_group.AppDbSrv_DG.name} to read all-resources in compartment id ${local.Fn4dev_comp_id}",
#   ]
#   name = "${local.Fn4_env_name}_AppDb"
# }

# resource "oci_identity_policy" "AppDB_Sandbox_Object_Policy" {
#   compartment_id = local.Fn4dev_comp_id

#   description = "Policy for Head Node object read in deployment ${local.Fn4_env_name}"

#   statements = [
#     "Allow dynamic-group ${oci_identity_dynamic_group.AppDbSrv_DG.name} to read objects in compartment id ${local.Fn4dev_comp_id}",
#   ]
#   name = "${local.Fn4_env_name}_AppDB_Object"
# }
# resource "oci_identity_policy" "AppDb_Secrets_Policy" {
#   compartment_id = local.Fn4dev_comp_id

#   description = "Policy for App DB Srv secrets in deployment ${local.Fn4_env_name}"

#   # Need to know what the correct permissions required are  <<CHANGE_ME>>

#   statements = [
#     "Allow dynamic-group ${oci_identity_dynamic_group.AppDbSrv_DG.name} to read secret-family in compartment id ${local.Fn4dev_comp_id}",
#   ]
#   name = "${local.Fn4_env_name}_AppDb_Secrets"
# }

resource "oci_identity_compartment" "Fn4_child_comp" {
  # If 'create child compartment' is true, create a new compartment else don't
  count = var.create_child_comp ? 1 : 0
  enable_delete  = true
  compartment_id = var.compartment_ocid
  description    = "Compartment for the SP3 Cluster with Deployment ID: ${local.Fn4_env_name}"
  name           = "deployment_${local.Fn4_env_name}"
}

locals { 
  # If 'create child compartment' is true, use the new compartment otherwise use the parent
  Fn4_cid = var.create_child_comp ? oci_identity_compartment.Fn4_child_comp[0].id : var.compartment_ocid
}