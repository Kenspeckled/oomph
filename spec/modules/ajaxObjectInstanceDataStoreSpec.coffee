ajaxObjectInstanceDataStore = require '../../lib/privateModules/ajaxObjectInstanceDataStore'

describe 'ajaxObjectInstanceDataStore', ->
  it 'should be an Object', ->
    expect(ajaxObjectInstanceDataStore).toEqual jasmine.any(Object)
