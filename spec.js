(function() {
  'use strict';

  var a = Amber;

  describe('A server', function() {
    var server, socket;

    function connect() {
      server.connect();
      socket.emit('open', a.Event({ object: socket }));
      socket.emit('connect', {});
    }

    beforeEach(function() {
      socket = a.Base();

      ['request', 'watch', 'unwatch', 'send', 'close', 'connect'].forEach(function(name) {
        socket[name] = jasmine.createSpy(name);
      });

      server = a.Server({
        socket: socket
      });
    });

    it('generates the correct asset store URL', function() {
      server.url = 'localhost:88/path/';
      expect(server.assetStoreURL).toBe('http://localhost:88/path/api/asset/');
    });

    it('generates the correct WebSocket URL', function() {
      server.url = 'localhost:88/path/';
      expect(server.socketURL).toBe('ws://localhost:88/path/');
    });

    it('is not connected when constructed', function() {
      expect(server.connected).toBe(false);
    });

    it('connects using the socket', function() {
      server.connect();
      expect(socket.connect.calls.allArgs()).toEqual([[]]);
      expect(server.connected).toBe(false);
    });

    it('responds to the open event', function() {
      server.connect();
      socket.emit('open', a.Event({ object: socket }));

      expect(socket.send.calls.allArgs()).toEqual([
        ['connect', jasmine.any(Object)]
      ]);
      expect(server.connected).toBe(false);
    });

    it('sends the last user and token with the connect packet', function() {
      server.lastUser = 'aUser';
      server.token = 'aToken';

      server.connect();
      socket.emit('open', a.Event({ object: socket }));

      expect(socket.send.calls.allArgs()).toEqual([
        ['connect', { user: 'aUser', token: 'aToken' }]
      ]);
      expect(server.connected).toBe(false);
    });

    it('responds to the connect event', function() {
      connect();
      expect(server.connected).toBe(true);
    });

    it('captures the token and user upon connection', function() {
      server.lastUser = 'aUser';

      server.connect();
      socket.emit('open', a.Event({ object: socket }));
      socket.emit('connect', { token: 'aToken', user: { scratchId: 1 } });

      expect(server.token).toBe('aToken');
      expect(server.user).toBeDefined();
      expect(server.user.name).toBe('aUser');
      expect(server.user.group).toBe('default');
      expect(server.user.scratchId).toBe(1);
    });

    it('retrieves user information', function() {
      connect();

      var promise = server.getUserInfo('aUser');
      expect(socket.send.calls.allArgs()).toE
    });
  });

}());
