# EBS Volume cleaner

The script does not automatically delete the EBS volumes it will only show the commands to do it manually.

The algorithm is as follows:
- Gets all the EBS volume ids from the API
- Get all EBS volumes from aws with the tag `kubernetes.io/cluster/$CLUSTER`
- Show the ids of the volumes not found in the kubernetes cluster
- Show the commands to delete the volumes that are not found in the cluster


# How to use this script

1. Login via CLI into the aws account of the cluster

2. Login to the K8S API of the workload cluster you want to check

3. In order to check which EBS volumes should be deleted you have to `./clean_ebs.sh <cluster_id>`

4. Check that the volumes to not exist in the cluster with a command like `kubectl get pv -A -o yaml | grep vol-02df29c83398b7a1b`

5. Delete the volumes executing the commands shown by the script.

# Example output

```
$> ./clean_ebs.sh test1

There are 15 in the cluster test1
There are 17 in the AWS account of cluster test1
The are 2 volumes not present in the kubernetes cluster:
vol-7ad8sdh3322731j22
vol-123578a92se99esae
If you want to delete the volumes execute the following commands:
aws ec2 delete-volume --volume-id vol-7ad8sdh3322731j22
aws ec2 delete-volume --volume-id vol-123578a92se99esae
```