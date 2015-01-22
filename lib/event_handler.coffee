{TextEditor} = require('atom')

class EventHandler

  constructor: (@remoteClient) ->
    @project = atom.project
    @workspace = atom.workspace

  onopen: (data) ->
    path = "#{@project.getPaths()[0]}/#{data.file}"
    @workspace.open(path)

  onclose: (data) ->
    closedItem = null

    @workspace.getPaneItems().forEach (item) ->
      closedItem = item if item.getPath().indexOf(data.file) >= 0

    @workspace.getActivePane().destroyItem closedItem

  onsave: (data) ->
    @workspace.getPaneItems().forEach (item) ->
      item.save() if item.getPath().indexOf(data.file) >= 0

  sendFileEvents: (type , file) ->
    data = { a: 'meta', type: type, data: { file: @project.relativize(file) } }

    @remoteClient.send JSON.stringify(data)

  listen: ->

    @remoteClient.on 'message', (event) =>
      event = JSON.parse(event)

      if @["on#{event.type}"]?
        @["on#{event.type}"](event.data)

    @workspace.observeTextEditors (editor) =>

      buffer = editor.getBuffer()

      buffer.onDidChange (event) ->
        editor.setCursorScreenPosition(event.newRange.end)

      editor.onDidSave (event) => @sendFileEvents('save', event.path)

    @workspace.onDidOpen (event) => @sendFileEvents('open', event.uri)

    @workspace.onWillDestroyPaneItem (event) => @sendFileEvents('close', event.item.getPath())

    @workspace.onDidChangeActivePaneItem (event) =>
      return unless event?
      @sendFileEvents('open', event.getPath())


module.exports = EventHandler
