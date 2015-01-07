{Emitter}    = require 'event-kit'
{TextEditor} = require('atom')
WsEmitClient = require('./ws/ws-emit-client.js')
Fsm          = require('./fsm.js')


remoteClient = new WsEmitClient('ws://localhost:3000')
fsm =  new Fsm({ws: remoteClient})

module.exports =

  activate: ->
    atom.workspaceView.command "remote-pair:action", => @action()
    @project = atom.project

    remoteClient.on 'open', ->
      console.log('Connected!')

    remoteClient.on 'save-file', (event) =>
      fsm.transition("remoteFileChanging")
      fsm.handle("saveFile", event, atom);

    remoteClient.on 'close-file', (event) =>
      fsm.transition("remoteFileChanging")
      fsm.handle("closeFile", event, atom);

    remoteClient.on 'change-file', (event) =>
      fsm.transition("remoteFileChanging")
      fsm.handle("changeFile", event, atom)

    remoteClient.on 'open-file', (event) =>
      fsm.transition("remoteFileChanging")
      fsm.handle("changeFile", event, atom)

    remoteClient.on 'change', (event) =>
      editors = atom.workspace.getTextEditors()

      for editor in editors when editor.getTitle() is event.file
        args = event.patch

        fsm.transition("remoteChanging")
        fsm.handle("remoteChange", editor, args)

    remoteClient.on 'selection', (event) =>
      editors = atom.workspace.getTextEditors()

      for editor in editors when editor.getTitle() is event.file
        fsm.transition("remoteSelecting")
        fsm.handle("remoteSelection", editor, event)
        setTimeout ->
          fsm.transition("localSelecting")
        , 300
        

    atom.workspace.observeTextEditors (editor) =>

      editor.backspace = (args) ->
        this.emit('will-backspace', args)
        TextEditor.prototype.backspace.call(this, args)

      editor.on 'will-backspace', (event)->
        fsm.transition("localChanging")

      editor.onDidSave (event) =>
        if @localSave
          remoteClient.write 'save-file', {path: @project.relativize(event.path)}

        @localSave = true

      editor.onDidChangeCursorPosition (event) =>
        if event.textChanged
          fsm.transition("localChanging")
        else
          setTimeout ->
            fsm.transition("localSelecting")
          , 300

      editor.onDidChangeSelectionRange (event) =>
        fsm.handle("localSelection", editor, event)

      editor.onWillInsertText (event) =>
        fsm.transition("localChanging")

      buffer = editor.getBuffer()

      buffer.onDidChange (event) =>
        fsm.handle('localChange', editor, event)

    atom.workspace.onDidOpen (event) =>
      fsm.handle 'fileAction', 'change-file', @project.relativize(event.uri)

      fsm.transition("localChanging")

    atom.workspace.onWillDestroyPaneItem (event) =>
      fsm.handle 'fileAction', 'close-file', @project.relativize(event.item.getPath())

      fsm.transition("localChanging")

    atom.workspace.onDidChangeActivePaneItem (event) =>
      fsm.handle 'fileAction', 'change-file', @project.relativize(event.getPath())

      fsm.transition("localChanging")
