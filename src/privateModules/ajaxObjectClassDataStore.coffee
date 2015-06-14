_ = require 'lodash'
ajaxUtilities = require './ajaxUtilities'

ajaxObjectClassDataStore =

  moduleName: "ajaxObjectClassDataStore"

  ajax:
    get: (path, args) ->
      ajaxUtilities.httpRequest 'GET',  path, args, true
    post: (path, args) ->
      ajaxUtilities.httpRequest 'POST', path, args, true
    put: (path, args) ->
      ajaxUtilities.httpRequest 'PUT',  path, args
    delete: (path, args) ->
      ajaxUtilities.httpRequest 'DELETE', path, args

  all: ->
    @ajax.get '/api/' + _.kebabCase(@name) + '/index' 

  find: (id) ->
    @ajax.get '/api/' + _.kebabCase(@name) + '/'+id

  findBy: (opts) ->
    @ajax.get '/api/' + _.kebabCase(@name) + '/show', opts

  where: (opts) ->
    @ajax.get '/api/' + _.kebabCase(@name) + '/index', opts

  create: (opts) ->
    @ajax.post '/api/' + _.kebabCase(@name) + '/new', opts

  update: (id, opts) ->
    @ajax.put '/api/' + _.kebabCase(@name) + '/'+ id + '/edit', opts

module.exports = ajaxObjectClassDataStore
