ServerObject = require '../../lib/models/ServerObject'

describe 'ServerObject', ->
  it 'should be a class', ->
    serverObjectInstance = new ServerObject
    expect(serverObjectInstance).toEqual jasmine.any(ServerObject)
