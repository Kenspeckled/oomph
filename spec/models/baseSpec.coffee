Base = require '../../src/models/Base'

describe 'Base', ->
  it 'should be a class', ->
    baseInstance = new Base
    expect(baseInstance).toEqual jasmine.any(Base)
