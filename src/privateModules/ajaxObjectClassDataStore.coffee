_ = require 'lodash'
ajaxUtilities = require './ajaxUtilities'
_utilities = require '../publicModules/utilities'

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

  findBy: (opts) ->
    @ajax.get '/api/' + _.kebabCase(@name), opts

  find: (id) ->
    @ajax.get '/api/' + _.kebabCase(@name) + '/' + id

  all: ->
    @ajax.get '/api/' + _utilities.pluralKababCase(@name)

  where: (opts) ->
    @ajax.get '/api/' + _utilities.pluralKababCase(@name), opts

  create: (opts) ->
    @ajax.post '/api/' + _.kebabCase(@name), opts

  update: (id, opts) ->
    @ajax.put '/api/' + _.kebabCase(@name) + '/'+ id, opts

module.exports = ajaxObjectClassDataStore
