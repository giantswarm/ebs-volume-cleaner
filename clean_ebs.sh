#!/bin/bash

CLUSTER=$1

volumesInCluster=$(kubectl --context gs-anteater-$CLUSTER get pv -A -o json | jq '.items[] | select((.spec.csi.volumeHandle !=null) and (.spec.csi.volumeHandle | test("vol-"))).spec.csi.volumeHandle' -r | tr ' ' '\n' |  sort | uniq -u)
volumesInCluster2=$(kubectl --context gs-anteater-$CLUSTER get pv -A -o json | jq '.items[] | select((.spec.awsElasticBlockStore.volumeID !=null) and (.spec.awsElasticBlockStore.volumeID | test("vol-"))).spec.awsElasticBlockStore.volumeID' -r | tr ' ' '\n' | sort | uniq -u | grep -o 'vol-.*')

volumesInCluster_amount=$(echo $volumesInCluster | tr ' ' '\n' | wc -l)
volumesInCluster2_amount=$(echo $volumesInCluster2 | tr ' ' '\n' | wc -l)
total_incluster=$((volumesInCluster_amount + volumesInCluster2_amount))

etcdVolumesInAws=$(aws ec2 describe-volumes --no-paginate --filters=Name=tag:kubernetes.io/cluster/$CLUSTER,Values=owned --filters=Name=tag:aws:cloudformation:stack-name,Values=cluster-$CLUSTER-tccpn --query "Volumes[*].{ID:VolumeId}" | jq .[].ID -r | sort | uniq -u)

volumesInAws=$(aws ec2 describe-volumes --no-paginate --filters=Name=tag:kubernetes.io/cluster/$CLUSTER,Values=owned --query "Volumes[*].{ID:VolumeId}" | jq .[].ID -r | sort | uniq -u)
volumesInAws_amount=$(echo $volumesInAws | tr ' ' '\n' | wc -l | sed 's/ //g' )

echo "There are $total_incluster in the cluster $CLUSTER"
echo "There are $volumesInAws_amount in the AWS account of cluster $CLUSTER"

missing=(`echo ${volumesInCluster[@]} ${volumesInCluster2[@]} ${etcdVolumesInAws[@]} ${volumesInAws[@]} | tr ' ' '\n' | sort | uniq -u`)
echo "The are ${#missing[@]} volumes not present in the kubernetes cluster:"
for id in ${missing[@]}; do
  volume_status=$(aws ec2 describe-volumes --volume-ids $id --query "Volumes[*].{State:State}" | jq .[].State -r)
  echo "Volume $id is in status: $volume_status"
done

echo "If you want to delete the volumes execute the following commands:"
for id in ${missing[@]}; do
  echo "aws ec2 delete-volume --volume-id $id"
done


