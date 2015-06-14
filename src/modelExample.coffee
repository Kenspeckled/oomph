class Engine extends ObjectOrientedModel
  @defineFields
    manufacturingId:
      dataType: 'string'
      identifiable: true
      validates:
        presence: true
        uniqueness: true
    modelSpec:
      dataType: 'reference'
      referenceModelName: 'ModelSpec'
    horsePower:
      dataType: 'integer'
    parts:
      dataType: 'reference'
      many: true
      referenceModelName: 'Part'
    accessories:
      dataType: 'reference'
      many: true
      referenceModelName: 'Accessory'

# This should generate the following database data:
# 'Engine:[engineId]' => { id: 'engine1', manufacturingId: 'abc', modelSpec: 'xk13ed', horsePower: 5, parts: 3, accessories: 3 }
# 'ModelSpec:[modelSpecId]' => { modelName: 'Jaguar', modelDetails: 'This is a model desciption', modelID: '123234'}
# 'Engine:[engineId]#parts' => [ '12345', '123545', '351324' ]
# 'Part:[partId]#engines' => [ 'engine1', 'engine2' ]
# 'Engine:[engineId]#acessories' => [ '2', '4', '5' ]
# 'Accessory:[accessoryId]#engines' => [ 'engine1' ]

class Part  extends ObjectOrientedModel
  @defineFields
    engines:
      dataType: 'reference'
      many: true
    classification:
      dataType: 'string'
      searchable: true
      validates:
        format: /\w\w\w\d\d/

# This should generate the following database data:
# 'Part:[partId]' => { id: '12345', engines: 2, classification: 'abc12' }
# 'Part:[partId]#engines' => [ 'engine1', 'engine2' ]
# 'Engine:[engineId]#parts' => [ '12345', '123545', '351324' ]
# 'Parts#classification/a' => ['12345', '12346', '12347']
# 'Parts#classification/ab' => ['12345', '12346']
# 'Parts#classification/abc' => ['12345']
# 'Parts#classification/abc1' => ['12345']
# 'Parts#classification/abc12' => ['12345']


#Engine.where parts: { includesAnyOf: ['12345', '351324'] }
#Engine.where parts: { includesAllOf: ['12345', '351324'] }
#Parts.where parts: { excludesAnyOf: ['12345', '351324'] }
#Parts.where parts: { excludesAllOf: ['12345', '351324'] }
