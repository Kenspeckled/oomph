Base = require './Base.coffee'
ajaxObjectInstanceDataStore = require '../privateModules/ajaxObjectInstanceDataStore.coffee'
ajaxObjectClassDataStore = require '../privateModules/ajaxObjectClassDataStore.coffee'
class ClientObject extends Base
  @include ajaxObjectInstanceDataStore
  @extend ajaxObjectClassDataStore

module.exports = ClientObject
