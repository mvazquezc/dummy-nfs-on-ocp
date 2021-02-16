# Dummy NFS Server on OCP

Instructions to run a dummy NFS server as a pod. NOT FOR PRODUCTION.

This uses the [unfs3 project](https://github.com/unfs3/unfs3).

## Deploy the NFS Server

Below instructions as they are will only work on OpenShift since they leverage SCCs.

Below command will create:

* A Namespace
* A ServiceAccount to run the NFS Server
* A RoleBinding to give access to the `anyuid` SCC to the ServiceAccount
* A Deployment for the NFS Server
* A Service for the NFS Server (ClusterIP)

> **NOTE**: The NFS has no persistent storage, any stored file will be lost when the pod dies.

~~~sh
# Set test namespace
NAMESPACE=test-nfs
# Objects creation
cat <<EOF | oc -n ${NAMESPACE} create -f -
apiVersion: v1
kind: Namespace
metadata:
  name: ${NAMESPACE}
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: nfs-server
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: nfs-server-anyuid-scc
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:openshift:scc:anyuid
subjects:
- kind: ServiceAccount
  name: nfs-server
  namespace: ${NAMESPACE}
---
apiVersion: apps/v1
kind: Deployment
metadata:
  creationTimestamp: null
  labels:
    app: nfs-server
  name: nfs-server
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nfs-server
  strategy: {}
  template:
    metadata:
      creationTimestamp: null
      labels:
        app: nfs-server
    spec:
      serviceAccountName: nfs-server
      containers:
      - image: quay.io/mavazque/nfs-server:latest
        name: nfs-server
        securityContext:
          runAsUser: 0
        ports:
        - containerPort: 2049
        resources: {}
status: {}
---
apiVersion: v1
kind: Service
metadata:
  creationTimestamp: null
  labels:
    app: nfs-server
  name: nfs-server
spec:
  ports:
  - name: 2049-2049
    port: 2049
    protocol: TCP
    targetPort: 2049
  selector:
    app: nfs-server
  type: ClusterIP
status:
  loadBalancer: {}
EOF
~~~

## Test the Server

Now we can try to mount the NFS Share on a pod.

Below command will create:

* A PersistentVolume using the `nfs` plugin
* A PersistentVolumeClaim binding to the PersistentVolume
* A Deployment mounting the PV

~~~sh
# Set test namespace
NAMESPACE=test-nfs
# Get ClusterIP Service IP
NFS_SERVER=$(oc -n ${NAMESPACE} get svc nfs-server -o jsonpath='{.spec.clusterIP}')
# Objects creation
cat <<EOF | oc -n ${NAMESPACE} create -f -
apiVersion: v1
kind: PersistentVolume
metadata:
  name: nfs-test-volume
spec:
  capacity:
    storage: 500Mi
  accessModes:
    - ReadWriteMany
  nfs:
    server: ${NFS_SERVER}
    path: "/nfs-share"
  mountOptions:
    - port=2049
    - mountport=2049
    - nfsvers=3
    - tcp
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: nfs-test-volume-claim
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: ""
  volumeName: nfs-test-volume
  resources:
    requests:
      storage: 500Mi
---
apiVersion: apps/v1
kind: Deployment
metadata:
  creationTimestamp: null
  labels:
    app: reversewords-app-shared-storage
  name: reversewords-app-shared-storage
spec:
  replicas: 1
  selector:
    matchLabels:
      app: reversewords-app-shared-storage
  strategy: {}
  template:
    metadata:
      creationTimestamp: null
      labels:
        app: reversewords-app-shared-storage
    spec:
      securityContext:
        supplementalGroups: [5000]
      volumes:
      - name: shared-volume
        persistentVolumeClaim:
          claimName: nfs-test-volume-claim
      containers:
      - image: quay.io/mavazque/reversewords:ubi8
        name: reversewords
        resources: {}
        volumeMounts:
          - name: shared-volume
            mountPath: "/mnt"
status: {}
EOF
