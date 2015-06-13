Redis = require 'redis'
Promise = require 'promise'
redisObjectDataStore = require '../../modules/redisObjectDataStore'
_utilities = require '../../utilities'
_ = require 'lodash'
ValidationError = require '../../models/ValidationError'

describe 'redisObjectDataStore', ->
  
  beforeAll (done) ->
    @redis = Redis.createClient(1111, 'localhost')
    @redis.on "error", ->
      throw new Error "Redis server not connected on port 1111 - try running 'redis-server --port 1111 &'"
    @redis.on "ready", =>
      @redis.flushdb()
      done()
    @redisObjectDataStore = redisObjectDataStore
    @redisObjectDataStore.name = 'RedisObjectDataStore'
    @redisObjectDataStore.prototype = null
    @redisObjectDataStore.redis = @redis

  beforeEach ->
    @redisObjectDataStore.attributes =
      url:
        dataType: 'string'
        identifiable: true
        sortable: true
      one:
        dataType: 'integer'
        sortable: true
      two:
        dataType: 'integer'
        sortable: true
      three:
        dataType: 'integer'
        sortable: true
      integer:
        dataType: 'integer'
        sortable: true
      identifier:
        dataType: 'string'
        identifiable: true
      reference:
        dataType: 'association'
      manyReferences:
        dataType: 'association'
        many: true
      sortableString:
        dataType: 'string'
        sortable: true
      sortableInteger:
        dataType: 'integer'
        sortable: true
      searchableText:
        dataType: 'text'
        searchable: true
      searchableString:
        dataType: 'string'
        searchable: true
      boolean:
        dataType: 'boolean'

  afterEach ->
    @redis.flushdb()

  afterAll ->
    @redis.flushdb()
    @redis.end()

  it 'should be a valid module', ->
    expect(@redisObjectDataStore).toEqual jasmine.any(Object)
    expect(@redisObjectDataStore.moduleName).toEqual "redisObjectDataStore"

  describe 'attributes set in #create', ->
    it 'should return a promise', ->
      createPromise = @redisObjectDataStore.create(integer: 1)
      expect(createPromise).toEqual jasmine.any(Promise)

    it 'should add to a sorted set when the modules class has attributes with the field type of "integer"', (done) ->
      multi = @redisObjectDataStore.redis.multi()
      spyOn(@redisObjectDataStore.redis, 'multi').and.returnValue(multi)
      spyOn(multi, 'zadd')
      @redisObjectDataStore.create(integer: 1).then (createdObject) ->
        expect(multi.zadd).toHaveBeenCalledWith('Test#integers', 1, createdObject.id)
        done()

    it 'should add to an ordered list when the modules class has attributes with the field type of "integer" and is sortable', (done) ->
      testPromise1 = @redisObjectDataStore.create( integer: 11 )
      testPromise2 = @redisObjectDataStore.create( integer: 8 )
      testPromise3 = @redisObjectDataStore.create( integer: 10 )
      testPromise4 = @redisObjectDataStore.create( integer: 9 )
      Promise.all([testPromise1,testPromise2,testPromise3,testPromise4]).done (testObjectArray) =>
        test1Id = testObjectArray[0].id
        test2Id = testObjectArray[1].id
        test3Id = testObjectArray[2].id
        test4Id = testObjectArray[3].id
        @redis.zrange "Test#integers", 0, -1, (error, list) ->
          expect(list).toEqual [test2Id, test4Id, test3Id, test1Id]
          done()

    it 'should add to an ordered list when the modules class has attributes with the field type of "string" and is sortable', (done) ->
      testPromise1 = @redisObjectDataStore.create( sortableString: 'd' )
      testPromise2 = @redisObjectDataStore.create( sortableString: 'a' )
      testPromise3 = @redisObjectDataStore.create( sortableString: 'c' )
      testPromise4 = @redisObjectDataStore.create( sortableString: 'b' )
      Promise.all([testPromise1,testPromise2,testPromise3,testPromise4]).done (testObjectArray) =>
        test1Id = testObjectArray[0].id
        test2Id = testObjectArray[1].id
        test3Id = testObjectArray[2].id
        test4Id = testObjectArray[3].id
        @redis.zrange "TestOrderedSet#sortableStrings", 0, -1, (error, list) ->
          expect(list).toEqual [test1Id, test3Id, test4Id, test2Id]
          done()

    it 'should add to a key-value pair when the modules class has attributes with the field type of "string" and is identifiable', (done) ->
      multi = @redisObjectDataStore.redis.multi()
      spyOn(@redisObjectDataStore.redis, 'multi').and.returnValue(multi)
      spyOn(multi, 'set')
      @redisObjectDataStore.create(identifier: 'identifierValue').then (createdObject) ->
        expect(multi.set).toHaveBeenCalledWith('Test#identifier:identifierValue', createdObject.id)
        done()

    it 'should add to partial words sets when the modules class has attributes with the field type of "string" and is searchable', (done) ->
      spyOn(@redisObjectDataStore.redis, 'zadd').and.callThrough()
      @redisObjectDataStore.create(searchableText: 'Search This').then (createdObject) =>
        calledArgs = @redisObjectDataStore.redis.zadd.calls.allArgs()
        keysCalled = []
        for call in calledArgs
          keysCalled.push call[0]
        expect(keysCalled).toContain('Test#words:searchableText:s')
        expect(keysCalled).toContain('Test#words:searchableText:se')
        expect(keysCalled).toContain('Test#words:searchableText:sea')
        expect(keysCalled).toContain('Test#words:searchableText:sear')
        expect(keysCalled).toContain('Test#words:searchableText:search')
        expect(keysCalled).toContain('Test#words:searchableText:t')
        expect(keysCalled).toContain('Test#words:searchableText:th')
        expect(keysCalled).toContain('Test#words:searchableText:thi')
        expect(keysCalled).toContain('Test#words:searchableText:this')
        done()


    it 'should add to a zset when the modules class has attributes with the field type of "boolean"', (done) ->
      multi = @redisObjectDataStore.redis.multi()
      spyOn(@redisObjectDataStore.redis, 'multi').and.returnValue(multi)
      spyOn(multi, 'zadd')
      @redisObjectDataStore.create(boolean: true).then (createdObject) ->
        expect(multi.zadd).toHaveBeenCalledWith('Test#boolean:true', 1, createdObject.id)
        done()

    it 'should add to a set when the modules class has attributes with the field type of "association" and "many" is true', (done) ->
      @redisObjectDataStore.attributes =
        linkedModel:
          dataType: 'association'
          many: true
      multi = @redisObjectDataStore.redis.multi()
      spyOn(@redisObjectDataStore.redis, 'multi').and.returnValue(multi)
      spyOn(multi, 'sadd')
      @redisObjectDataStore.create(linkedModel: ['linkedModelId1', 'linkedModelId2']).then (createdObject) ->
        expect(multi.sadd).toHaveBeenCalledWith('Test#linkedModel:'+createdObject.id, 'linkedModelId1', 'linkedModelId2')
        done()

    it 'should NOT add to a set when the modules class has attributes with the field type of "association" and "many" is NOT true', (done) ->
      @redisObjectDataStore.attributes =
        linkedModel:
          dataType: 'association'
      multi = @redisObjectDataStore.redis.multi()
      spyOn(@redisObjectDataStore.redis, 'multi').and.returnValue(multi)
      spyOn(multi, 'sadd')
      @redisObjectDataStore.create(linkedModel: 'linkedModelId1').then (createdObject) ->
        expect(multi.sadd).not.toHaveBeenCalled()
        done()


  describe '#find', ->

    it 'should return a promise', ->
      testObject = @redisObjectDataStore.find('test1')
      expect(testObject).toEqual jasmine.any(Promise)

    it 'should resolve to a valid instance of the modules class when given an id', (done) ->
      pending()
      #redisObjectDataStoreClass = @redisObjectDataStoreClass
      #testProps = { one: 1, two: 2, three: 3 }
      #test1Object = new redisObjectDataStoreClass(testProps)
      #@redisObjectDataStore.create(testProps).then (returnObject) =>
      #  id = returnObject.id
      #  findPromise = @redisObjectDataStore.find(id)
      #  findPromise.done (returnValue) ->
      #    # remove generated props for the test
      #    delete returnValue.id
      #    delete returnValue.createdAt
      #    expect(returnValue).toEqual test1Object
      #    done()

    it 'should reject if no object is found', (done) ->
      findPromise = @redisObjectDataStore.find('testNotFound')
      findPromise.done (returnValue) ->
        expect(returnValue).toEqual false
        done()

    it 'should create an object of the same class as the module owner', (done) ->
      pending()

    it 'should return an integer correctly', (done) ->
      testProps = { integer: '1'}
      @redisObjectDataStore.create(testProps).then (createdObject) =>
        findPromise = @redisObjectDataStore.find(createdObject.id)
        findPromise.done (returnValue) ->
          expect(returnValue.integer).toEqual jasmine.any(Number)
          done()

    it 'should return the association id when many is false and preloadModel is not defined', (done) ->
      @redisObjectDataStore.attributes =
        associated:
          dataType: 'association'
          many: false
      testProps =  associated: 'id1'
      @redisObjectDataStore.create(testProps).then (createdObject) =>
        findPromise = @redisObjectDataStore.find(createdObject.id)
        findPromise.done (foundObj) ->
          expect(foundObj.associated).toEqual 'id1'
          done()

    it 'should return an array of association ids when many is true and preloadModel is not defined', (done) ->
      #FIXME - this test is not like our use case
      @redisObjectDataStore.attributes =
        associated:
          dataType: 'association'
          many: true
      testProps =  associated: ['id1', 'id2', 'id3']
      @redisObjectDataStore.create(testProps).then (createdObject) =>
        findPromise = @redisObjectDataStore.find(createdObject.id)
        findPromise.done (foundObj) ->
          expect(foundObj.associated).toContain 'id1'
          expect(foundObj.associated).toContain 'id2'
          expect(foundObj.associated).toContain 'id3'
          expect(foundObj.associated.length).toEqual 3
          done()

    it 'should return the association object when many is false and preloadModel is defined', (done) ->
      pending()
      #@redisObjectDataStore.attributes =
      #  associated:
      #    dataType: 'association'
      #    many: false
      #    preloadModel: @differentORM
      #expectedAssociatedObject = null
      #associationCreatePromise = @differentORM.create(url: 'associatedProduct')
      #createORMPromise = associationCreatePromise.then (associatedObject) =>
      #  testProps =  associated: associatedObject.id
      #  expectedAssociatedObject = associatedObject
      #  @redisObjectDataStore.create(testProps)
      #createORMPromise.then (createdObject) =>
      #  findPromise = @redisObjectDataStore.find(createdObject.id)
      #  findPromise.done (foundObj) ->
      #    expect(foundObj.associated).toEqual expectedAssociatedObject
      #    done()

    it 'should return an array of association objects when many is true and preloadModel is defined', (done) ->
      pending()
      #associationPromises = []
      #associationPromises.push @differentORM.create(url: 'associatedProduct1')
      #associationPromises.push @differentORM.create(url: 'associatedProduct2')
      #associationPromises.push @differentORM.create(url: 'associatedProduct3')
      #@redisObjectDataStore.attributes =
      #  associated:
      #    dataType: 'association'
      #    many: true
      #    preloadModel: @differentORM
      #Promise.all(associationPromises).then (associatedObjects) =>
      #  testProps =  associated: _.map(associatedObjects, 'id')
      #  @redisObjectDataStore.create(testProps).then (createdObject) =>
      #    findPromise = @redisObjectDataStore.find(createdObject.id)
      #    findPromise.done (foundObj) ->
      #      expect(foundObj.associated).toContain associatedObjects[0]
      #      done()



  describe '#findBy', ->
    it 'should return a promise', ->
      testObject = @redisObjectDataStore.findBy(id: 'test1')
      expect(testObject).toEqual jasmine.any(Promise)

    it "should resolve to a valid instance of the module's class when given an id", (done) ->
      testProps = { url: 'uniqueValue', one: 1, two: 2, three: 3 }
      @redisObjectDataStore.create(testProps).then (createdObject) =>
        findByPromise = @redisObjectDataStore.findBy(id: createdObject.id)
        findByPromise.done (returnValue) ->
          expect(returnValue).toEqual createdObject
          done()

    it "should resolve to a valid instance of the module's class when given a url", (done) ->
      testProps = { url: 'uniqueValue', one: 1, two: 2, three: 3 }
      @redisObjectDataStore.create(testProps).then (createdObject) =>
        findByPromise = @redisObjectDataStore.findBy(url: 'uniqueValue')
        findByPromise.done (returnValue) ->
          expect(returnValue).toEqual createdObject
          done()

    it 'should reject if no object is found', (done) ->
      findByPromise = @redisObjectDataStore.findBy(url: 'urlNotFound')
      findByPromise.done (returnValue) ->
        expect(returnValue).toEqual false
        done()

  describe '#where', ->
    it 'should remove temporary sorted sets', (done) ->
      testPromise1 = @redisObjectDataStore.create( url: 'uniqueValue1', integer: 1 )
      testPromise2 = @redisObjectDataStore.create( url: 'uniqueValue2', integer: 1 )
      testPromise3 = @redisObjectDataStore.create( url: 'uniqueValue3', integer: 2 )
      Promise.all([testPromise1,testPromise2,testPromise3]).done =>
        wherePromise = @redisObjectDataStore.where(integer: 1)
        wherePromise.done (returnValue) =>
          setTimeout =>
            @redisObjectDataStore.redis.keys 'temporary*', (err, keys) ->
              expect(keys).toEqual []
              done()
          ,1100

    it 'should return a promise', ->
      testObject = @redisObjectDataStore.where(one: '1')
      expect(testObject).toEqual jasmine.any(Promise)

    it 'should be able to return multiple test objects', (done) ->
      testPromise1 = @redisObjectDataStore.create( url: 'uniqueValue1', boolean: true )
      testPromise2 = @redisObjectDataStore.create( url: 'uniqueValue2', boolean: true )
      testPromise3 = @redisObjectDataStore.create( url: 'uniqueValue3', boolean: false )
      Promise.all([testPromise1,testPromise2,testPromise3]).done =>
        wherePromise = @redisObjectDataStore.where(boolean: true)
        wherePromise.done (returnValue) =>
          expect(returnValue.length).toEqual 2
          done()

    it 'should be able to return a single test objects', (done) ->
      testPromise1 = @redisObjectDataStore.create( url: 'uniqueValue1', one: 2 )
      testPromise2 = @redisObjectDataStore.create( url: 'uniqueValue2', one: 1 )
      testPromise3 = @redisObjectDataStore.create( url: 'uniqueValue3', one: 1 )
      Promise.all([testPromise1,testPromise2,testPromise3]).done =>
        wherePromise = @redisObjectDataStore.where(one: equalTo: 2)
        wherePromise.done (returnValue) =>
          expect(returnValue.length).toEqual 1
          expect(returnValue[0]).toEqual jasmine.objectContaining  url: 'uniqueValue1'
          done()

    it 'should return correct test objects when multiple properties conditions are met', (done) ->
      testPromise1 = @redisObjectDataStore.create( url: 'uniqueValue1', one: 1, two: 1 )
      testPromise2 = @redisObjectDataStore.create( url: 'uniqueValue2', one: 1, two: 2 )
      testPromise3 = @redisObjectDataStore.create( url: 'uniqueValue3', one: 1, two: 2 )
      Promise.all([testPromise1,testPromise2,testPromise3]).then =>
        whereConditions =
          one:
            equalTo: 1
          two:
            equalTo: 1
        wherePromise = @redisObjectDataStore.where(whereConditions)
        wherePromise.done (returnValue) =>
          expect(returnValue.length).toEqual 1
          expect(returnValue[0]).toEqual jasmine.objectContaining  url: 'uniqueValue1'
          done()

    it 'should return an empty array when nothing matches the conditions', (done) ->
      testPromise1 = @redisObjectDataStore.create( url: 'uniqueValue1', one: 1, two: 2, three: 3 )
      testPromise2 = @redisObjectDataStore.create( url: 'uniqueValue2', one: 1, two: 2, three: 3 )
      testPromise3 = @redisObjectDataStore.create( url: 'uniqueValue3', one: 1, two: 2, three: 3 )
      Promise.all([testPromise1,testPromise2,testPromise3]).then =>
        whereConditions =
          one:
            equalTo: 1
          two:
            equalTo: 2
          three:
            equalTo: 4
        wherePromise = @redisObjectDataStore.where(whereConditions)
        wherePromise.done (returnValue) =>
          expect(returnValue).toEqual []
          done()

    it "should resolve to an array of valid instances of the module's class", (done) ->
      testPromise1 = @redisObjectDataStore.create( url: 'uniqueValue1', one: 1 )
      testPromise2 = @redisObjectDataStore.create( url: 'uniqueValue2', one: 1 )
      testPromise3 = @redisObjectDataStore.create( url: 'uniqueValue3', one: null )
      Promise.all([testPromise1,testPromise2,testPromise3]).then (createdObjectArray) =>
        wherePromise = @redisObjectDataStore.where(one: 1)
        wherePromise.done (returnValue) =>
          expect(returnValue).toContain createdObjectArray[0]
          expect(returnValue).toContain createdObjectArray[1]
          expect(returnValue.length).toEqual 2
          done()

    it 'should return an array of objects sorted consistently (by id)', (done) ->
      integerArray = [1, 1, 1, 2, 2, 3, 4, 5, 5]
      promiseArray = _.map integerArray, (integer) =>
        @redisObjectDataStore.create( integer: integer )
      Promise.all(promiseArray).then (createdObjectArray) =>
        @redisObjectDataStore.where(integer: equalTo: 1).done (firstResultArray) =>
          @redisObjectDataStore.where(integer: equalTo: 1).done (secondResultArray) =>
            expect(secondResultArray).toEqual firstResultArray
            expect(secondResultArray.length).toEqual 3
            done()

    it "should default to sorting by created at time (alphabetically by id)", (done) ->
      pending()
      #createDelayedObj = (integer) ->
      #  new Promise (resolve) =>
      #    setTimeout =>
      #      resolve @redisObjectDataStore.create(integer: integer)
      #    , 10
      #delayedCreatePromises = []
      #for i in [0..9]
      #  delayedCreatePromises.push createDelayedObj.apply(this, [i%2])
      #Promise.all(delayedCreatePromises).then (createdObjectArray) =>
      #  @redisObjectDataStore.where(integer: equalTo: 1).done (returnArray) ->
      #    returnedIds = if returnArray then _.map(returnArray.ids, (x) -> x.id ) else []
      #    sortedReturnedIds = returnedIds.sort (a,b) -> a > b
      #    expect(returnArray.length).toEqual 5
      #    expect(returnedIds).toEqual sortedReturnedIds
      #    done()

    describe 'arguements', ->
      describe 'integers', ->
        beforeEach (done) ->
          testPromise1 = @redisObjectDataStore.create( url: 'uniqueValue1', integer: 5 )
          testPromise2 = @redisObjectDataStore.create( url: 'uniqueValue2', integer: 10 )
          testPromise3 = @redisObjectDataStore.create( url: 'uniqueValue3', integer: 15 )
          Promise.all([testPromise1,testPromise2,testPromise3]).then (testObjects) =>
            @testObject1 = testObjects[0]
            @testObject2 = testObjects[1]
            @testObject3 = testObjects[2]
            done()

        it 'should return an array of objects that have an integer greater than', (done) ->
          whereConditions =
            integer:
              greaterThan: 10
          wherePromise = @redisObjectDataStore.where(whereConditions)
          wherePromise.done (returnValue) =>
            expect(returnValue.length).toEqual 1
            expect(returnValue[0]).toEqual @testObject3
            done()

        it 'should return an array of objects that have an integer greater than or equal to', (done) ->
          whereConditions =
            integer:
              greaterThanOrEqualTo: 10
          wherePromise = @redisObjectDataStore.where(whereConditions)
          wherePromise.done (returnValue) =>
            expect(returnValue.length).toEqual 2
            expect(returnValue).toContain @testObject3
            expect(returnValue).toContain @testObject2
            done()

        it 'should return an array of objects that have an integer less than', (done) ->
          whereConditions =
            integer:
              lessThan: 10
          wherePromise = @redisObjectDataStore.where(whereConditions)
          wherePromise.done (returnValue) =>
            expect(returnValue.length).toEqual 1
            expect(returnValue[0]).toEqual @testObject1
            done()

        it 'should return an array of objects that have an integer less than or equal to', (done) ->
          whereConditions =
            integer:
              lessThanOrEqualTo: 10
          wherePromise = @redisObjectDataStore.where(whereConditions)
          wherePromise.done (returnValue) =>
            expect(returnValue.length).toEqual 2
            expect(returnValue).toContain @testObject1
            expect(returnValue).toContain @testObject2
            done()

        it 'should return an array of objects that have an integer equal to', (done) ->
          whereConditions =
            integer:
              equalTo: 10
          wherePromise = @redisObjectDataStore.where(whereConditions)
          wherePromise.done (returnValue) =>
            expect(returnValue.length).toEqual 1
            expect(returnValue[0]).toEqual @testObject2
            done()

      describe 'keywords', ->
        beforeEach (done) ->
          testPromise1 = @redisObjectDataStore.create( url: 'uniqueValue1', searchableText: 'bananas apples throat', searchableString: 'tongue' )
          testPromise2 = @redisObjectDataStore.create( url: 'uniqueValue2', searchableText: 'two one four', searchableString: 'neck apples' )
          testPromise3 = @redisObjectDataStore.create( url: 'uniqueValue3', searchableText: 'One two Three throat', searchableString: 'throat two' )
          Promise.all([testPromise1,testPromise2,testPromise3]).then (testObjects) =>
            @testObject1 = testObjects[0]
            @testObject2 = testObjects[1]
            @testObject3 = testObjects[2]
            done()

        it 'should return an array of objects that includes case insensitive keywords', (done) ->
          whereConditions =
            includes:
              keywords: 'one'
              in: 'searchableText'
          wherePromise = @redisObjectDataStore.where(whereConditions)
          wherePromise.done (returnValue) =>
            expect(returnValue.length).toEqual 2
            expect(returnValue).toContain @testObject2
            expect(returnValue).toContain @testObject3
            done()

        it 'should ignore empty spaces and punctuation characters', ->
          pending()

        it 'should return an array of objects that includes partial keywords', (done) ->
          whereConditions =
            includes:
              keywords: 'thr'
              in: 'searchableText'
          wherePromise = @redisObjectDataStore.where(whereConditions)
          wherePromise.done (returnValue) =>
            expect(returnValue.length).toEqual 2
            expect(returnValue).toContain @testObject1
            expect(returnValue).toContain @testObject3
            done()

        it 'should return an array of objects that includes multiple keywords in any order', (done) ->
          whereConditions =
            includes:
              keywords: 'two one'
              in: 'searchableText'
          wherePromise = @redisObjectDataStore.where(whereConditions)
          wherePromise.done (returnValue) =>
            expect(returnValue.length).toEqual 2
            expect(returnValue).toContain @testObject2
            expect(returnValue).toContain @testObject3
            done()

        describe 'inAllOf', ->
          it 'should return an array of objects that includes keywords in all different attributes', (done) ->
            whereConditions =
              includes:
                keywords: 'throat'
                inAllOf: ['searchableText', 'searchableString']
            wherePromise = @redisObjectDataStore.where(whereConditions)
            wherePromise.done (returnValue) =>
              expect(returnValue.length).toEqual 1
              expect(returnValue).toContain @testObject3
              done()

          it 'should return an array of objects that includes multiple keywords in all different attributes', (done) ->
            whereConditions =
              includes:
                keywords: 'throat two'
                inAllOf: ['searchableText', 'searchableString']
            wherePromise = @redisObjectDataStore.where(whereConditions)
            wherePromise.done (returnValue) =>
              expect(returnValue.length).toEqual 1
              expect(returnValue).toContain @testObject3
              done()

          it 'should return an array of objects that includes multiple keywords in all different attributes', (done) ->
            whereConditions =
              includes:
                keywords: 'throat One'
                inAllOf: ['searchableText', 'searchableString']
            wherePromise = @redisObjectDataStore.where(whereConditions)
            wherePromise.done (returnValue) =>
              expect(returnValue.length).toEqual 0
              done()

        describe 'inAnyOf', ->
          it 'should return an array of objects that includes keywords in any different attributes', (done) ->
            whereConditions =
              includes:
                keywords: 'throat'
                inAnyOf: ['searchableText', 'searchableString']
            wherePromise = @redisObjectDataStore.where(whereConditions)
            wherePromise.done (returnValue) =>
              expect(returnValue.length).toEqual 2
              expect(returnValue).toContain @testObject1
              expect(returnValue).toContain @testObject3
              done()

          it 'should return an array of objects that includes keywords in any different attributes ordered by relevance by default', (done) ->
            whereConditions =
              includes:
                keywords: 'apples'
                inAnyOf: ['searchableText', 'searchableString']
                modifiedWeights: [
                  attributes: 'searchableText'
                  weight: 0.5
                ]
            wherePromise = @redisObjectDataStore.where(whereConditions)
            wherePromise.done (returnValue) =>
              expect(returnValue.length).toEqual 2
              expect(returnValue[0]).toEqual @testObject2
              expect(returnValue[1]).toEqual @testObject1
              done()

          it 'should return an array of objects that includes keywords in any different attributes ordered by relevance by default', (done) ->
            whereConditions =
              includes:
                keywords: 'apples'
                inAnyOf: ['searchableText', 'searchableString']
                modifiedWeights: [
                  attributes: 'searchableString'
                  weight: 0.5
                ]
            wherePromise = @redisObjectDataStore.where(whereConditions)
            wherePromise.done (returnValue) =>
              expect(returnValue.length).toEqual 2
              expect(returnValue[0]).toEqual @testObject1
              expect(returnValue[1]).toEqual @testObject2
              done()

          it 'should return an array of objects that includes multiple keywords in any different attributes ordered by relevance by default', (done) ->
            testPromise1 = @redisObjectDataStore.create( searchableText: 'bear', searchableString: 'cow cow' )
            testPromise2 = @redisObjectDataStore.create( searchableText: 'cow cow', searchableString: 'bear' )
            testPromise3 = @redisObjectDataStore.create( searchableText: 'cow', searchableString: 'dog' )
            whereConditions =
              includes:
                keywords: 'bear cow'
                inAnyOf: ['searchableText', 'searchableString']
                modifiedWeights: [
                  attributes: 'searchableString'
                  weight: 0.5
                ]
            Promise.all([testPromise1,testPromise2,testPromise3]).done (testobjects) =>
              wherePromise = @redisObjectDataStore.where(whereConditions)
              wherePromise.done (returnValue) =>
                expect(returnValue.length).toEqual 2
                expect(returnValue[0]).toEqual testobjects[1]
                expect(returnValue[1]).toEqual testobjects[0]
                done()


      describe 'sortBy', ->
        it 'should return an array of objects ordered by a sortable field', (done) ->
          testPromise1 = @redisObjectDataStore.create( url: 'uniqueValue1', sortableString: 'alpha', boolean: true  )
          testPromise2 = @redisObjectDataStore.create( url: 'uniqueValue2', sortableString: 'beta', boolean: false )
          testPromise3 = @redisObjectDataStore.create( url: 'uniqueValue3', sortableString: 'charlie', boolean: true )
          whereConditions =
            boolean: true
            sortBy: 'sortableString'
          Promise.all([testPromise1,testPromise2,testPromise3]).done =>
            wherePromise = @redisObjectDataStore.where(whereConditions)
            wherePromise.done (returnValue) =>
              expect(returnValue.length).toEqual 2
              expect(returnValue[0]).toEqual jasmine.objectContaining  url: 'uniqueValue1'
              expect(returnValue[1]).toEqual jasmine.objectContaining  url: 'uniqueValue3'
              done()

        it 'should return an array of objects that includes keywords in different attributes, ordered by a sortable field (not weight)', (done) ->
          testPromise1 = @redisObjectDataStore.create( url: 'uniqueValue1', searchableText: 'bananas apples throat', searchableString: 'tongue', sortableString: 'charlie' )
          testPromise2 = @redisObjectDataStore.create( url: 'uniqueValue2', searchableText: 'two one four', searchableString: 'neck', sortableString: 'beta' )
          testPromise3 = @redisObjectDataStore.create( url: 'uniqueValue3', searchableText: 'One two Three', searchableString: 'throat', sortableString: 'alpha' )
          whereConditions =
            includes:
              keywords: 'throat'
              inAnyOf: ['searchableText', 'searchableString']
              modifiedWeights: [
                attributes: 'searchableText'
                weight: 2
              ]
            sortBy: 'sortableString'
          Promise.all([testPromise1,testPromise2,testPromise3]).done =>
            wherePromise = @redisObjectDataStore.where(whereConditions)
            wherePromise.done (returnValue) ->
              expect(returnValue.length).toEqual 2
              expect(returnValue[0]).toEqual jasmine.objectContaining  url: 'uniqueValue3'
              expect(returnValue[1]).toEqual jasmine.objectContaining  url: 'uniqueValue1'
              done()

        it 'should return an array of objects randomly ordered', (done) ->
          #FIXME: shouldn't have randomly failing tests
          console.log 'Occassional fail expected - testing random order'
          urlArray = ['alpha', 'bravo', 'charlie', 'delta', 'echo', 'foxtrot', 'golf', 'hotel','india', 'juliet' ]
          i = 0
          promiseArray = _.map urlArray, (url) =>
            i++
            @redisObjectDataStore.create( url: url, boolean: (i <= 5) )
          whereConditions =
            sortBy: 'rand'
            boolean: true
          Promise.all(promiseArray).done =>
            wherePromise = @redisObjectDataStore.where(whereConditions)
            wherePromise.done (returnValue) =>
              expect(returnValue.length).toEqual 5
              expect(returnValue[4]).not.toEqual jasmine.objectContaining  url: 'echo'
              done()

  describe '#all', ->
    it 'should return a promise', ->
      testObject = @redisObjectDataStore.all()
      expect(testObject).toEqual jasmine.any(Promise)

    it "should resolve to an array of all the instances of the module's class", (done) ->
      testPromise1 = @redisObjectDataStore.create( url: 'uniqueValue1', one: 1, two: 2, three: 3 )
      testPromise2 = @redisObjectDataStore.create( url: 'uniqueValue2', one: 1, two: 2, three: 3 )
      testPromise3 = @redisObjectDataStore.create( url: 'uniqueValue3', one: 1, two: 2, three: 3 )
      Promise.all([testPromise1,testPromise2,testPromise3]).then (createdObjectArray) =>
        allPromise = @redisObjectDataStore.all()
        allPromise.done (returnValue) ->
          expect(returnValue).toContain createdObjectArray[0]
          expect(returnValue).toContain createdObjectArray[1]
          expect(returnValue).toContain createdObjectArray[2]
          expect(returnValue.length).toEqual 3
          done()

    it "should not resolve any instances of a different module's class", (done) ->
      pending()
      #differentModel = _.clone @redisObjectDataStore
      #differentModel.name = "DifferentModel"
      #redisObjectDataStoreCreatePromise = @redisObjectDataStore.create( url: 'redisObjectDataStoreModelInstance')
      #differentModelCreatePromise = differentModel.create( url: 'differentModelInstance')
      #Promise.all([redisObjectDataStoreCreatePromise, differentModelCreatePromise]).then (createdObjectArray) =>
      #  redisObjectDataStoreAllPromise = @redisObjectDataStore.all()
      #  differentModelAllPromise = differentModel.all()
      #  Promise.all([redisObjectDataStoreAllPromise, differentModelAllPromise]).done (returnArray) =>
      #    expect(returnArray[0]).toEqual [createdObjectArray[0]]
      #    expect(returnArray[1]).toEqual [createdObjectArray[1]]
      #    done()

    it "should return an array of objects sorted consistently (by id)", (done) ->
      urlArray = ['india', 'juliet', 'golf', 'hotel', 'alpha', 'bravo', 'delta', 'echo', 'foxtrot', 'charlie']
      promiseArray = _.map urlArray, (url) =>
        @redisObjectDataStore.create( url: url )
      Promise.all(promiseArray).then (createdObjectArray) =>
        @redisObjectDataStore.all().done (firstResultArray) =>
          @redisObjectDataStore.all().done (secondResultArray) ->
            expect(secondResultArray).toEqual firstResultArray
            done()

    it "should default to sorting by create at time (alphabetically by id)", (done) ->
      createDelayedObj = (integer) ->
        new Promise (resolve) =>
          nextTick(resolve @redisObjectDataStore.create(integer: integer))
      delayedCreatePromises = []
      for i in [0..9]
        delayedCreatePromises.push createDelayedObj.bind(this, i)
      _utilities.promiseEachFn(delayedCreatePromises).then (createdObjectArray) =>
        @redisObjectDataStore.all().done (returnArray) ->
          expect(returnArray.length).toEqual 10
          expect(returnArray).toEqual createdObjectArray
          done()

    it "should return an array of objects sorted by sortableString when passed sortBy args", (done) ->
      stringArray = ['india', 'juliet', 'golf', 'hotel', 'alpha', 'bravo', 'delta', 'echo', 'foxtrot', 'charlie']
      objectsPromise = _.map stringArray, (string) =>
        @redisObjectDataStore.create( sortableString: string )
      Promise.all(objectsPromise).then (createdObjectArray) =>
        @redisObjectDataStore.all(sortBy: 'sortableString').done (returnArray) ->
          expect(returnArray.length).toEqual 10
          expect(returnArray[0]).toEqual jasmine.objectContaining sortableString: 'alpha'
          expect(returnArray[1]).toEqual jasmine.objectContaining sortableString: 'bravo'
          expect(returnArray[2]).toEqual jasmine.objectContaining sortableString: 'charlie'
          expect(returnArray[3]).toEqual jasmine.objectContaining sortableString: 'delta'
          expect(returnArray[4]).toEqual jasmine.objectContaining sortableString: 'echo'
          expect(returnArray[5]).toEqual jasmine.objectContaining sortableString: 'foxtrot'
          expect(returnArray[6]).toEqual jasmine.objectContaining sortableString: 'golf'
          expect(returnArray[7]).toEqual jasmine.objectContaining sortableString: 'hotel'
          expect(returnArray[8]).toEqual jasmine.objectContaining sortableString: 'india'
          expect(returnArray[9]).toEqual jasmine.objectContaining sortableString: 'juliet'
          done()

    it "should return an array of objects sorted in ascending order when passed sortBy and sortDirection args", (done) ->
      stringArray = ['india', 'juliet', 'golf', 'hotel', 'alpha', 'bravo', 'delta', 'echo', 'foxtrot', 'charlie']
      objectsPromise = _.map stringArray, (string) =>
        @redisObjectDataStore.create( sortableString: string )
      Promise.all(objectsPromise).then (createdObjectArray) =>
        @redisObjectDataStore.all(sortBy: 'sortableString', sortDirection: 'asc').done (returnArray) ->
          expect(returnArray.length).toEqual 10
          expect(returnArray[0]).toEqual jasmine.objectContaining sortableString: 'alpha'
          expect(returnArray[1]).toEqual jasmine.objectContaining sortableString: 'bravo'
          expect(returnArray[2]).toEqual jasmine.objectContaining sortableString: 'charlie'
          expect(returnArray[3]).toEqual jasmine.objectContaining sortableString: 'delta'
          expect(returnArray[4]).toEqual jasmine.objectContaining sortableString: 'echo'
          expect(returnArray[5]).toEqual jasmine.objectContaining sortableString: 'foxtrot'
          expect(returnArray[6]).toEqual jasmine.objectContaining sortableString: 'golf'
          expect(returnArray[7]).toEqual jasmine.objectContaining sortableString: 'hotel'
          expect(returnArray[8]).toEqual jasmine.objectContaining sortableString: 'india'
          expect(returnArray[9]).toEqual jasmine.objectContaining sortableString: 'juliet'
          done()

    it "should return an array of objects sorted in decending order when passed sortBy and sortDirection args", (done) ->
      stringArray = ['india', 'juliet', 'golf', 'hotel', 'alpha', 'bravo', 'delta', 'echo', 'foxtrot', 'charlie']
      objectsPromise = _.map stringArray, (string) =>
        @redisObjectDataStore.create( sortableString: string )
      Promise.all(objectsPromise).then (createdObjectArray) =>

        @redisObjectDataStore.all(sortBy: 'sortableString', sortDirection: 'desc').done (returnArray) ->
          expect(returnArray.length).toEqual 10
          expect(returnArray[0]).toEqual jasmine.objectContaining sortableString: 'juliet'
          expect(returnArray[1]).toEqual jasmine.objectContaining sortableString: 'india'
          expect(returnArray[2]).toEqual jasmine.objectContaining sortableString: 'hotel'
          expect(returnArray[3]).toEqual jasmine.objectContaining sortableString: 'golf'
          expect(returnArray[4]).toEqual jasmine.objectContaining sortableString: 'foxtrot'
          expect(returnArray[5]).toEqual jasmine.objectContaining sortableString: 'echo'
          expect(returnArray[6]).toEqual jasmine.objectContaining sortableString: 'delta'
          expect(returnArray[7]).toEqual jasmine.objectContaining sortableString: 'charlie'
          expect(returnArray[8]).toEqual jasmine.objectContaining sortableString: 'bravo'
          expect(returnArray[9]).toEqual jasmine.objectContaining sortableString: 'alpha'
          done()

    it "should return an array of 5 items when passed a limit of 5", (done) ->
      stringArray = ['india', 'juliet', 'golf', 'hotel', 'alpha', 'bravo', 'delta', 'echo', 'foxtrot', 'charlie']
      objectsPromise = _.map stringArray, (string) =>
        @redisObjectDataStore.create( sortableString: string )
      Promise.all(objectsPromise).then (createdObjectArray) =>
        @redisObjectDataStore.all(limit: 5).done (returnArray) ->
          expect(returnArray.length).toEqual 5
          done()

    it "should return an array of all available items when passed a limit of 0", (done) ->
      stringArray = ['india', 'juliet', 'golf', 'hotel', 'alpha', 'bravo', 'delta', 'echo', 'foxtrot', 'charlie']
      objectsPromise = _.map stringArray, (string) =>
        @redisObjectDataStore.create( sortableString: string )
      Promise.all(objectsPromise).then (createdObjectArray) =>
        @redisObjectDataStore.all(limit: 0).done (returnArray) ->
          expect(returnArray.length).toEqual 10
          done()

    it "should return an array of one item when passed a limit of 1", (done) ->
      stringArray = ['india', 'juliet', 'golf', 'hotel', 'alpha', 'bravo', 'delta', 'echo', 'foxtrot', 'charlie']
      objectsPromise = _.map stringArray, (string) =>
        @redisObjectDataStore.create( sortableString: string )
      Promise.all(objectsPromise).then (createdObjectArray) =>
        @redisObjectDataStore.all(limit: 1).done (returnArray) ->
          expect(returnArray.length).toEqual 1
          done()

    it "should return an array of objects sorted with a limit and an offset when passed args", (done) ->
      stringArray = ['india', 'juliet', 'golf', 'hotel', 'alpha', 'bravo', 'delta', 'echo', 'foxtrot', 'charlie']
      objectsPromise = _.map stringArray, (string) =>
        @redisObjectDataStore.create( sortableString: string )
      Promise.all(objectsPromise).then (createdObjectArray) =>
        @redisObjectDataStore.all(sortBy: 'sortableString', offset: 6).done (returnArray) ->
          expect(returnArray.length).toEqual 4
          expect(returnArray[0]).toEqual jasmine.objectContaining sortableString: 'golf'
          expect(returnArray[1]).toEqual jasmine.objectContaining sortableString: 'hotel'
          expect(returnArray[2]).toEqual jasmine.objectContaining sortableString: 'india'
          expect(returnArray[3]).toEqual jasmine.objectContaining sortableString: 'juliet'
          done()

    it "should return an array of objects sorted with a limit and an offset when passed args", (done) -> #This test failed sporadically once
      stringArray = ['india', 'juliet', 'golf', 'hotel', 'alpha', 'bravo', 'delta', 'echo', 'foxtrot', 'charlie']
      objectsPromise = _.map stringArray, (string) =>
        @redisObjectDataStore.create( sortableString: string )
      Promise.all(objectsPromise).then (createdObjectArray) =>
        @redisObjectDataStore.all(sortBy: 'sortableString', limit: 5, offset: 3).done (returnArray) ->
          expect(returnArray.length).toEqual 5
          expect(returnArray[0]).toEqual jasmine.objectContaining sortableString: 'delta'
          expect(returnArray[1]).toEqual jasmine.objectContaining sortableString: 'echo'
          expect(returnArray[2]).toEqual jasmine.objectContaining sortableString: 'foxtrot'
          expect(returnArray[3]).toEqual jasmine.objectContaining sortableString: 'golf'
          expect(returnArray[4]).toEqual jasmine.objectContaining sortableString: 'hotel'
          done()

    it "should return an array of objects sorted in decending order when passed sortBy and sortDirection args", (done) ->
      stringArray = ['india', 'juliet', 'golf', 'hotel', 'alpha', 'bravo', 'delta', 'echo', 'foxtrot', 'charlie']
      objectsPromise = _.map stringArray, (string) =>
        @redisObjectDataStore.create( sortableString: string )
      Promise.all(objectsPromise).then (createdObjectArray) =>
        @redisObjectDataStore.all(sortBy: 'sortableString', sortDirection: 'desc', limit: 2, offset: 7).done (returnArray) ->
          expect(returnArray.length).toEqual 2
          expect(returnArray[0]).toEqual jasmine.objectContaining sortableString: 'charlie'
          expect(returnArray[1]).toEqual jasmine.objectContaining sortableString: 'bravo'
          done()

    it "should return an array of objects sorted in decending order when passed sortBy and sortDirection args", (done) ->
      stringArray = ['india', 'juliet', 'golf', 'hotel', 'alpha', 'bravo', 'delta', 'echo', 'foxtrot', 'charlie']
      objectsPromise = _.map stringArray, (string) =>
        @redisObjectDataStore.create( sortableString: string )
      Promise.all(objectsPromise).then (createdObjectArray) =>
        @redisObjectDataStore.all(sortBy: 'sortableString', sortDirection: 'desc', limit: 8, offset: 1).done (returnArray) ->
          expect(returnArray.length).toEqual 8
          expect(returnArray[0]).toEqual jasmine.objectContaining sortableString: 'india'
          expect(returnArray[1]).toEqual jasmine.objectContaining sortableString: 'hotel'
          expect(returnArray[2]).toEqual jasmine.objectContaining sortableString: 'golf'
          expect(returnArray[3]).toEqual jasmine.objectContaining sortableString: 'foxtrot'
          expect(returnArray[4]).toEqual jasmine.objectContaining sortableString: 'echo'
          expect(returnArray[5]).toEqual jasmine.objectContaining sortableString: 'delta'
          expect(returnArray[6]).toEqual jasmine.objectContaining sortableString: 'charlie'
          expect(returnArray[7]).toEqual jasmine.objectContaining sortableString: 'bravo'
          done()

  describe '#create', ->
    it 'should return a promise', ->
      testProps = { url: 'uniqueValue'}
      testObject = @redisObjectDataStore.create testProps
      expect(testObject).toEqual jasmine.any(Promise)

    it 'should resolve an object with a 10 character id', (done) ->
      # This test will fail from Sun May 25 2059 18:38:27 BST (2821109907456 unix time)
      # and the number of characters will increase by 1
      testProps =  url: 'uniqueValue'
      testObjectPromise = @redisObjectDataStore.create testProps
      testObjectPromise.done (testObject) ->
        expect(testObject.id.length).toEqual 10
        done()

    it "should create an object with properties that are defined in the class' attributes", (done) ->
      testProps = boolean: false
      testObjectPromise = @redisObjectDataStore.create testProps
      testObjectPromise.then (testObject) ->
        expect(testObject.boolean).toBe false
        done()

    it "should create an object and ignore properties that are not defined in the class' attributes", (done) ->
      testProps = notAnAttribute: 'value'
      @redisObjectDataStore.create(testProps).catch (error) =>
        expect(error).toEqual(new Error "No valid fields given")
        done()


    describe 'presence validation', ->
      it 'should create objects that pass validation', (done) ->
        @redisObjectDataStore.attributes.presenceValidation =
          dataType: 'string'
          validates:
            presence: true
        @redisObjectDataStore.create(presenceValidation: 'value').then (testObject) =>
          expect(testObject.presenceValidation).toEqual 'value'
          done()

      it 'should not create objects that fail validation', (done) ->
        @redisObjectDataStore.attributes.presenceValidation =
          dataType: 'string'
          identifiable: true
          validates:
            presence: true
        @redisObjectDataStore.create(one: 1, presenceValidation: null).catch (errors) ->
          expect(errors).toContain(new Error 'presenceValidation must be present')
          done()

    describe 'length validation', ->

      it 'should not create objects that fail length validation by having a length that is greater than', (done) ->
        @redisObjectDataStore.attributes.lengthValidation =
          dataType: 'string'
          validates:
            length:
              is: 9
        @redisObjectDataStore.create(one: 1, lengthValidation: 'elevenchars').catch (errors) ->
          expect(errors.length).toEqual 1
          expect(errors).toContain jasmine.any ValidationError
          expect(errors).toContain jasmine.objectContaining message: 'lengthValidation should have a length of 9'
          done()

      it 'should not create objects that fail length validation by having a length that is less than', (done) ->
        @redisObjectDataStore.attributes.lengthValidation =
          dataType: 'string'
          validates:
            length:
              is: 9
        @redisObjectDataStore.create(lengthValidation: 'sixchr').catch (errors) ->
          expect(errors.length).toEqual 1
          expect(errors).toContain jasmine.any ValidationError
          expect(errors).toContain jasmine.objectContaining message: 'lengthValidation should have a length of 9'
          done()

      it 'should create objects that have a length that is equal to the length validation', (done) ->
        @redisObjectDataStore.attributes.lengthValidation =
          dataType: 'string'
          validates:
            length:
              is: 9
        @redisObjectDataStore.create(lengthValidation: 'ninechars').then (testObject) ->
          expect(testObject.lengthValidation).toEqual 'ninechars'
          done()

      it 'should perfredisObjectDataStore the validation only when the property is present', (done) ->
        @redisObjectDataStore.attributes.lengthValidation =
          dataType: 'string'
          validates:
            length:
              is: 9
        @redisObjectDataStore.create(one: 1, lengthValidation: null).then (testObject) =>
          expect(testObject.lengthValidation).toEqual undefined
          done()


      describe 'minimum length', ->
        it 'should create objects that have a length that is equal to the minimum length validation', (done) ->
          @redisObjectDataStore.attributes.minLengthValidation =
            dataType: 'string'
            validates:
              length:
                minimum: 9
          @redisObjectDataStore.create(minLengthValidation: 'ninechars').then (testObject) =>
            expect(testObject.minLengthValidation).toEqual 'ninechars'
            done()

        it 'should create objects that have a length that is greater than the minimum length validation', (done) ->
          @redisObjectDataStore.attributes.minLengthValidation =
            dataType: 'string'
            validates:
              length:
                minimum: 9
          @redisObjectDataStore.create(minLengthValidation: 'elevenchars').then (testObject) =>
            expect(testObject.minLengthValidation).toEqual 'elevenchars'
            done()

        it 'should not create objects that fail minLength validation', (done) ->
          @redisObjectDataStore.attributes.minLengthValidation =
            dataType: 'string'
            validates:
              length:
                minimum: 9
          @redisObjectDataStore.create(minLengthValidation: 'sixchr').catch (error) =>
            expect(error).toContain(new Error 'minLengthValidation should have a minimum length of 9')
            done()

      describe 'maximum length', ->
        it 'should create objects that have a length that is equal to the maximum length validation', (done) ->
          @redisObjectDataStore.attributes.maxLengthValidation =
            dataType: 'string'
            validates:
              length:
                maximum: 9
          @redisObjectDataStore.create(maxLengthValidation: 'ninechars').then (testObject) =>
            expect(testObject.maxLengthValidation).toEqual 'ninechars'
            done()

        it 'should create objects that have a length that is less than the maximum length validation', (done) ->
          @redisObjectDataStore.attributes.maxLengthValidation =
            dataType: 'string'
            validates:
              length:
                maximum: 9
          @redisObjectDataStore.create(maxLengthValidation: 'sixchr').then (testObject) =>
            expect(testObject.maxLengthValidation).toEqual 'sixchr'
            done()

        it 'should not create objects that fail validation', (done) ->
          @redisObjectDataStore.attributes.maxLengthValidation =
            dataType: 'string'
            validates:
              length:
                maximum: 9
          @redisObjectDataStore.create(maxLengthValidation: 'elevenchars').catch (error) =>
            expect(error).toContain(new Error 'maxLengthValidation should have a maximum length of 9')
            done()


    describe 'greaterThan validation', ->
      it 'should create objects that pass greaterThan validation', (done) ->
        @redisObjectDataStore.attributes.greaterThanValidation =
          dataType: 'integer'
          validates:
            greaterThan: 9
        @redisObjectDataStore.create(greaterThanValidation: 11).then (testObject) =>
          expect(testObject.greaterThanValidation).toEqual 11
          done()

      it 'should not create objects that fail greaterThan validation by being less than', (done) ->
        @redisObjectDataStore.attributes.greaterThanValidation =
          dataType: 'integer'
          validates:
            greaterThan: 9
        @redisObjectDataStore.create(greaterThanValidation: 1).catch (error) =>
          expect(error).toContain(new Error 'greaterThanValidation should be greater than 9')
          done()

      it 'should not create objects that fail greaterThan validation by being equal to', (done) ->
        @redisObjectDataStore.attributes.greaterThanValidation =
          dataType: 'integer'
          validates:
            greaterThan: 10
        @redisObjectDataStore.create(greaterThanValidation: 10).catch (error) =>
          expect(error).toContain(new Error 'greaterThanValidation should be greater than 10')
          done()

    describe 'greaterThanOrEqualTo validation', ->
      it 'should create objects that pass greaterThanOrEqualTo validation by being equal to', (done) ->
        @redisObjectDataStore.attributes.greaterThanOrEqualToValidation =
          dataType: 'integer'
          validates:
            greaterThanOrEqualTo: 10
        @redisObjectDataStore.create(greaterThanOrEqualToValidation: 10).then (testObject) =>
          expect(testObject.greaterThanOrEqualToValidation).toEqual 10
          done()

      it 'should create objects that pass greaterThanOrEqualTo validation by being greater than', (done) ->
        @redisObjectDataStore.attributes.greaterThanOrEqualToValidation =
          dataType: 'integer'
          validates:
            greaterThanOrEqualTo: 10
        @redisObjectDataStore.create(greaterThanOrEqualToValidation: 11).then (testObject) =>
          expect(testObject.greaterThanOrEqualToValidation).toEqual 11
          done()

      it 'should not create objects that fail greaterThanOrEqualTo validation', (done) ->
        @redisObjectDataStore.attributes.greaterThanOrEqualToValidation =
          dataType: 'integer'
          validates:
            greaterThanOrEqualTo: 10
        @redisObjectDataStore.create(greaterThanOrEqualToValidation: 1).catch (error) =>
          expect(error).toContain(new Error 'greaterThanOrEqualToValidation should be greater than or equal to 10')
          done()

    describe 'lessThan validation', ->
      it 'should create objects that pass lessThan validation', (done) ->
        @redisObjectDataStore.attributes.lessThanValidation =
          dataType: 'integer'
          validates:
            lessThan: 10
        @redisObjectDataStore.create(lessThanValidation: 9).then (testObject) =>
          expect(testObject.lessThanValidation).toEqual 9
          done()

      it 'should not create objects that fail lessThan validation by being more than', (done) ->
        @redisObjectDataStore.attributes.lessThanValidation =
          dataType: 'integer'
          validates:
            lessThan: 10
        @redisObjectDataStore.create(lessThanValidation: 11).catch (error) =>
          expect(error).toContain(new Error 'lessThanValidation should be less than 10')
          done()

      it 'should not create objects that fail lessThan validation by being equal to', (done) ->
        @redisObjectDataStore.attributes.lessThanValidation =
          dataType: 'integer'
          validates:
            lessThan: 10
        @redisObjectDataStore.create(lessThanValidation: 10).catch (error) =>
          expect(error).toContain(new Error 'lessThanValidation should be less than 10')
          done()

    describe 'lessThanOrEqualTo validation', ->
      it 'should create objects that pass lessThanOrEqualTo validation by being less than', (done) ->
        @redisObjectDataStore.attributes.lessThanOrEqualToValidation =
          dataType: 'integer'
          validates:
            lessThanOrEqualTo: 10
        @redisObjectDataStore.create(lessThanOrEqualToValidation: 9).then (testObject) =>
          expect(testObject.lessThanOrEqualToValidation).toEqual 9
          done()

      it 'should create objects that pass lessThanOrEqualTo validation by being equal to', (done) ->
        @redisObjectDataStore.attributes.lessThanOrEqualToValidation =
          dataType: 'integer'
          validates:
            lessThanOrEqualTo: 10
        @redisObjectDataStore.create(lessThanOrEqualToValidation: 10).then (testObject) =>
          expect(testObject.lessThanOrEqualToValidation).toEqual 10
          done()

      it 'should not create objects that fail lessThanOrEqualTo validation', (done) ->
        @redisObjectDataStore.attributes.lessThanOrEqualToValidation =
          dataType: 'integer'
          validates:
            lessThanOrEqualTo: 10
        @redisObjectDataStore.create(lessThanOrEqualToValidation: 11).catch (error) =>
          expect(error).toContain(new Error 'lessThanOrEqualToValidation should be less than or equal to 10')
          done()

    describe 'equalTo validation', ->
      it 'should create objects that pass equalTo validation', (done) ->
        @redisObjectDataStore.attributes.equalToValidation =
          dataType: 'integer'
          validates:
            equalTo: 10
        @redisObjectDataStore.create(equalToValidation: 10).then (testObject) =>
          expect(testObject.equalToValidation).toEqual 10
          done()

      it 'should not create objects that fail equalTo validation by being more than', (done) ->
        @redisObjectDataStore.attributes.equalToValidation =
          dataType: 'integer'
          validates:
            equalTo: 10
        @redisObjectDataStore.create(equalToValidation: 11).catch (error) =>
          expect(error).toContain(new Error 'equalToValidation should equal 10')
          done()

      it 'should not create objects that fail equalTo validation by being less than', (done) ->
        @redisObjectDataStore.attributes.equalToValidation =
          dataType: 'integer'
          validates:
            equalTo: 10
        @redisObjectDataStore.create(equalToValidation: 9).catch (error) =>
          expect(error).toContain(new Error 'equalToValidation should equal 10')
          done()

    describe 'fredisObjectDataStoreat validation', ->
      describe "'with'", ->
        it 'should not fail when the attribute is not present', (done) ->
          pending()

        it "should create objects that pass fredisObjectDataStoreat validation 'with' a regular expression that accounts for all of the data", (done) ->
          @redisObjectDataStore.attributes.fredisObjectDataStoreatValidation =
            dataType: 'string'
            validates:
              fredisObjectDataStoreat:
                with: /[a-zA-Z]+/
          @redisObjectDataStore.create(fredisObjectDataStoreatValidation: 'abcd').then (testObject) =>
            expect(testObject.fredisObjectDataStoreatValidation).toEqual 'abcd'
            done()

        it "should create objects that pass fredisObjectDataStoreat validation 'with' a regular expression that only accounts for some of the data", (done) ->
          @redisObjectDataStore.attributes.fredisObjectDataStoreatValidation =
            dataType: 'string'
            validates:
              fredisObjectDataStoreat:
                with: /[a-zA-Z]+/
          @redisObjectDataStore.create(fredisObjectDataStoreatValidation: 'ab123cd').then (testObject) =>
            expect(testObject.fredisObjectDataStoreatValidation).toEqual 'ab123cd'
            done()

        it "should not create objects that fail fredisObjectDataStoreat validation 'with' a regular expression", (done) ->
          @redisObjectDataStore.attributes.fredisObjectDataStoreatValidation =
            dataType: 'string'
            validates:
              fredisObjectDataStoreat:
                with: /[a-zA-Z]+/
          @redisObjectDataStore.create(fredisObjectDataStoreatValidation: '123').catch (error) =>
            expect(error).toContain(new Error 'fredisObjectDataStoreatValidation should meet the fredisObjectDataStoreat requirements')
            done()

        it 'should perfredisObjectDataStore the validation only when the property is present', (done) ->
          @redisObjectDataStore.attributes.fredisObjectDataStoreatValidation =
            dataType: 'string'
            validates:
              fredisObjectDataStoreat:
                with: /[a-zA-Z]+/
          @redisObjectDataStore.create(one: 1, fredisObjectDataStoreatValidation: null).then (testObject) =>
            expect(testObject.fredisObjectDataStoreatValidation).toEqual undefined
            done()

      describe "'without'", ->
        it "should not create objects that fail validation", (done) ->
          @redisObjectDataStore.attributes.fredisObjectDataStoreatValidation =
            dataType: 'string'
            validates:
              fredisObjectDataStoreat:
                without: /[a-zA-Z]+/
          @redisObjectDataStore.create(fredisObjectDataStoreatValidation: 'abcd').catch (error) ->
            expect(error).toContain(new Error 'fredisObjectDataStoreatValidation should meet the fredisObjectDataStoreat requirements')
            done()

        it "should create objects that pass fredisObjectDataStoreat validation", (done) ->
          @redisObjectDataStore.attributes.fredisObjectDataStoreatValidation =
            dataType: 'string'
            validates:
              fredisObjectDataStoreat:
                without: /[a-zA-Z]+/
          @redisObjectDataStore.create(fredisObjectDataStoreatValidation: '123').then (testObject) =>
            expect(testObject.fredisObjectDataStoreatValidation).toEqual '123'
            done()

    describe 'inclusionIn validation', ->
      it 'should create objects that pass inclusionIn validation', (done) ->
        @redisObjectDataStore.attributes.inclusionInValidation =
          dataType: 'string'
          validates:
            inclusionIn: ['one', 'two', 'three']
        @redisObjectDataStore.create(inclusionInValidation: 'one').then (testObject) =>
          expect(testObject.inclusionInValidation).toEqual 'one'
          done()

      it 'should not create objects that fail inclusionIn validation', (done) ->
        @redisObjectDataStore.attributes.inclusionInValidation =
          dataType: 'string'
          validates:
            inclusionIn: ['one', 'two', 'three']
        @redisObjectDataStore.create(inclusionInValidation: 'four').catch (error) =>
          expect(error).toContain(new Error 'inclusionInValidation must be one of the accepted values')
          done()

    describe 'exclusionIn validation', ->
      it 'should create objects that pass exclusionIn validation', (done) ->
        @redisObjectDataStore.attributes.exclusionInValidation =
          dataType: 'string'
          validates:
            exclusionIn: ['one', 'two', 'three']
        @redisObjectDataStore.create(exclusionInValidation: 'four').then (testObject) =>
          expect(testObject.exclusionInValidation).toEqual 'four'
          done()

      it 'should not create objects that fail exclusionIn validation', (done) ->
        @redisObjectDataStore.attributes.exclusionInValidation =
          dataType: 'string'
          validates:
            exclusionIn: ['one', 'two', 'three']
        @redisObjectDataStore.create(exclusionInValidation: 'one').catch (error) =>
          expect(error).toContain(new Error 'exclusionInValidation must not be one of the forbidden values')
          done()

    describe 'uniqueness validation', ->
      it 'should not create objects that fail validation', (done) ->
        @redisObjectDataStore.attributes.uniquenessValidation =
          dataType: 'string'
          identifiable: true
          validates:
            uniqueness: true
        @redisObjectDataStore.redis.set 'Test:uniquenessValidation:notUnique', 'test', () =>
          @redisObjectDataStore.create(uniquenessValidation: 'notUnique').catch (errors) =>
            expect(errors).toContain(new Error 'uniquenessValidation should be a unique value')
            done()

  describe '#update', ->
    beforeEach (done) ->
      testProps =
        one: '0'
        integer: 1
        identifier: "identifier"
        boolean: true
        reference: "reference"
        manyReferences: ['one1','two2','three3']
        searchableText: "Search this"
        sortableString: "first"
        sortableInteger: 1
      @redisObjectDataStore.create(testProps).then (testObject) =>
        @testObj = testObject
        done()

    it 'should return a promise', ->
      testObjectPromise = @redisObjectDataStore.update @testObj.id, url: 'uniqueValue'
      expect(testObjectPromise).toEqual jasmine.any(Promise)

    it 'should throw an error when the id is not found', (done) ->
      testObjectPromise = @redisObjectDataStore.update 'invalidID', url: 'uniqueValue'
      testObjectPromise.catch (error) ->
        expect(error).toEqual new Error "Id not found"
        done()

    it 'should update the object when a change is made', (done) ->
      testObjectPromise = @redisObjectDataStore.update @testObj.id, one: 111
      testObjectPromise.done (obj) ->
        expect(obj.one).toEqual 111
        done()

    it 'should update the relevant sorted set when an integer field is updated', (done) ->
      testObjectPromise = @redisObjectDataStore.update @testObj.id, integer: 9
      testObjectPromise.done (obj) =>
        @redisObjectDataStore.redis.zrangebyscore 'Test#integers', 0, 10, 'withscores', (err, res) =>
          expect(res).toEqual [@testObj.id, '9']
          done()

    it 'should update the relevant key-value pair when an identifier field is updated', (done) ->
      testObjectPromise = @redisObjectDataStore.update @testObj.id, identifier: 'edited'
      testObjectPromise.done (obj) =>
        multi = @redisObjectDataStore.redis.multi()
        multi.get 'Test#identifier:edited'
        multi.get 'Test#identifier:identifier'
        multi.exec (err, res) =>
          expect(res[0]).toEqual @testObj.id
          expect(res[1]).toEqual null
          expect(res.length).toEqual 2
          done()

    it 'should add to a set when an association field is updated', (done) ->
      testObjectPromise = @redisObjectDataStore.update @testObj.id, manyReferences: ['editedId1']
      testObjectPromise.done (obj) =>
        @redisObjectDataStore.redis.smembers 'Test#manyReferences:' + @testObj.id, (err, members) ->
          expect(members).toContain 'editedId1'
          expect(members.length).toEqual 4
          done()

    it 'should have all associated objects when an association field is updated', (done) ->
      testObjectPromise = @redisObjectDataStore.update @testObj.id, manyReferences: ['editedId1']
      testObjectPromise.done (obj) =>
        expect(obj.manyReferences.length).toEqual 4
        done()

    it 'should not save a many association field to the database', (done) ->
      pending()


    it 'should update the relevant set when a boolean field is updated', (done) ->
      testObjectPromise = @redisObjectDataStore.update @testObj.id, boolean: false
      testObjectPromise.done (obj) =>
        multi = @redisObjectDataStore.redis.multi()
        multi.zrange 'Test#boolean:false', 0, -1
        multi.zrange 'Test#boolean:true', 0, -1
        multi.exec (err, res) =>
          expect(res[0]).toEqual [@testObj.id]
          expect(res[1]).toEqual []
          expect(res.length).toEqual 2
          done()

    it 'should remove partial words sets when there is a searchable field', (done) ->
      spyOn(@redisObjectDataStore.redis, 'zrem').and.callThrough()
      @redisObjectDataStore.update(@testObj.id, searchableText: null).then (createdObject) =>
        calledArgs = @redisObjectDataStore.redis.zrem.calls.allArgs()
        keysCalled = []
        for call in calledArgs
          keysCalled.push call[0]
        expect(keysCalled).toContain('Test#words:searchableText:s')
        expect(keysCalled).toContain('Test#words:searchableText:se')
        expect(keysCalled).toContain('Test#words:searchableText:sea')
        expect(keysCalled).toContain('Test#words:searchableText:sear')
        expect(keysCalled).toContain('Test#words:searchableText:search')
        expect(keysCalled).toContain('Test#words:searchableText:t')
        expect(keysCalled).toContain('Test#words:searchableText:th')
        expect(keysCalled).toContain('Test#words:searchableText:thi')
        expect(keysCalled).toContain('Test#words:searchableText:this')
        done()

    it 'should update the relevant sorted set when a sortable string is updated', (done) ->
      testObjectPromise = @redisObjectDataStore.update @testObj.id, sortableString: 'second'
      testObjectPromise.done (obj) =>
        @redis.zrange "TestOrderedSet#sortableStrings", 0, -1, (error, list) =>
          expect(list).toEqual [@testObj.id]
          done()

    it 'should update the object', (done) ->
      updateProps = { one: 1, integer: 2, identifier: 'newidentifier', reference: 'newreference', sortableString: 'second', sortableInteger: 2, searchableText: 'new Search this', boolean: false }
      _.assign(@testObj, updateProps)
      testObjectPromise = @redisObjectDataStore.update @testObj.id, updateProps
      testObjectPromise.done (obj) =>
        @redisObjectDataStore.find(@testObj.id).done (returnValue) =>
          expect(returnValue).toEqual @testObj
          done()

    describe '"remove_" prefix', ->
      it 'should remove values from a set when an association is updated', (done) ->
        testObjectPromise = @redisObjectDataStore.update @testObj.id, remove_manyReferences: ['two2', '2']
        testObjectPromise.done (obj) =>
          @redisObjectDataStore.redis.smembers 'Test#manyReferences:' + @testObj.id, (err, members) ->
            expect(members).toContain 'one1'
            expect(members).toContain 'three3'
            expect(members.length).toEqual 2
            done()
