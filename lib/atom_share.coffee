{allowUnsafeEval} = require 'loophole'

class AtomShare
  constructor: (@ws) ->
    allowUnsafeEval =>
      @sharejs = require('share').client
      @sjs = new @sharejs.Connection(@ws)
      require('./textarea_attach')(@sharejs)

  start: ->
    sessionId = atom.config.get('atom-remote-pair.sessionId')

    @ws.send JSON.stringify({ a: 'meta', type: 'init', sessionId: sessionId })

    atom.workspace.observeTextEditors (editor) =>
      relativePath = atom.project.relativize(editor.getPath())

      doc = @sjs.get('editors', "#{sessionId}:#{relativePath}")

      @setupDoc(doc, editor)

  setupDoc: (doc, editor) ->
    doc.textArea = document.createElement('textarea')
    doc.subscribe()
    buffer = editor.getBuffer()
    doc.whenReady ->
      unless doc.type?
        doc.create 'text'
      if doc.type and doc.type.name is 'text'
        doc.attachTextarea(doc.textArea, buffer)

    buffer.onDidChange (event) ->
      doc.textArea.value = buffer.getText()
      doc.textArea.dispatchEvent(new Event('textInput'))


module.exports = AtomShare
