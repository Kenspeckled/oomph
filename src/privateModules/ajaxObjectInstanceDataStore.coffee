ajaxObjectClassDataStore = require '../privateModules/ajaxObjectClassDataStore'

ajaxObjectInstanceDataStore =

  save: ->
    if @id 
      updateFields = {}
      for attr in Object.keys(@constructor.attributes)
        updateFields[attr] = this[attr] if this[attr]
      ajaxObjectClassDataStore.update.apply(@constructor, [@id, updateFields]).then (newProps) =>
        _.assign(this, newProps)
    else
      ajaxObjectClassDataStore.create.apply(@constructor, [this]).then (newProps) =>
        _.assign(this, newProps)

module.exports = ajaxObjectInstanceDataStore
