exports.PROTOCOL_7 = PROTOCOL_7 = 'http://livereload.com/protocols/official-7'

exports.ProtocolError = class ProtocolError
  constructor: (reason, data) ->
    @message = "LiveReload protocol error (#{reason}) after receiving data: \"#{data}\"."

exports.Parser = class Parser
  protocol: null
  constructor: (@handlers) ->
    @reset()

  reset: ->
    @protocol = null

  process: (data) ->
    try
      if not @protocol?
        if message = @_parseMessage data, ['hello']
          unless message.protocols.length
            throw new ProtocolError("no protocols specified in handshake message")

          unless PROTOCOL_7 in message.protocols
            throw new ProtocolError("no supported protocols found")
          @protocol = 7

        @handlers.connected @protocol
      else
        message = @_parseMessage data, ['reload', 'alert']
        @handlers.message message

    catch e
      if typeof @handlers.error == 'function' and e instanceof ProtocolError
        @handlers.error e
      else
        throw e

  _parseMessage: (data, validCommands) ->
    try
      message = JSON.parse(data)
    catch e
      throw new ProtocolError('unparsable JSON', data)

    unless message.command
      throw new ProtocolError('missing "command" key', data)
    unless message.command in validCommands
      throw new ProtocolError("invalid command '#{message.command}', only valid commands are: #{validCommands.join(', ')})", data)

    message
