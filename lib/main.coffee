EventHandler = require './event_handler'
AtomShare    = require './atom_share'
WebSocket    = require 'ws'

module.exports =
  ### Public ###

  version: require('../package.json').version
  #The default remote pair settings
  # Internal: The default configuration properties for the package.
  config:
    serverAddress:
      title: 'Server address'
      type: 'string'
      default: 'localhost'
    serverPort:
      title: 'Server port number'
      type: 'integer'
      default: 3000
    sessionId:
      title: 'Session Id'
      type: 'string'
      default: 'amazing-pair-programming-experience'

  setDefaultValues: ->
    @address = atom.config.get('atom-remote-pair.serverAddress')
    @portNumber = atom.config.get('atom-remote-pair.serverPort')

  createSocketConnection: ->
    new WebSocket("http://#{@address}:#{@portNumber}")

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
