EventManager = require('./event_manager.coffee')

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

  activate: ->
    @setDefaultValues()
    @eventManager = new EventManager(atom)
    @eventManager.createSocketConnection(@address, @portNumber)

module.exports = new RemoteInitializer()
