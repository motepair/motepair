var WebSocket = require('ws');

module.exports = Socket

var EventEmitter = require('events').EventEmitter
var inherits = require('inherits')
var once = require('once')

var RECONNECT_TIMEOUT = 5000

inherits(Socket, EventEmitter)
var emit = WebSocket.super_.prototype.emit

function Socket (url) {
  this._init(url)
}

Socket.prototype.send = function (message) {
  this._ws.send(message)
}


Socket.prototype.destroy = function (onclose) {
  if (onclose) this.once('close', onclose)
  try {
    this._ws.close()
  } catch (err) {
    this._onclose()
  }
}

Socket.prototype._init = function (url) {
  this._ws = new WebSocket(url)
  this._ws.onopen = this._onopen.bind(this)
  this._ws.onmessage = this._onmessage.bind(this)
  this._ws.onclose = this._onclose.bind(this)
  this._ws.onerror = once(this._onerror.bind(this))
}

Socket.prototype._onopen = function () {
  this.emit("open");
}

Socket.prototype._onerror = function (err) {
  this.emit('error', err)
}


Socket.prototype._onmessage = function (event) {
  var json = JSON.parse(event.data),
      event = json.event,
      data = json.data;

  emit.apply(this, [event, data])
}

Socket.prototype._onclose = function () {
}


Socket.prototype.write = function(event, message) {
  var data = { event: event, data: message}

  this.send(JSON.stringify(data))
}



