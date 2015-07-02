publishSubscribe = 

  moduleName: "publishSubscribe"

  broadcast: (ev, data) ->
    @_callbacks = {} if !@hasOwnProperty('_callbacks')
    _callbackList = @_callbacks[ev]
    return this if !@hasOwnProperty('_callbacks') || !_callbackList
    _callbackList.forEach (fn) =>
      fn.call(this, data)
    return this

  listen: (ev, fn) ->
    @_callbacks = {} if !@hasOwnProperty('_callbacks')
    (@_callbacks[ev] || @_callbacks[ev] = []).push fn
    return this

  removeListener: (ev, fn) ->
    if @_callbacks and @_callbacks[ev]
      callbackList = @_callbacks[ev]
      index = callbackList.indexOf fn
      if index > -1
        callbackList.splice(index, 1)

  removeAllListenersOn: (ev) ->
    if @_callbacks and @_callbacks[ev]
      delete @_callbacks[ev]

module.exports = publishSubscribe
