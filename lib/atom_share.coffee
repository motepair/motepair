{allowUnsafeEval} = require 'loophole'

attacher = require './textarea_attach.js'

class AtomShare
  constructor: (@ws) ->
    allowUnsafeEval =>
      @sharejs = require('share').client
      @sjs = new @sharejs.Connection(@ws)

  docReady: ->
    unless this.type?
      this.create 'text'
    if this.type and this.type.name is 'text'
      this.attachTextarea(this.textArea)

  start: ->
    atom.workspace.observeTextEditors (editor) =>
      relativePath = atom.project.relativize(editor.getPath())
      
      doc = @sjs.get('editors', relativePath);
      doc.textArea = document.createElement('textarea')
      doc.subscribe();
      doc.whenReady @docReady

      buffer = editor.getBuffer()
      attacher.attach(@sharejs, buffer)

      buffer.onDidChange (event) ->
        doc.textArea.value = buffer.getText()
        doc.textArea.dispatchEvent(new Event('textInput'))

module.exports = AtomShare
