_ = require 'lodash'
publishSubscribe = require '../publishSubscribe'

class Base
  constructor: (initialisedProps) ->
    _class = @constructor

  @extend = (args...) ->
    _class = this
    args.forEach (module) ->
      if module.constructor != Object
        throw new Error('Arguments not an object or a list of objects')
      if module.moduleInitialise
        initialiser = module.moduleInitialise.bind(_class)
        initialiser()
      for prop, value of module
        _class[prop] = value unless _.includes(['moduleName', 'moduleInitialise'], prop)
      _class.extendedModules = [] if !_class.extendedModules
      _class.extendedModules.push(module.moduleName) if !module.hasOwnProperty('moduleName')

  @include = (args...) ->
    _class = this
    args.forEach (module) ->
      if module.constructor != Object
        throw new Error('Arguments not an object or a list of objects')
      if module.moduleInitialise
        initialiser = module.moduleInitialise.bind(_class)
        initialiser()
      for prop,value of module
        _class.prototype[prop] = value unless _.includes(['moduleName', 'moduleInitialise'], prop)
      _class.includedModules = [] if !_class.includedModules
      _class.includedModules.push(module.moduleName) if !module.hasOwnProperty('moduleName')

  @getName = ->
    funcNameRegex = /function (.{1,})\(/
    results = funcNameRegex.exec(_class.toString())
    if results and results.length > 1 then results[1] else ''


Base.extend publishSubscribe

module.exports = Base

