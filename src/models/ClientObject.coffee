Base = require './Base'
ajaxObjectInstanceDataStore = require '../privateModules/ajaxObjectInstanceDataStore'
ajaxObjectClassDataStore = require '../privateModules/ajaxObjectClassDataStore'
class ClientObject extends Base
  @include ajaxObjectInstanceDataStore
  @extend ajaxObjectClassDataStore

module.exports = ClientObject
