EventHandler = require './event_handler'
AtomShare    = require './atom_share'
WebSocket    = require 'ws'
NewSessionView = require './new-session-view'
SessionView = require './session-view'
RemoteCursorView = require './remote-cursor-view'

process.env.NODE_TLS_REJECT_UNAUTHORIZED = "0"

module.exports =
  ### Public ###

  version: require('../package.json').version
  # The default remote pair settings
  # Internal: The default configuration properties for the package.
  config:
    serverAddress:
      title: 'Server address'
      type: 'string'
      default: 'wss.motepair.com'
    serverPort:
      title: 'Server port number'
      type: 'integer'
      default: 80
    secureConnection:
      title: 'Secure Connection'
      type: 'boolean'
      default: false
    userEmail:
      title: 'Email address'
      type: 'string'
      default: ''
    followMode:
      title: 'Enable Follow mode'
      type: 'boolean'
      default: true

  setDefaultValues: ->
    @address = atom.config.get('motepair.serverAddress')
    @portNumber = atom.config.get('motepair.serverPort')
    @secureConnection = atom.config.get('motepair.secureConnection')

  createSocketConnection: ->
    @setDefaultValues()

    proto = if @secureConnection then 'wss' else 'ws'

    new WebSocket("#{proto}://#{@address}:#{@portNumber}")

  activate: ->
    @setDefaultValues()
    atom.commands.add 'atom-workspace', "motepair:connect", => @startSession()
    atom.commands.add 'atom-workspace', "motepair:disconnect", => @deactivate()

  startSession: ->
    @view = new NewSessionView()
    @view.show()

    atom.commands.add '.new-session-view',
      'core:confirm', =>
        if @view.miniEditor.getText() isnt ''
          @connect(@view.miniEditor.getText())
        else
          atom.notifications.addWarning("Motepair: Session ID can not be empty.")

  setupHeartbeat: ->
    @heartbeatId = setInterval =>
      try
        @ws.send 'ping', (error) =>
          if error?
            @event_handler.emitter.emit 'socket-not-opened'
            clearInterval(@heartbeatId)
      catch error
        @event_handler.emitter.emit 'socket-not-opened'
        clearInterval(@heartbeatId)
    , 30000

  connect: (sessionId)->

    @ws ?= @createSocketConnection()

    @ws.on "open", =>
      atom.notifications.addSuccess("Motepair: Session started.")
      @setupHeartbeat()
      @atom_share = new AtomShare(@ws)
      @atom_share.start(sessionId)

      @event_handler = new EventHandler(@ws)
      @event_handler.listen()

      @event_handler.emitter.on 'socket-not-opened', =>
        atom.notifications.addWarning("Motepair: Connection get lost.")
        @deactivate()

      @sessionStatusView = new SessionView
      @sessionStatusView.show(@view.miniEditor.getText())
      atom.clipboard.write(@view.miniEditor.getText())

    @ws.on 'error', (e) =>
      console.log('error', e)
      atom.notifications.addError("Motepair: Could not connect to server.")
      @ws.close()
      @ws = null


  deactivate: ->
    clearInterval(@heartbeatId)
    if @ws?
      atom.notifications.addSuccess("Motepair: Disconnected from session.")
      @sessionStatusView.hide()
      @ws.close()
      @ws = null
      @event_handler.subscriptions.dispose()
      @atom_share.subscriptions.dispose()
    else
      atom.notifications.addWarning("Motepair: No active session found.")
