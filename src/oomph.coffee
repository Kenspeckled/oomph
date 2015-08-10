utilities = require './utilities'
publishSubscribe = require './publishSubscribe'
validate = require './validate'

oomph = 

  utilities: utilities

  publishSubscribe: publishSubscribe

  validate: validate

  createClass: (name, classAttributes) ->
    _class = (props) ->
      for property of props
        this[property] = props[property]
      @initialize.apply this, arguments
      return

    _class.className = name
    _class.classAttributes = classAttributes

    if !_class::initialize
      _class::initialize = ->

    # Expects objcet data mapping adaptors to be defined on oomph
    # i.e. oomph.adaptor = require 'oomph-ajax-adaptor'
    _class = @adaptor.connectAdaptor(_class) if @adaptor

    _class.extend = (_extendableClass) ->
      Object.keys(_extendableClass).forEach (key) =>
        _class[key] = _extendableClass[key]
      Object.keys(_extendableClass.prototype).forEach (key) =>
        _class.prototype[key] = _extendableClass.prototype[key]

    return _class
  
module.exports = oomph

