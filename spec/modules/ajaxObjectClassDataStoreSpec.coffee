ajaxObjectClassDataStore = require '../../src/privateModules/ajaxObjectClassDataStore'

describe 'ajaxObjectClassDataStore', ->
  it 'should be an Object', ->
    expect(ajaxObjectClassDataStore).toEqual jasmine.any(Object)
