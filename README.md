## Prometheus manifest builder

Creates a HA prometheus installation in the `monitoring` namespace, looking at `default` and `kube-system`. 

1. Set the required environment variables shown in
   `alertmanager-config.yaml.src`. These are the secrets to access the SMTP
   relay and the email alerts should be sent to. (`SMTP_AUTH_USERNAME`,
   `SMTP_AUTH_SECRET`, and `TARGET_EMAIL`)

2. Run `make build` (or just `make`) to create the k8s manifests

3. Apply the k8s manifests with `make apply` or `kubectl apply -f manifests\`

4. Run `./forward.sh` to access the monitoring system

- Prometheus is on `localhost:9090`
- Alertmanager is on `localhost:9093`
- Grafana is on `localhost:3000`

Uses [kube-prometheus](https://github.com/coreos/kube-prometheus)
