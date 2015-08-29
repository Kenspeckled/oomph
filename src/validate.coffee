_ = require 'lodash'
ValidationError = require './ValidationError'
_utilities = require './utilities'

validate = (validationObj, attrName, attrValue) ->
  validations = []
  for validationType in Object.keys(validationObj)
    validationSetting = validationObj[validationType]
    if validationType != 'presence' and !attrValue
      continue
    switch validationType
      when 'presence'
        if _utilities.isBlank(attrValue)
          validations.push new ValidationError attrName + " must be present", attribute: attrName, expected: validationSetting
      when 'equalTo'
        unless attrValue == validationSetting
          validations.push new ValidationError attrName + " should equal " + validationSetting, attribute: attrName, actual: attrValue, expected: validationSetting
      when 'lessThan'
        unless attrValue < validationSetting
          validations.push new ValidationError attrName + " should be less than " + validationSetting, attribute: attrName, actual: attrValue, expected: validationSetting
      when 'lessThanOrEqualTo'
        unless attrValue <= validationSetting
          validations.push new ValidationError attrName + " should be less than or equal to " + validationSetting, attribute: attrName, actual: attrValue, expected: validationSetting
      when 'greaterThanOrEqualTo'
        unless attrValue >= validationSetting
          validations.push new ValidationError attrName + " should be greater than or equal to " + validationSetting, attribute: attrName, actual: attrValue, expected: validationSetting
      when 'greaterThan'
        unless attrValue > validationSetting
          validations.push new ValidationError attrName + " should be greater than " + validationSetting, attribute: attrName, actual: attrValue, expected: validationSetting
      when 'inclusionIn'
        unless _.includes(validationSetting, attrValue)
          validations.push new ValidationError attrName + " must be one of the accepted values", attribute: attrName, actual: attrValue, expected: validationSetting
      when 'exclusionIn'
        if _.includes(validationSetting, attrValue)
          validations.push new ValidationError attrName + " must not be one of the forbidden values", attribute: attrName, actual: attrValue, expected: validationSetting
      #when 'uniqueness'
      #  # FIXME: add uniquenss test
      #  #validationPromise = new Promise (resolve, reject) =>
      #    #resolve new ValidationError attrName + " should be a unique value", attribute: attrName, actual: attrValue, expected: validationSetting
      #  #validations.push validationPromise
      when 'length'
        if validationSetting.hasOwnProperty('is')
          unless attrValue.length == validationSetting.is
            validations.push new ValidationError attrName + " should have a length of " + validationSetting.is, attribute: attrName, actual: attrValue.length, expected: validationSetting.is
        else if validationSetting.hasOwnProperty('minimum')
          unless attrValue.length >= validationSetting.minimum
            validations.push new ValidationError attrName + " should have a minimum length of " + validationSetting.minimum, attribute: attrName, actual: attrValue.length, expected: validationSetting.minimum
        else if validationSetting.hasOwnProperty('maximum')
          unless attrValue.length <= validationSetting.maximum
            validations.push new ValidationError attrName + " should have a maximum length of " + validationSetting.maximum, attribute: attrName, actual: attrValue.length, expected: validationSetting.maximum
        else
          throw new Error "length validation setting not valid on " + attrName
      when 'format'
        if validationSetting.hasOwnProperty('with')
          if validationSetting.with.exec(attrValue) == null
            validations.push new ValidationError attrName + " should meet the format requirements", attribute: attrName, actual: attrValue, expected: validationSetting.with
        else if validationSetting.hasOwnProperty('without')
          unless validationSetting.without.exec(attrValue) == null
            validations.push new ValidationError attrName + " should meet the format requirements", attribute: attrName, actual: attrValue, expected: validationSetting.without
        else
          throw new Error "format validation setting not valid on " + attrName

  validations

module.exports = validate
