ajaxUtilities = require './ajaxUtilities'

ajaxObjectClassDataStore =

  moduleName: "ajaxObjectClassDataStore"

  ajax: ->
    get: (path, args) ->
      ajaxUtilities.httpRequest 'GET',  path, args, true
    post: (path, args) ->
      ajaxUtilities.httpRequest 'POST', path, args, true
    put: (path, args) ->
      ajaxUtilities.httpRequest 'PUT',  path, args
    delete: (path, args) ->
      ajaxUtilities.httpRequest 'DELETE', path, args

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

module.exports = ajaxObjectClassDataStore
