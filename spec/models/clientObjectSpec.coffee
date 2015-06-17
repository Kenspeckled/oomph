ClientObject = require '../../src/models/ClientObject'

describe 'ClientObject', ->
  it 'should be a class', ->
    clientObjectInstance = new ClientObject
    expect(clientObjectInstance).toEqual jasmine.any(ClientObject)
