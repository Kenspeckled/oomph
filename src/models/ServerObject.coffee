Base = require './Base.coffee'
redisObjectInstanceDataStore = require '../privateModules/redisObjectInstanceDataStore.coffee'
redisObjectClassDataStore = require '../privateModules/redisObjectClassDataStore.coffee'
class ServerObject extends Base
  @include redisObjectInstanceDataStore
  @extend redisObjectClassDataStore

module.exports = ServerObject
