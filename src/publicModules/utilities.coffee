pluralize = require 'pluralize'

Promise = require 'promise'

utilities =

  randomString: (length) ->
    max = parseInt(new Array( length + 1 ).join('z'), 36)
    min = parseInt(((10**(length-1)).toString()),36)
    Math.floor(Math.random()*(max - min)+min).toString(36)

  currency: (symbol, number) ->
    symbol + parseFloat(Math.round(number * 100) / 100).toFixed(2)

  isBlank: (string) ->
    string == "" or string == undefined or string == null

  isPresent: (string) ->
    !isBlank(string)

  promiseWhile: (conditionFn, fn) ->
    new Promise (resolve, reject) ->
      promiseLoop = (output) ->
        if !conditionFn()
          return resolve(output)
        fn() # must return a promise
        .then(promiseLoop)
      process.nextTick(promiseLoop)

  promiseEachFn: (promiseFnArray) ->
    promiseReturnArray = []
    if promiseFnArray.length > 0
      firstPromiseFn = promiseFnArray.shift()
      promise = firstPromiseFn()
      promiseReturnArray.push promise
    else
      promise = new Promise (resolve) ->
        resolve()
    _.each promiseFnArray, (fn) =>
      promise = promise.then(fn)
      promiseReturnArray.push promise
    Promise.all(promiseReturnArray)

  promiseEach: (promiseArray) ->
    promiseReturnArray = []
    if promiseArray.length > 0
      promise = promiseArray.shift()
      promiseReturnArray.push promise
    else
      promise = new Promise (resolve) ->
        resolve()
    _.each promiseArray, (p) =>
      promise = promise.then -> p
      promiseReturnArray.push promise
    return Promise.all(promiseReturnArray)

  queryStringToObject: (querystring) ->
    pairs = querystring.replace('?','').split('&')
    result = {}
    pairs.forEach (pair) ->
      pair = pair.split('=')
      result[pair[0]] = decodeURIComponent(pair[1] || '')
    result

  objectToQueryString: (obj, prefix) ->
    str = []
    for p of obj
      if obj.hasOwnProperty(p)
        k = if prefix then prefix + '[' + p + ']' else p
        v = obj[p]
        str.push if typeof v == 'object' then @objectToQueryString(v, k) else encodeURIComponent(k) + '=' + encodeURIComponent(v)
    str.join '&'

  camelCase: (str) ->
    str.replace(/(?:^\w|[A-Z]|\b\w|_\w)/g, (letter, index) ->
      if index == 0 then letter.toLowerCase() else letter.toUpperCase()
    ).replace /\s+|_/g, ''

  plural: (str) ->
    pluralize(str)

  pluralKababCase: (str) ->
    kebabCaseStr = _.kebabCase(str)
    match = kebabCaseStr.match /-(\w+)$/
    if match
      lastWord = match[1] 
    else
      lastWord = kebabCaseStr
    kebabCaseStr.replace new RegExp(lastWord + '$'), pluralize(lastWord)

module.exports = utilities
