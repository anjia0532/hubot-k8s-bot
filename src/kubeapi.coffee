class KubeApi
  request = require 'request'

  constructor: (contextConfig) ->
    caFile = contextConfig['ca']?
    if caFile and caFile != ""
      fs = require('fs')
      path = require('path')
      @ca = fs.readFileSync(caFile)
    @urlPrefix = contextConfig['server']
    @token = contextConfig['token']

  get: ({path, roles}, callback) ->
    requestOptions =
      url: @urlPrefix + path

    requestOptions['auth'] =
      bearer: @token

    if @ca
      requestOptions.agentOptions =
        ca: @ca

    request.get requestOptions, (err, response, data) ->
      return callback(err) if err
      if response.statusCode == 404
        return callback null, null
      if response.statusCode != 200
        return callback new Error("请求 k8s api 报错: #{response.statusCode}" + JSON.stringify(data))
      if typeof data == 'string' and (data.startsWith "{" or data.startsWith "[")
        callback null, JSON.parse(data)
      else
        callback null, data

  patch: ({body, path, roles}, callback) ->
    requestOptions =
      url: @urlPrefix + path

    if body
      requestOptions.body = body

    requestOptions['method'] = "PATCH"
    requestOptions['json'] = true
    requestOptions['headers'] = {"content-type": "application/merge-patch+json"}

    requestOptions['auth'] =
      bearer: @token

    if @ca
      requestOptions.agentOptions =
        ca: @ca

    request requestOptions, (err, response, data) ->
      return callback(err) if err
      if response.statusCode == 404
        return callback null, null
      if response.statusCode != 200
        return callback new Error("请求 k8s api 报错: #{response.statusCode}" + JSON.stringify(data))
      callback null, data


module.exports = KubeApi
