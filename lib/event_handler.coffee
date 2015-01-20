{TextEditor} = require('atom')

class EventHandler
  project: atom.project

  constructor: (@remoteClient) ->

  onopen: (data) ->
    path = "#{@project.getPaths()[0]}/#{data.file}"
    atom.workspace.open(path)

  listen: ->

    @remoteClient.on 'message', (event) =>
      event = JSON.parse(event)

      if @["on#{event.type}"]?
        @["on#{event.type}"](event.data)


    atom.workspace.observeTextEditors (editor) =>
      console.log("editor")

    atom.workspace.onDidOpen (event) =>
      console.log("c -> s: Abrindo local")
      data =
        a: 'meta'
        type:'open'
        data:
          file: @project.relativize(event.uri)

      @remoteClient.send JSON.stringify(data)


module.exports = EventHandler
