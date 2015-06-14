Promise = require 'promise'

httpRequest = (method, url, args, isJson) ->
  new Promise (resolve, reject) ->
    client = new XMLHttpRequest
    uri = url
    if args
      uri += '?'
      uri += _utilities.objectToQueryString args
    console.log "Ajax request to " + uri
    client.open method, uri
    client.send()

    client.onload = ->
      if @status == 200
        if isJson
          resolve JSON.parse(@response)
        else
          resolve @response
      else
        reject @statusText

    client.onerror = ->
      reject @statusText

if typeof window == 'undefined' #window is not defined on the server
  url = ''
else
  url = window.location.href.replace(window.location.pathname, '').replace(window.location.search, '')

ajax =
  get: (path, args) ->
    httpRequest 'GET',  path, args, true
  post: (path, args) ->
    httpRequest 'POST', path, args
  put: (path, args) ->
    httpRequest 'PUT',  path, args
  delete: (path, args) ->
    httpRequest 'DELETE', path, args

AJAXClassMethods =

  moduleName: "AJAXClassMethods"

  all: ->
    ajax.get @indexPath

  find: (id) ->
    ajax.get @showPath, {id: id}

  findBy: (opts) ->
    ajax.get @showPath, opts

  where: (opts) ->
    ajax.get @indexPath, opts

  create: (opts) ->
    ajax.post @createPath, opts

  update: (id, opts) ->
    ajax.put @updatePath, opts

module.exports = AJAXClassMethods
