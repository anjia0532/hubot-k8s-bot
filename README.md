# Hubot Kubernetes Bot 机器人

支持多 K8S 集群并与其交互。

## 配置

- `HUBOT_K8S_CONTEXTS` `{"prod":{"server":"https://kubernetes.cluster.io","ca":"./ca.crt","dashboardPrefix":"https://kubernetes.cluster.io","token":"<kubernetes token>"}}`
- `HUBOT_K8S_DEFAULT_CONTEXT` - Default context (from above config)
- `HUBOT_K8S_DEFAULT_NAMESPACE` - Default namespace in Kubernetes

## 命令:

All commands operate in the currently selected namespace and context. All commands with label selectors accept it in the form `label=value`.

### 列出所有命令
> k8s help

### 列出 Kubernetes 集群
> k8s context

### 切换 Kubernetes 集群
> k8s context `<context>`

### 列出 Kubernetes 命名空间
> k8s namespace|ns

### 切换 Kubernetes 命名空间
> k8s namespace|ns `<namespace>`

### 列出 Deployments
> k8s deployments|deploy [`<labelSelector>`]

### 列出 Statefulsets
> k8s statefulsets|sts [`<labelSelector>`]

### 列出 Nodes
> k8s nodes|no [`<labelSelector>`]

### 列出 Services
> k8s services|svc [`<labelSelector>`]

### 列出 Cron Jobs
> k8s cronjobs|cj [`<labelSelector>`]

### 列出 Jobs
> k8s jobs [`<labelSelector>`]

### 列出 Pods
> k8s pods|po [`<labelSelector>`]

### 获取日志
> k8s logs|log `<pod name>`

## 鸣谢

- https://github.com/astamiviswakarma/hubot-k8s
- https://github.com/canthefason/hubot-kubernetes
