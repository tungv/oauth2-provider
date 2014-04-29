request = require 'request'

module.exports = (mockup)->
  client = mockup.data.clients['awesome-app']
  PROVIDER_BASEURL = mockup.config.PROVIDER_BASEURL

  describe 'Client Credentials', ->
    applicationLogin = (client, cb)->
      query = {
        grant_type: 'client_credentials'
        client_id: client.clientId
        client_secret: client.clientSecret
        scope: '*'
      }

      request.post {
        uri: "#{PROVIDER_BASEURL}/oauth/token"
        json: query
      }, cb

    apiRequest = mockup.methods.apiRequest


    describe 'Successful scenario', ->
      resp = {}
      it 'should return 200 code', (done)->
        applicationLogin client, (err, _resp, body)->
          resp = _resp
          resp.statusCode.should.equal 200
          done()

      it 'should contain an access_token', ->
        resp.body.access_token.should.be.a 'string'

      it 'should contain an token_type', ->
        resp.body.token_type.should.equal 'Bearer'

      it 'should allow returned access_token to access protected resources', (done)->
        apiRequest resp.body, (err, resp, body)->
          body.name.should.equal 'correct'
          done()

    describe 'Failure scenario', ->

      it 'should not return access_token on invalid credentials', (done)->
        applicationLogin {clientId: client.id, clientSecret: 'hacker'}, (err, resp, body)->
          resp.statusCode.should.equal 401
          body.should.equal 'Unauthorized'
          done()


      it 'should not allow invalid access_token to access protected resources', (done)->
        apiRequest {
          token_type: 'Bearer'
          access_token: '1nv@l1D-@cc355'
        }, (err, resp, body)->
          resp.statusCode.should.equal 401
          body.should.equal 'Unauthorized'
          done()
