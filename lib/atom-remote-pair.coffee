{Emitter} = require 'event-kit'
WsEmitClient = require('./ws/ws-emit-client.js')
Fsm = require('./fsm.js')


{TextEditor} = require('atom')


localChange = true
localSelection = false
remoteClient = new WsEmitClient('ws://localhost:3000')
fsm =  new Fsm({ localChange: localChange, ws: remoteClient})

module.exports =

  activate: ->
    atom.workspaceView.command "remote-pair:action", => @action()
    @project = atom.project
    @localOpening = true

    remoteClient.on 'open', ->
      console.log('Connected!')

    remoteClient.on 'save-file', (event) =>
      @localSave = false
      for item in atom.workspace.getPaneItems() when item.getPath().indexOf(event.path) >= 0
        item.save()

    remoteClient.on 'close-file', (event) =>
      @localOpening = false
      closedItem = null

      for item in atom.workspace.getPaneItems() when item.getPath().indexOf(event.path) >= 0
        closedItem = item

      activePane = atom.workspace.getActivePane()

      activePane.destroyItem(closedItem)

    remoteClient.on 'change-file', (event) =>
      @localOpening = false
      atom.workspace.open("#{@project.getPaths()[0]}/#{event.path}")

    remoteClient.on 'open-file', (event) =>
      @localOpening = false
      atom.workspace.open("#{@project.getPaths()[0]}/#{event.path}")

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
      if @localOpening
        remoteClient.write 'open-file', {path: @project.relativize(event.uri)}

      @localOpening = true

    atom.workspace.onWillDestroyPaneItem (event) =>
      if @localOpening
        remoteClient.write 'close-file', {path: @project.relativize(event.item.getPath())}

      @localOpening = true

    atom.workspace.onDidChangeActivePaneItem (event) =>
      if @localOpening
        remoteClient.write 'change-file', {path: @project.relativize(event.getPath())}

      @localOpening = true
