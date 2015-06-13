class ValidationError extends Error
  constructor: (message, args) ->
    @name = 'ValidationError'
    @message = message
    @attribute = args.attribute if args.attribute
    @expected = args.expected if args.expected
    @actual = args.actual if args.actual 

module.exports = ValidationError
