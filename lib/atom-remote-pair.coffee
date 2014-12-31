{Emitter} = require 'event-kit'
WsEmitClient = require('./ws/ws-emit-client.js')

module.exports =
  activate: ->
    atom.workspaceView.command "remote-pair:action", => @action()
    @project = atom.project
    @localChange = true
    @localSelection = false
    @localOpening = true

    @ws = new WsEmitClient('ws://localhost:3000')

    @ws.on 'open', ->
      console.log('Connected!')

    @ws.on 'close-file', (event) =>
      @localOpening = false
      closedItem = null

      for item in atom.workspace.getPaneItems() when item.getPath().indexOf(event.path) >= 0
        closedItem = item

      activePane = atom.workspace.getActivePane() 

      activePane.destroyItem(closedItem)

    @ws.on 'change-file', (event) =>
      @localOpening = false
      atom.workspace.open("#{@project.getPaths()[0]}/#{event.path}")

    @ws.on 'open-file', (event) =>
      @localOpening = false
      atom.workspace.open("#{@project.getPaths()[0]}/#{event.path}")

    @ws.on 'change', (event) =>
      console.log("remote change", event)

      editors = atom.workspace.getTextEditors()

      for editor in editors when editor.getTitle() is event.file
        buffer = editor.getBuffer()
        args = event.patch

        @localChange = false
        if args.oldText.length > 0 and args.newText.length is 0
          buffer.delete(args.oldRange)
        else if args.oldText.length > 0 and args.newText.length > 0
          buffer.delete(args.oldRange)
          buffer.insert(args.newRange.start, args.newText)
        else if args.oldText.length is 0 and args.newText.length > 0
          buffer.insert(args.newRange.start, args.newText)

        editor.getSelections()[0].clear()

    @ws.on 'selection', (event) =>
      editors = atom.workspace.getTextEditors()

      for editor in editors when editor.getTitle() is event.file
        @localSelection = false
        editor.setSelectedBufferRange(event.range)
        @localSelection = true

    atom.workspace.observeTextEditors (editor) =>

      editor.onDidChangeCursorPosition (event) =>
        @localSelection = !event.textChanged

      editor.onDidChangeSelectionRange (event) =>
        if @localSelection
          @ws.write 'selection', { file: editor.getTitle(), range: event.newBufferRange }

      editor.onWillInsertText (event) =>
        @localSelection = false
        @old = buffer.getText()
        @localChange = true

      buffer = editor.getBuffer()
      @old = buffer.getText()

      buffer.onDidChange (event) =>
        if @localChange
          @localSelection = false
          console.log("local change", event)
          newBuffer = buffer.getText()
          @ws.write 'change', { file: editor.getTitle(), patch: event }
          @old = buffer.getText()


    atom.workspace.onDidOpen (event) =>
      if @localOpening
        @ws.write 'open-file', {path: @project.relativize(event.uri)}

      @localOpening = true

    atom.workspace.onWillDestroyPaneItem (event) =>
      if @localOpening
        @ws.write 'close-file', {path: @project.relativize(event.item.getPath())}

      @localOpening = true


    atom.workspace.onDidChangeActivePaneItem (event) =>
      if @localOpening
        @ws.write 'change-file', {path: @project.relativize(event.getPath())}

      @localOpening = true


