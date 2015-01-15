EventHandler = require('./event_handler.coffee')
WsEmitClient = require('./ws/ws-emit-client.js')
Fsm          = require('./fsm.js')

class Main
  ### Public ###

  version: require('../package.json').version
 #The default remote pair settings
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
    atom.workspaceView.command "atom-remote-pair:connect", => @connect()
    atom.workspaceView.command "atom-remote-pair:disconnect", => @deactivate()

  connect: ->
    @createSocketConnection()
    @eventHandler = new EventHandler(@remoteClient, @fsm)
    @eventHandler.listen()

  deactivate: ->
    @remoteClient.destroy()

module.exports = new Main()
