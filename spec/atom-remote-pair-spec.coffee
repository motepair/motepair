AtomRemotePair = require '../lib/atom-remote-pair'

# Use the command `window:run-package-specs` (cmd-alt-ctrl-p) to run specs.
#
# To run a specific `it` or `describe` block add an `f` to the front (e.g. `fit`
# or `fdescribe`). Remove the `f` to unfocus the block.

describe "AtomRemotePair", ->
  [workspaceElement, activationPromise] = []

  beforeEach ->
    workspaceElement = atom.views.getView(atom.workspace)
    activationPromise = atom.packages.activatePackage('atom-remote-pair')

  describe "when the atom-remote-pair:toggle event is triggered", ->
    it "hides and shows the modal panel", ->
      # Before the activation event the view is not on the DOM, and no panel
      # has been created
      expect(workspaceElement.querySelector('.atom-remote-pair')).not.toExist()

      # This is an activation event, triggering it will cause the package to be
      # activated.
      atom.commands.dispatch workspaceElement, 'atom-remote-pair:toggle'

      waitsForPromise ->
        activationPromise

      runs ->
        expect(workspaceElement.querySelector('.atom-remote-pair')).toExist()

        atomRemotePairElement = workspaceElement.querySelector('.atom-remote-pair')
        expect(atomRemotePairElement).toExist()

        atomRemotePairPanel = atom.workspace.panelForItem(atomRemotePairElement)
        expect(atomRemotePairPanel.isVisible()).toBe true
        atom.commands.dispatch workspaceElement, 'atom-remote-pair:toggle'
        expect(atomRemotePairPanel.isVisible()).toBe false

    it "hides and shows the view", ->
      # This test shows you an integration test testing at the view level.

      # Attaching the workspaceElement to the DOM is required to allow the
      # `toBeVisible()` matchers to work. Anything testing visibility or focus
      # requires that the workspaceElement is on the DOM. Tests that attach the
      # workspaceElement to the DOM are generally slower than those off DOM.
      jasmine.attachToDOM(workspaceElement)

      expect(workspaceElement.querySelector('.atom-remote-pair')).not.toExist()

      # This is an activation event, triggering it causes the package to be
      # activated.
      atom.commands.dispatch workspaceElement, 'atom-remote-pair:toggle'

      waitsForPromise ->
        activationPromise

      runs ->
        # Now we can test for view visibility
        atomRemotePairElement = workspaceElement.querySelector('.atom-remote-pair')
        expect(atomRemotePairElement).toBeVisible()
        atom.commands.dispatch workspaceElement, 'atom-remote-pair:toggle'
        expect(atomRemotePairElement).not.toBeVisible()
