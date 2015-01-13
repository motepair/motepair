EventHandler = require('./event_handler.coffee')
WsEmitClient = require('./ws/ws-emit-client.js')
Fsm          = require('./fsm.js')

class RemoteInitializer
  config:
    serverAddress:
      title: 'Server address'
      type: 'string'
      default: 'localhost'
    serverPort:
      title: 'Server port number'
      type: 'integer'
      default: 4444
    sessionId:
      title: 'Session Id'
      type: 'string'
      default: 'amazing-pair-programming-experience'

  setDefaultValues: ->
    @address = atom.config.get('atom-remote-pair.serverAddress')
    @portNumber = atom.config.get('atom-remote-pair.serverPort')

  createSocketConnection: ->
    @remoteClient = new WsEmitClient("ws://#{ @address }:#{ @portNumber }")
    @fsm =  new Fsm({ws: @remoteClient})

  activate: ->
    @setDefaultValues()
    @createSocketConnection()
    @eventHandler = new EventHandler(atom, @remoteClient, @fsm)
    @eventHandler.listen()

module.exports = new RemoteInitializer()
