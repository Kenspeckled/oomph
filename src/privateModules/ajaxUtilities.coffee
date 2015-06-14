Promise = require 'promise'
ajaxUtilities = 

  httpRequest: (method, url, args, isJson) ->
    new Promise (resolve, reject) ->
      client = new XMLHttpRequest
      uri = url
      if method != 'POST'
        if args
          uri += '?'
          uri += @objectToQueryString args
        client.open method, uri
        client.send()
      else
        params = @objectToQueryString args
        client.open method, url
        client.setRequestHeader("Content-type", "application/x-www-form-urlencoded")
        client.send params 
      console.log "Ajax request " + method + " to " + uri
      client.onload = ->
        if @status == 200
          if isJson
            resolve JSON.parse(@response)
          else
            resolve @response
        else
          reject @statusText

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

module.exports = ajaxUtilities
