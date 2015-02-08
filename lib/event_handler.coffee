{EventEmitter}        = require 'events'
{CompositeDisposable, Range, Point, TextEditor} = require 'atom'
RemoteCursorView = require './remote-cursor-view'
fs = require 'fs'

class EventHandler

  constructor: (@remoteClient) ->
    @emitter = new EventEmitter
    @project = atom.project
    @workspace = atom.workspace
    @subscriptions = new CompositeDisposable
    @localChange = false

  onopen: (data) ->
    path = "#{@project.getPaths()[0]}/#{data.file}"
    return unless fs.existsSync(path)
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
    editor = atom.workspace.getActivePaneItem()
    return unless editor?
    editor.selectionMarker?.destroy()
    unless Point.fromObject(data.select.start).isEqual(Point.fromObject(data.select.end))
      editor.selectionMarker = editor.markBufferRange Range.fromObject(data.select), invalidate: 'never'
      editor.decorateMarker editor.selectionMarker, type: 'highlight', class: 'mp-selection'

  oncursor: (data) ->
    editor = atom.workspace.getActivePaneItem()
    return unless editor?
    editor.remoteCursor?.marker.destroy()

    editor.remoteCursor = new RemoteCursorView(editor, data.cursor)
    editor.scrollToBufferPosition(data.cursor, {center: true});

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

      editor.backspace = (args) ->
        this.emit('will-backspace', args)
        TextEditor.prototype.backspace.call(this, args)

      editor.on 'will-backspace', (event) =>
        @localChange = true

      editor.onWillInsertText =>
        @localChange = true

      editor.onDidStopChanging =>
        @localChange = false

      @subscriptions.add buffer.onDidChange (event) =>
        position = event.newRange.end

        unless @localChange
          editor.remoteCursor?.setCursorPosition(position)

      @subscriptions.add editor.onDidChangeCursorPosition (event) =>
        return if event.textChanged

        data = {
          a: 'meta',
          type: 'cursor',
          data: {
            file: @project.relativize(editor.getPath()),
            cursor: event.newScreenPosition
          }
        }

        @sendMessage data

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
      return if event.uri.indexOf('undefined') >= 0 or event.uri.match /atom:\/\//
      @sendFileEvents('open', event.uri)

    @subscriptions.add @workspace.onWillDestroyPaneItem (event) =>
      return unless event.item.getPath?()?

      event.item.detachShareJsDoc()
      @sendFileEvents('close', event.item.getPath())

    @subscriptions.add @workspace.onDidChangeActivePaneItem (event) =>
      return unless event? and event.getPath? and event.getPath()?
      @sendFileEvents('open', event.getPath())


module.exports = EventHandler
