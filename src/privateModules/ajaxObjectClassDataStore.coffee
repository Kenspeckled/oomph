_ = require 'lodash'
_utilities = require '../utilities'
_ajax = require '../ajax'

ajaxObjectClassDataStore =

  moduleName: "ajaxObjectClassDataStore"

  findBy: (opts) ->
    _ajax.get '/api/' + _.kebabCase(@name), opts

  find: (id) ->
    _ajax.get '/api/' + _.kebabCase(@name) + '/' + id

  all: ->
    _ajax.get '/api/' + _utilities.pluralKebabCase(@name)

  where: (opts) ->
    _ajax.get '/api/' + _utilities.pluralKebabCase(@name), opts

  create: (opts) ->
    _ajax.post '/api/' + _.kebabCase(@name), opts

  update: (id, opts) ->
    _ajax.put '/api/' + _.kebabCase(@name) + '/'+ id, opts

module.exports = ajaxObjectClassDataStore
