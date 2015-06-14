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


AJAXClassMethods =

  moduleName: "AJAXClassMethods"

  ajax: ->
    get: (path, args) ->
      httpRequest 'GET',  path, args, true
    post: (path, args) ->
      httpRequest 'POST', path, args
    put: (path, args) ->
      httpRequest 'PUT',  path, args
    delete: (path, args) ->
      httpRequest 'DELETE', path, args

  all: ->
    @ajax.get '/api/' + @name.toLowerCase + '/index' 

  find: (id) ->
    @ajax.get '/api/' + @name.toLowerCase + '/'+id

  findBy: (opts) ->
    @ajax.get '/api/' + @name.toLowerCase + '/show', opts

  where: (opts) ->
    @ajax.get '/api/' + @name.toLowerCase + '/index', opts

  create: (opts) ->
    @ajax.post '/api/' + @name.toLowerCase + '/new', opts

  update: (id, opts) ->
    @ajax.put '/api/' + @name.toLowerCase + '/'+ id + '/edit', opts

module.exports = AJAXClassMethods
