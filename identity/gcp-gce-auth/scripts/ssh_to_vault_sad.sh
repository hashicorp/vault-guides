export instance_id=$(terraform output vault_sad_instance_id)
export project_id=$(terraform output project_id)

gcloud compute ssh ${instance_id} --project ${project_id}
