# Description:
#   Lets you interact with kubernetes
#
# Commands:
#   hubot k8s context - Diplay current Kubernetes context
#   hubot k8s context <context> - Change Kubernetes context
#   hubot k8s namespace - Diplay current Kubernetes namespace
#   hubot k8s namespace <namespace> - Change Kubernetes namespace
#   hubot k8s deployments - List Kubernetes deployments in current namespace
#   hubot k8s pods - List Kubernetes pods in current namespace
#   hubot k8s services - List Kubernetes services in current namespace
#   hubot k8s cronjobs - List Kubernetes cronjobs in current namespace
#   hubot k8s jobs - List Kubernetes jobs in current namespace
#   hubot k8s logs <pod name> - Return log of the named pod in current namespace

Config = require "./config"
KubeApi = require "./kubeapi"

module.exports = (@robot) ->
  getKubeApi = (res) ->
    context = Config.getContext(res)
    contextConfig = Config.contexts[context]
    return new KubeApi(contextConfig)

  # get/set kubernetes context
  robot.respond /k8s\s*context\s*(.+)?/i, (res) ->
    context = res.match[1]
    if not context or context is ""
      return res.reply "Kubernetes 集群列表为:\n #{Config.getContexts(res)}"
    Config.setContext res, context
    res.reply "将 Kubernetes 活动集群设置为: #{context}"

  robot.respond /k8s\s*(help)\s*(.+)?/i, (res) ->
    res.reply ["**k8s context** - 列出 k8s 集群列表",
      "**k8s context context** - 切换 k8s 集群",
      "**k8s namespace|ns** - 列出 k8s namespace 列表",
      "**k8s namespace|ns namespace** - 切换 k8s namespace",
      "**k8s nodes|no** - 列出指定k8s集群下的 nodes 列表",
      "**k8s deployments|deploy** - 列出指定k8s集群下特定命名空间下的 deployments 列表",
      "**k8s scale resource resourcename count ** - 扩缩容指定资源的为指定数量，例如 k8s scale deployment nginx-app 3",
      "**k8s statefulsets|sts** - 列出指定k8s集群下特定命名空间下的 statefulsets 列表",
      "**k8s pods|po** - 列出指定k8s集群下特定命名空间下的 pods 列表",
      "**k8s services|svc** - 列出指定k8s集群下特定命名空间下的 services 列表",
      "**k8s cronjobs|cj** - 列出指定k8s集群下特定命名空间下的 cronjobs 列表",
      "**k8s jobs** - 列出指定k8s集群下特定命名空间下的 jobs 列表",
      "**k8s logs|log podName** - 返回指定 pod 的日志",
      "**k8s help** - 列出支持的命令"
    ].join('  \n  ')

  # get/set kubernetes namespaces
  robot.respond /k8s\s*(namespace|ns)\s*(.+)?/i, (res) ->
    namespace = res.match[2]
    if not namespace or namespace is ""
      kubeapi = getKubeApi(res)
      resource = res.match[1]
      if alias = Config.resourceAliases[resource] then resource = alias
      apiPrefix = Config.resourceApiPrefix[resource] || "/api/v1";

      namespace = Config.getNamespace(res)
      kubeapi.get {path: apiPrefix + "/namespaces"}, (err, response) ->
        if err
          robot.logger.error err
          return res.send "请求K8S集群的 namespace 列表失败，集群为 *#{context}*"
        namespaces = ""
        for ns in response.items
          if ns.metadata.name == namespace
            namespaces += "* "
          namespaces += "#{ns.metadata.name}  \n  "
        return res.reply "K8S集群 #{Config.getContext(res)} 下的 namespace:  \n  #{namespaces}"
    else
      Config.setNamespace res, namespace
      res.reply "Kubernetes 集群: #{Config.getContext(res)}, namespace 切换为: #{namespace}"


  robot.respond /k8s\s*(deployments|deploy|statefulsets|sts|pods|po|services|svc|cronjobs|cj|jobs)\s*(.+)?/i, (res) ->
# kubectl get pods -n kube-system -l=tier=control-plane --v=8 打印请求url
    kubeapi = getKubeApi(res)
    namespace = Config.getNamespace(res)
    context = Config.getContext(res)
    resource = res.match[1]
    contextConfig = Config.contexts[context]
    if alias = Config.resourceAliases[resource] then resource = alias
    apiPrefix = Config.resourceApiPrefix[resource] || "/api/v1";

    url = "#{apiPrefix}/namespaces/#{namespace}/#{resource}"
    if res.match[2] and res.match[2] != ""
      url += "?labelSelector=#{res.match[2].trim()}"

    kubeapi.get {path: url}, (err, response) ->
      robot.logger.debug "请求 *#{resource}* url: #{url}"
      if err
        robot.logger.error err
        return res.send "请求 *#{resource}* 失败，集群为：**#{context}** 命名空间为：**#{namespace}**"
      return res.reply "请求 **#{resource}** labelSelector: **#{res.match[2]}** 未找到资源，集群为：**#{context}** 命名空间为：**#{namespace}**" unless response and response.items and response.items.length
      responseFormat = Config.responses[resource] or ->
      reply = "以下是 **#{context}** 集群，**#{namespace}** 命名空间下的 **#{resource}** 列表:  \n  "
      reply += responseFormat(response, contextConfig.dashboardPrefix)
      res.reply reply

  robot.respond /k8s\s*(nodes|no)\s*(.+)?/i, (res) ->
    context = Config.getContext(res)
    contextConfig = Config.contexts[context]
    resource = res.match[1]

    url = "/api/v1/nodes"
    kubeapi = new KubeApi(contextConfig)
    kubeapi.get {path: url}, (err, response) ->
      robot.logger.debug "请求 *#{resource}* url: #{url}"
      if err
        robot.logger.error err
        return res.send "拉取 nodes 失败，集群为：**#{context}**"
      return res.reply "未找到 nodes， 集群为：**#{context}**" unless response

      responseFormat = Config.responses[resource] or ->
      reply = "以下是 **#{context}** 集群下的 **#{resource}** 列表:  \n  "
      reply += responseFormat(response, contextConfig.dashboardPrefix)
      res.reply reply

  robot.respond /k8s\s*(logs|log)\s*(.+)?/i, (res) ->
    context = Config.getContext(res)
    contextConfig = Config.contexts[context]
    namespace = Config.getNamespace(res)
    pod = res.match[2]

    url = "/api/v1/namespaces/#{namespace}/pods/#{pod}/log"
    kubeapi = new KubeApi(contextConfig)
    kubeapi.get {path: url}, (err, response) ->
      robot.logger.debug "请求 *#{resource}* url: #{url}"
      if err
        robot.logger.error err
        return res.send "拉取 pod **#{pod}** 日志失败，集群为：**#{context}** 命名空间为：**#{namespace}**"
      return res.reply "未找到 **#{pod}**日志， 集群为：**#{context}** 命名空间为：**#{namespace}**" unless response

      res.reply "以下是 **#{context}** 集群，**#{namespace}** 命名空间下的 **#{pod}** 日志:  \n  "
      i = 0
      response.match(/(.|[\r\n]){1,15000}/g).forEach((item) ->
        robot.logger.info ++i + item
        res.reply item
      )

  robot.respond /k8s\s*(scale)\s*(.+)?/i, (res) ->
    command = res.match[2].split(" ")
    resource = command[0]
    name = command[1]
    count = Number(command[2])
    context = Config.getContext(res)
    contextConfig = Config.contexts[context]
    namespace = Config.getNamespace(res)

    if alias = Config.resourceAliases[resource] then resource = alias
    url = "/apis/apps/v1/namespaces/#{namespace}/#{alias}/#{name}/scale"
    kubeapi = new KubeApi(contextConfig)
    kubeapi.patch {path: url, body: {"spec": {"replicas": count}}}, (err, response) ->
      robot.logger.debug "请求 *#{resource}* url: #{url}"
      if err
        robot.logger.error err
        return res.send "修改 #{alias}/#{name} 副本数量失败，集群为：**#{context}** 命名空间为：**#{namespace}**"
      res.reply "**#{context}** 集群，**#{namespace}** 命名空间下的 #{alias}/#{name} 副本数量改为 #{count}  \n  "


