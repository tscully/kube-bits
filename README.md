# kube-bits
Kubernetes bits and bobs

## Content
### healthcheck.sh
This is a basic healthcheck script for kubernetes clusters.  
The script has been tested against RKE and Tanzu clusters.

**Running the script**  
Simply check out or download the script and run it from shell.   

     ./healthcheck.sh [/home/user/kubeconfig]

**Prerequisites**  
The script can accept a kubeconfig file from the commandline as an argument. When not specifying the kubeconfig file, it will try to use the KUBECONFIG environment variable and current context.
  
**Capabilities**  
The script currently checks for the following components:
- Controlplane and API state.
- etcd status and peers
- Node status and conditions.
- Node CPU and memory counters.
- Pod state and restart counter.