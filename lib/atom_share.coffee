{allowUnsafeEval} = require 'loophole'

attacher = require './textarea_attach.js'

class AtomShare
  constructor: (@ws) ->
    allowUnsafeEval =>
      @sharejs = require('share').client
      @sjs = new @sharejs.Connection(@ws)

  start: ->
    atom.workspace.observeTextEditors (editor) =>
      relativePath = atom.project.relativize(editor.getPath())
      sessionId = atom.config.get('atom-remote-pair.sessionId')
      doc = @sjs.get('editors', "#{sessionId}:#{relativePath}")
      doc.textArea = document.createElement('textarea')
      doc.subscribe()
      doc.whenReady ->
        unless doc.type?
          doc.create 'text'
        if doc.type and doc.type.name is 'text'
          doc.attachTextarea(doc.textArea)

      buffer = editor.getBuffer()
      attacher.attach(doc, buffer)

      buffer.onDidChange (event) ->
        doc.textArea.value = buffer.getText()
        doc.textArea.dispatchEvent(new Event('textInput'))

module.exports = AtomShare
