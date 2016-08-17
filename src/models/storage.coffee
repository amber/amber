
class Storage
  set: (k, v) -> Promise.resolve localStorage.setItem k, v
  get: (k) -> Promise.resolve localStorage.getItem k
  remove: (k) -> Promise.resolve localStorage.removeItem k
  clear: -> Promise.resolve localStorage.clear()

dummyStorage =
  m: new Map
  set: (k, v) -> Promise.resolve @m.set k, v
  get: (k) -> Promise.resolve @m.get k
  remove: (k) -> Promise.resolve @m.delete k
  clear: (k) -> Promise.resolve @m.clear()

module.exports = try new Storage localStorage catch then dummyStorage
