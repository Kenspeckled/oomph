Base = require './Base'
redisObjectInstanceDataStore = require '../privateModules/redisObjectInstanceDataStore'
redisObjectClassDataStore = require '../privateModules/redisObjectClassDataStore'
class ServerObject extends Base
  @include redisObjectInstanceDataStore
  @extend redisObjectClassDataStore

module.exports = ServerObject
