EventHandler = require('./event_handler.coffee')
# WsEmitClient = require('./ws/ws-emit-client.js')
WebSocket    = require('ws');
Fsm          = require('./fsm.js')
AtomShare    = require './atom_share'

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
    @ws = new WebSocket("http://localhost:3000")
    @ws.on "open", ->
      console.log("Connected")

  activate: ->
    @setDefaultValues()
    atom.workspaceView.command "atom-remote-pair:connect", => @connect()
    atom.workspaceView.command "atom-remote-pair:disconnect", => @deactivate()

  connect: ->
    @createSocketConnection()
    @atom_share = new AtomShare(@ws)
    @atom_share.start()

  deactivate: ->
    @remoteClient.destroy()

module.exports = new Main()
