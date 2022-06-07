## RootFS usage of pods on a node
### Requirements
- kubeconfig file to the cluster
- jq and curl

### Procedure
1. Start a proxy to the api server
    ```kubectl proxy --port=8080```

2. Curl the node stats and pipe to jq for formatting.
    ``` curl http://localhost:8080/api/v1/nodes/NODE_NAME/proxy/stats/summary 2>/dev/null | jq '.pods[] | .containers[].name + " - " + (.containers[].rootfs.usedBytes|tostring)+" Bytes"'```
    Result:
    ```
    "vsphere-csi-node - 53248 Bytes"
    "liveness-probe - 53248 Bytes"
    "node-driver-registrar - 53248 Bytes"
    "vsphere-csi-node - 36864 Bytes"
    ```