# <set_variables>
export PROFILER_COMPUTE_NAME="${PROFILER_COMPUTE_NAME}" # the compute name for hosting the profiler
export PROFILER_COMPUTE_SIZE="${PROFILER_COMPUTE_SIZE}" # the compute size for hosting the profiler
# </set_variables>

# <create_compute_cluster_for_hosting_the_profiler>
echo "Creating Compute $PROFILER_COMPUTE_NAME ..."
az ml compute create --name $PROFILER_COMPUTE_NAME --size $PROFILER_COMPUTE_SIZE --identity-type SystemAssigned --type amlcompute

# check compute status
compute_status=`az ml compute show --name $PROFILER_COMPUTE_NAME --query "provisioning_state" -o tsv`
echo $compute_status
if [[ $compute_status == "Succeeded" ]]; then
  echo "Compute $PROFILER_COMPUTE_NAME created successfully"
else 
  echo "Compute $PROFILER_COMPUTE_NAME creation failed"
  exit 1
fi

# create role assignment for acessing workspace resources
compute_resource_id=`az ml compute show --name $PROFILER_COMPUTE_NAME --query id -o tsv`
workspace_resource_id=`echo $compute_resource_id | sed 's/\(.*\)\/computes\/.*/\1/'`
access_token=`az account get-access-token --query accessToken -o tsv`
compute_info=`curl https://management.azure.com$compute_resource_id?api-version=2021-03-01-preview -H "Content-Type: application/json" -H "Authorization: Bearer $access_token"`
if [[ $? -ne 0 ]]; then echo "Failed to get info for compute $PROFILER_COMPUTE_NAME" && exit 1; fi
identity_object_id=`echo $compute_info | jq '.identity.principalId' | sed "s/\"//g"`
az role assignment create --role Contributor --assignee-object-id $identity_object_id --scope $workspace_resource_id
if [[ $? -ne 0 ]]; then echo "Failed to create role assignment for compute $PROFILER_COMPUTE_NAME" && exit 1; fi
# </create_compute_cluster_for_hosting_the_profiler>