# Remote Pairing package

[![Build Status](https://travis-ci.org/motepair/motepair.svg?branch=master)](https://travis-ci.org/motepair/motepair) [![Join the chat at https://gitter.im/motepair/motepair](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/motepair/motepair?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

Remote pair programming tool for Atom. Lag free!

![remote-pair](https://raw.githubusercontent.com/motepair/motepair/master/docs/motepair.gif)

### How it Works
We’ve done a basic integration with  [Share.js](http://sharejs.org/) to allow concurrent editing via OT and bind some Atom events to a websocket, like opening/closing/saving files.

### Installing

Use the Atom package manager, which can be found in the Settings view or
run `apm install motepair` from the command line.


### Using
Open the project to start collaborating via the `Motepair:connect` command
(you can trigger this command via Cmd+Shift+P).

Please make sure that peers to open the same project directory. This is a very important step as we rely on the relative project path to identify the correct file.

### Current Status
Features:
  - Insertion/Deletion.
  - Open/Close/Switch Files.
  - Save Files.
  - Selection
  - Remote Cursor
  - Gravatar
    - Go to Motepair settings to enable it. Just type your email than your pair will see your photo.
  - Encrypted Connection (You need to deploy your own [server](https://github.com/motepair/motepair-server) in order to use this feature.)

Current Backlog:
  - Peers Indication
  - Directory validation

### Development
* Create a branch with your feature/fix.
* Add a specs
* Create a PR.

### Warning
The connection right now it is not encrypted if you have problems with that, please do not use it. That is part of the backlog.

Be aware that this package is still in development, so it can be unstable, we are working hard to make the Remote Pair programming a better experience to all.

Please, if you see any bug, don't hesitate and open a Issue, we need your help to improve the code and fix all the bugs.

Check out the [server repository](https://github.com/motepair/motepair-server)

## Contributors

* [Leon Maia](http://github.com/leonmaia) ([@leonmaia](https://twitter.com/leonmaia))
* [Luiz Filho](http://github.com/luizbafilho) ([@luizbafilho](http://twitter.com/luizbafilho))

## License

GPL v3 License. &copy; 2014 Leon Maia & Luiz Filho
