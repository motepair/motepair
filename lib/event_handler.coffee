{EventEmitter}        = require 'events'
{CompositeDisposable} = require 'atom'

class EventHandler

  constructor: (@remoteClient) ->
    @emitter = new EventEmitter
    @project = atom.project
    @workspace = atom.workspace
    @subscriptions = new CompositeDisposable

  onopen: (data) ->
    path = "#{@project.getPaths()[0]}/#{data.file}"
    @workspace.open(path)

  onclose: (data) ->
    closedItem = null

    @workspace.getPaneItems().forEach (item) ->
      closedItem = item if item.getPath? and item.getPath()?.indexOf(data.file) >= 0

    @workspace.getActivePane().destroyItem closedItem

  onsave: (data) ->
    @workspace.getPaneItems().forEach (item) ->
      item.save() if item.getPath? and item.getPath()?.indexOf(data.file) >= 0

  sendFileEvents: (type , file) ->
    data = { a: 'meta', type: type, data: { file: @project.relativize(file) } }

    try
      @remoteClient.send JSON.stringify(data)
    catch e
      @emitter.emit 'socket-not-opened'

  listen: ->

    @remoteClient.on 'message', (event) =>
      event = JSON.parse(event)

      if @["on#{event.type}"]?
        @["on#{event.type}"](event.data)

    @subscriptions.add @workspace.observeTextEditors (editor) =>

      buffer = editor.getBuffer()

      @subscriptions.add buffer.onDidChange (event) =>
        editor.setCursorScreenPosition(event.newRange.end)

      @subscriptions.add editor.onDidSave (event) => @sendFileEvents('save', event.path)

    @subscriptions.add @workspace.onDidOpen (event) =>
      return if event.uri.indexOf('undefined') >= 0 or event.uri is 'atom://config'
      @sendFileEvents('open', event.uri)

    @subscriptions.add @workspace.onWillDestroyPaneItem (event) =>
      return unless event.item.getPath?()?
      @sendFileEvents('close', event.item.getPath())

    @subscriptions.add @workspace.onDidChangeActivePaneItem (event) =>
      return unless event? and event.getPath? and event.getPath()?
      @sendFileEvents('open', event.getPath())


module.exports = EventHandler
