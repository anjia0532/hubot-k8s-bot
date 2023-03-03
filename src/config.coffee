# Configuration:
#   HUBOT_K8S_CONTEXTS - map for kubernetes contexts (like kubectl), example: {"default":{"server":"https://kubernetes.example.org:6443","ca":"/kube-ca.crt","token":"kube-token","dashboardPrefix":"https://kubernetes.example.org"}}
#   HUBOT_K8S_DEFAULT_CONTEXT - default context to use
#   HUBOT_K8S_DEFAULT_NAMESPACE - default namespace to use

moment = require "moment"

class Config
  @contexts: JSON.parse process.env.HUBOT_K8S_CONTEXTS
  @defaultContext = process.env.HUBOT_K8S_DEFAULT_CONTEXT
  @defaultNamespace = process.env.HUBOT_K8S_DEFAULT_NAMESPACE

  @resourceAliases =
    "deploy": "deployments"
    "po": "pods"
    "svc": "services"
    "sts": "statefulsets"
    "no": "nodes"
    "cj": "cronjobs"

  @resourceApiPrefix =
    "deployments": "/apis/apps/v1"
    "statefulsets": "/apis/apps/v1"
    "jobs": "/apis/batch/v1"
    "cronjobs": "/apis/batch/v1"

  @getContext = (res) ->
    user = res.message.user.id
    key = "#{user}.context"
    return robot.brain.get(key) or @defaultContext

  @getContexts = (res) ->
    user = res.message.user.id
    key = "#{user}.context"
    currentContext = robot.brain.get(key) or @defaultContext
    context = ""
    for k,v of @contexts
      if (k == currentContext)
        context += "* "
      context += "#{k}  \n  "
    return context


  @setContext = (res, context) ->
    user = res.message.user.id
    key = "#{user}.context"
    return robot.brain.set(key, context or @defaultContext)

  @getNamespace = (res) ->
    user = res.message.user.id
    key = "#{user}.namespace"
    return robot.brain.get(key) or @defaultNamespace

  @setNamespace = (res, namespace) ->
    user = res.message.user.id
    key = "#{user}.namespace"
    return robot.brain.set(key, namespace or @defaultNamespace)


#    "daemonsets": "apps.daemonset"
  @responses =
    'cronjobs': (response, dashboardPrefix) ->
      reply = ''
      for cronjob in response.items
        {metadata: {name, namespace}, spec: {schedule, suspend}, status: {lastScheduleTime}} = cronjob
        reply += "- [/#{namespace}/#{name}/cronjobs](#{dashboardPrefix}/batch.cronjob/#{namespace}/#{name}) - "
        reply += "调度时间 `#{schedule}` 是否挂起 `#{suspend}` 最后调度时间 `#{moment(lastScheduleTime).fromNow()}`  \n  "
      return reply
    'nodes': (response, dashboardPrefix) ->
      reply = ''
      for nodes in response.items
        {metadata: {name}, nodeInfo: {osImage, containerRuntimeVersion, kubeletVersion}} = node
        reply += "- [/#{name}/nodes](#{dashboardPrefix}/node}/#{name}) - "
        reply += "系统镜像 `#{osImage}` container版本 `#{containerRuntimeVersion}` kubelet版本 `#{kubeletVersion}`  \n  "
      return reply
    'deployments': (response, dashboardPrefix) ->
      reply = ''
      for deployment in response.items
        {
          metadata: {name, namespace},
          status: {replicas, updatedReplicas, readyReplicas, availableReplicas}
        } = deployment
        reply += "- [/#{namespace}/#{name}/deployments](#{dashboardPrefix}/apps.deployment/#{namespace}/#{name}) - "
        reply += "目标副本 `#{replicas}` 就绪副本 `#{readyReplicas}` 更新副本 `#{updatedReplicas}` 可用副本 `#{availableReplicas}` \n  "
      return reply
    'statefulsets': (response, dashboardPrefix) ->
      reply = ''
      for statefulsets in response.items
        {
          metadata: {name, namespace},
          status: {replicas, updatedReplicas, readyReplicas, availableReplicas}
        } = statefulsets
        reply += "- [/#{namespace}/#{name}/statefulsets](#{dashboardPrefix}/apps.statefulset/#{namespace}/#{name}) - "
        reply += "目标副本 `#{replicas}` 就绪副本 `#{readyReplicas}` 更新副本 `#{updatedReplicas}` 可用副本 `#{availableReplicas}` \n  "
      return reply
    'jobs': (response, dashboardPrefix) ->
      reply = ''
      for job in response.items
        {metadata: {name, namespace}, status: {startTime, conditions}} = job
        statuses = []
        for condition in conditions
          statuses.push condition.type
        reply += "- [/#{namespace}/#{name}/jobs](#{dashboardPrefix}/batch.job/#{namespace}/#{name}) - "
        reply += "最后开始时间`#{moment(startTime).fromNow()}` 状态 `#{statuses.join(" ")}`  \n  "
      return reply
    'pods': (response, dashboardPrefix) ->
      reply = ''
      for pod in response.items
        {metadata: {name, namespace}, status: {phase, startTime, containerStatuses}} = pod
        podRestartCount = 0
        podReadyCount = 0
        podCount = 0
        for cs in (containerStatuses || [])
          {restartCount, ready, image} = cs
          podRestartCount = podRestartCount + restartCount
          podCount = podCount + 1
          if ready then podReadyCount = podReadyCount + 1
        reply += "- [/#{namespace}/#{name}/pods](#{dashboardPrefix}/pod/#{namespace}/#{name}) - "
        reply += "pod名称 `#{name}` pods `#{podReadyCount}/#{podCount}` 状态 `#{phase}` 重启次数 `#{restartCount}` 开始时间 `#{moment(startTime).fromNow()}`  \n  "
      return reply
    'services': (response, dashboardPrefix) ->
      reply = ''
      for service in response.items
        {metadata: {name, namespace}, spec: {clusterIP, ports}} = service
        internalPorts = []
        nodePorts = []
        for p in ports
          {protocol, port, nodePort} = p
          internalPorts.push "#{port}/#{protocol}"
          nodePorts.push "#{nodePort}/#{protocol}"
        reply += "- [/#{namespace}/#{name}/services](#{dashboardPrefix}/service/#{namespace}/#{name}) - "
        reply += "端口 `#{internalPorts.join(" ")}` 主机端口 `#{nodePorts.join(" ")}` 集群ip `#{clusterIP}`  \n  "
      return reply

module.exports = Config
