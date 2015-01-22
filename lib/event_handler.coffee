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

  listen: ->

    @remoteClient.on 'message', (event) =>
      event = JSON.parse(event)

      if @["on#{event.type}"]?
        @["on#{event.type}"](event.data)

    @workspace.observeTextEditors (editor) =>

      editor.onDidSave (event) =>
        data = { a: 'meta', type:'save', data: { file: @project.relativize(event.path) } }

        @remoteClient.send JSON.stringify(data)

    @workspace.onDidOpen (event) =>
      data = { a: 'meta', type:'open', data: { file: @project.relativize(event.uri) } }

      @remoteClient.send JSON.stringify(data)

    @workspace.onWillDestroyPaneItem (event) =>
      data = { a: 'meta', type:'close', data: { file: @project.relativize(event.item.getPath()) } }

      @remoteClient.send JSON.stringify(data)

    @workspace.onDidChangeActivePaneItem (event) =>
      return unless event?
      data = { a: 'meta', type:'open', data: { file: @project.relativize(event.getPath()) } }

      @remoteClient.send JSON.stringify(data)


module.exports = EventHandler
