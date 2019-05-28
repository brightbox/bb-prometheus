local stripLimits(podSpec, containerName) = podSpec + {
  local containers = podSpec.containers,
  local rbacProxyCtnr = std.filter(function(c) c.name == containerName, containers)[0] + {
    resources+: {
      limits: {},
    },
  },
  local otherCtnrs = std.filter(function(c) c.name != containerName, containers),
  containers: otherCtnrs + [rbacProxyCtnr],
};

local _kp = 
  (import 'kube-prometheus/kube-prometheus.libsonnet') +
  (import 'kube-prometheus/kube-prometheus-kubeadm.libsonnet') + {
    _config+:: {
      namespace: 'monitoring',
      alertmanager+:: {
        config: importstr 'alertmanager-config.yaml',
      },
    },
  };

local kp = _kp + {
  nodeExporter+: {
    daemonset+: {
      spec+: {
        template+: {
          spec:
            stripLimits(
              stripLimits(_kp.nodeExporter.daemonset.spec.template.spec,
                'node-exporter'),
                'kube-rbac-proxy'),
        },
      },
    },
  },
  kubeStateMetrics+: {
    deployment+: {
      spec+: {
        template+: {
          spec:
            stripLimits(
              stripLimits(
                stripLimits(_kp.kubeStateMetrics.deployment.spec.template.spec,
                  'kube-rbac-proxy-main'),
                  'kube-rbac-proxy-self'),
                  'addon-resizer'),
        },
      },
    },
  },
  prometheusOperator+: {
    deployment+: {
      spec+: {
        template+: {
          spec+: {
            containers: [
              _kp.prometheusOperator.deployment.spec.template.spec.containers[0] + {
                args+: [
                  '--config-reloader-cpu=0'
                ],
              }
            ],
          },
        },
      },
    },
  },
};

{ ['00namespace-' + name]: kp.kubePrometheus[name] for name in std.objectFields(kp.kubePrometheus) } +
{ ['0prometheus-operator-' + name]: kp.prometheusOperator[name] for name in std.objectFields(kp.prometheusOperator) } +
{ ['node-exporter-' + name]: kp.nodeExporter[name] for name in std.objectFields(kp.nodeExporter) } +
{ ['kube-state-metrics-' + name]: kp.kubeStateMetrics[name] for name in std.objectFields(kp.kubeStateMetrics) } +
{ ['alertmanager-' + name]: kp.alertmanager[name] for name in std.objectFields(kp.alertmanager) } +
{ ['prometheus-' + name]: kp.prometheus[name] for name in std.objectFields(kp.prometheus) } +
{ ['prometheus-adapter-' + name]: kp.prometheusAdapter[name] for name in std.objectFields(kp.prometheusAdapter) } +
{ ['grafana-' + name]: kp.grafana[name] for name in std.objectFields(kp.grafana) }
