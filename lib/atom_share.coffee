{CompositeDisposable} = require 'atom'
shareAtomEditor = require './atom_attacher'

class AtomShare
  constructor: (@ws) ->
    @packageVersion = require('../package.json').version
    @subscriptions = new CompositeDisposable
    @sharejs = require('./share').client
    @sjs = new @sharejs.Connection(@ws)

  start: (sessionId) ->
    @ws.send JSON.stringify(
      {
        a: 'meta',
        type: 'init',
        sessionId: sessionId,
        atomVersion: atom.getVersion(),
        motepairVersion: @packageVersion
      }
    )

    @subscriptions.add atom.workspace.observeTextEditors (editor) =>
      relativePath = atom.project.relativize(editor.getPath())

      doc = @sjs.get('editors', "#{sessionId}:#{relativePath}")

      @setupDoc(doc, editor)

  setupDoc: (doc, editor) ->
    doc.subscribe()

    doc.whenReady ->
      unless doc.type?
        doc.create 'text'
      if doc.type and doc.type.name is 'text'
        ctx = doc.createContext() unless ctx?
        shareAtomEditor(editor, ctx)


module.exports = AtomShare
