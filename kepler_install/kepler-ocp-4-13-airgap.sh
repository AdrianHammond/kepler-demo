oc delete -f kepler-ocp-4-13-airgap.yaml
oc create ns kepler
oc adm policy add-scc-to-user privileged -z default -n kepler
oc adm policy add-scc-to-user privileged -z kepler -n kepler
oc adm policy add-scc-to-user privileged -z kepler-sa -n kepler
oc label namespace kepler security.openshift.io/scc.podSecurityLabelSync=false
kubectl label --overwrite ns kepler pod-security.kubernetes.io/enforce=privileged
kubectl label --overwrite ns kepler pod-security.kubernetes.io/warn=privileged
oc apply -f kepler-ocp-4-13-airgap.yaml

sleep 5
oc describe daemonset -n kepler
oc get pods -n kepler


