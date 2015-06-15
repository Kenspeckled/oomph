Promise = require 'promise'
_utilities = require '../publicModules/utilities'

ajaxUtilities = 

  httpRequest: (method, url, args, isJson) ->
    new Promise (resolve, reject) =>
      client = new XMLHttpRequest
      uri = url
      if method != 'POST'
        if args
          uri += '?'
          uri += _utilities.objectToQueryString args
        client.open method, uri
        client.send()
      else
        params = _utilities.objectToQueryString args
        client.open method, url
        client.setRequestHeader("Content-type", "application/x-www-form-urlencoded")
        client.send params 
      client.onload = ->
        if @status == 200
          if isJson
            resolve JSON.parse(@response)
          else
            resolve @response
        else
          reject @statusText

module.exports = ajaxUtilities
