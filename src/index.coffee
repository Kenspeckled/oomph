utilities = require './utilities'
publishSubscribe = require './publishSubscribe'
validate = require './validate'

oomph = 

  utilities: utilities

  publishSubscribe: publishSubscribe

  validate: validate

  createClass: (name, args) ->
    _class = ->
      @name = name
      @initialize.apply this, arguments
      #Object.keys(@afterInitialize).forEach (key) =>
      #  @afterInitialize[key].apply this, arguments
      return

    # Expects objcet data mapping adaptors to be defined on oomph
    # i.e. oomph.adaptor = require 'oomph-ajax-adaptor'
    _class = @adaptor.addObjectDataMappingToClass(_class) if @adaptor

    for property of args
      _class.prototype[property] = args[property]

    if !_class::initialize
      _class::initialize = ->

    _class.extendClass = (_extendedClass) ->
      Object.keys(_extendedClass).forEach (key) =>
        _class[key].apply this, arguments
      Object.keys(_extendedClass.prototype).forEach (key) =>
        _class.prototype[key].apply this, arguments

    return _class
  
module.exports = oomph

