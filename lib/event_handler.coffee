{EventEmitter}        = require 'events'
{CompositeDisposable, Range, Point} = require 'atom'

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

  onselect: (data) ->
    editor = atom.workspace.activePaneItem
    return unless editor?
    editor.selectionMarker?.destroy()
    unless Point.fromObject(data.select.start).isEqual(Point.fromObject(data.select.end))
      editor.selectionMarker = editor.markBufferRange Range.fromObject(data.select), invalidate: 'never'
      editor.decorateMarker editor.selectionMarker, type: 'highlight', class: 'mp-selection'

  sendFileEvents: (type , file) ->
    data = { a: 'meta', type: type, data: { file: @project.relativize(file) } }

    @sendMessage data

  sendMessage: (data) ->
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

      @subscriptions.add editor.onDidChangeSelectionRange (event) =>
        data = {
          a: 'meta',
          type: 'select',
          data: {
            file: @project.relativize(editor.getPath()),
            select: event.newScreenRange
          }
        }

        @sendMessage data

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
