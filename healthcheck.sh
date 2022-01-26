#!/bin/bash

set -o pipefail

# Some general vars

if [ -z $1 ]
then
    echo "no kubeconfig file provided"
    exit 1
else
    kubeconfig=$1
fi

kctl="kubectl --kubeconfig=$1"
GREEN='\033[0;32m'
RED='\033[0;31m'
WHITE='\033[0;37m'

# Healthcheck functions
#######################

function cluster_check ()
{
    # check commands
    cluster_apicheck=$($kctl get --raw='/livez/ping')
    cluster_etcdcheck=$($kctl get --raw='/livez/etcd')
    cluster_etcdpod=$($kctl get pods -A | grep etcd | awk '{print $2}' | head -n1)
    cluster_etcdpeercmd="etcdctl member list --key=/etc/kubernetes/pki/etcd/server.key --cert=/etc/kubernetes/pki/etcd/server.crt --cacert=/etc/kubernetes/pki/etcd/ca.crt"
    
    # Produce cluster-info
    $kctl cluster-info | head -n2

    # Check cluster api-server
    if [ $cluster_apicheck == "ok" ]
    then
        echo -e "${GREEN}API server${WHITE} is running"
    else
        echo -e "${RED}WARNING:${WHITE} API server is faulty"
    fi
    sleep 1

    # Check cluster etcd server
    if [ $cluster_etcdcheck == "ok" ]
    then
        echo -e "${GREEN}etcd cluster${WHITE} is running"
    else
        echo -e "${RED}WARNING:${WHITE} etcd is faulty"
    fi

    # Check cluster etcd members
    if [ -z $cluster_etcdpod ]
    then
        echo "No etcd pods available to verify peers"
    else
        echo ""
        echo "Active etcd cluster peers:"
        $kctl exec -n kube-system -it $cluster_etcdpod -- $cluster_etcdpeercmd | awk '{print "    "$0}'
    fi

    echo ""

}

function node_check ()
{
    # Check commands
    node_notready=$(kubectl --kubeconfig=$1 get nodes | grep NotReady | awk '{print $1}')
    node_scheddisabled=$(kubectl --kubeconfig=$1 get nodes | grep SchedulingDisabled | awk '{print $1}')
    node_top=$(kubectl --kubeconfig=$1 top nodes --use-protocol-buffers)

    # Check for NotReady nodes
    if [ -z $node_status ]
    then
        echo "No NotReady nodes found"  
    else
        echo "WARNING: NotReady nodes found:"
        echo "$node_notready"
    fi
    sleep 1
    # Check for SchedulingDisabled nodes
    if [ -z $nodescheddisabled ]
    then
        echo "No SchedulingDisabled nodes found"  
    else
        echo "WARNING: SchedulingDisabled nodes found:"
        echo "$nodescheddisabled"
    fi
    sleep 1
    # Check for node CPU/mem metrics
    echo ""
    echo "Listing node CPU/memory metrics"
    echo "$node_top" | awk '{print "    "$0}'
    echo ""
    sleep 1
    # Check for node conditions
    echo "Listing node conditions:"
    $kctl get nodes | awk '{print $1}' | tail -n +2 | while read node ;
    do  
        echo -e ${GREEN}$node${WHITE};
        $kctl describe node $node | grep -A 6 "Conditions:" | tail -n +2;
    done
    echo ""
}

function pod_check ()
{
    # Check commands
    podunavailable=$($kctl get pods -A | grep -v Running | grep -v Completed | tail -n +2)

    # Check for pods that are not Running or Completed
    if [ -z $podunavailable ]
    then
        echo "All pods in running or completed state"
        echo ""
    else
        echo "WARNING: Pods found that are not Running or Completed:"
        echo "$podunavailable"
        echo ""
    fi

    # Check for pod restarts
    echo "Listing pods with restarts: "
    $kctl get pods -A | tail -n +2 | while read pod ; 
    do 
        if [[ $(echo $pod | awk '{print $5}') > 0 ]]
        then
            echo $pod | awk '{print "Pod \033[32m" $2 "\033[37m in namespace \033[32m" $1 "\033[37m has \033[32m" $5 "\033[37m restarts"}'; 
        fi
    done
}


# Main
######
echo ""
echo "Kubernetes healthcheck script"
echo "#############################"
echo ""
echo "Selected kubeconfig file is" $1
echo ""

echo "Checking cluster status:"
echo "------------------------"
cluster_check

echo "Checking node status:"
echo "---------------------"
node_check

echo "Checking pod status:"
echo "--------------------"
pod_check