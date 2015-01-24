EventHandler = require './event_handler'
AtomShare    = require './atom_share'
WebSocket    = require 'ws'

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
    new WebSocket("http://localhost:3000")

  activate: ->
    @setDefaultValues()
    atom.workspaceView.command "atom-remote-pair:connect", => @connect()
    atom.workspaceView.command "atom-remote-pair:disconnect", => @deactivate()

  connect: ->
    @ws ?= @createSocketConnection()

    @ws.on "open", =>
      console.log("Connected")

      @atom_share = new AtomShare(@ws)
      @atom_share.start()

      @event_handler = new EventHandler(@ws)
      @event_handler.listen()

  deactivate: ->
    @ws.close()
    @ws = null
    @event_handler.subscriptions.dispose()
    @atom_share.subscriptions.dispose()
    
module.exports = new Main()
