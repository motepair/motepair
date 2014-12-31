{Emitter} = require 'event-kit'
WsEmitClient = require('./ws/ws-emit-client.js')

module.exports =
  activate: ->
    atom.workspaceView.command "remote-pair:action", => @action()
    @localChange = true
    @localSelection = false
    @emitter = new Emitter
    @ws = new WsEmitClient('ws://localhost:3000')

    @ws.on 'open', ->
      console.log('Connected!')

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
