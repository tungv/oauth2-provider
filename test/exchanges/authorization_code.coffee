## make sure user has logged in
#  before (done)->
#    request.post {
#      uri: "#{PROVIDER_BASEURL}/login"
#      form:
#        username: user.username
#        password: user.password
#    }, (err, r, body)->
#      logger.debug 'body', body
#      done()

request = require 'request'

module.exports = (mockup)->
  PROVIDER_BASEURL = mockup.config.PROVIDER_BASEURL
  user = mockup.data.users['adw12asd23']
  client = mockup.data.clients['awesome-app']

  jar = request.jar()
  request = request.defaults({jar})

  userLogin = (user, cb)->
    request.post {
      uri: "#{PROVIDER_BASEURL}/login"
      form:
        username: user.username
        password: user.password
    }, cb




  describe 'Authorization Code', ->
    describe 'Successful scenario', ->
      before (done)->
        userLogin user, done

      transactionId = ''
      grantCode = ''
      token = {}
      apiRequest = mockup.methods.apiRequest

      it 'should return decision form', (done)->
        request.get {
          uri: PROVIDER_BASEURL + '/dialog/authorize'
          qs: {
            response_type: 'code'
            redirect_uri: client.redirectURI
            scope: 'email'
            client_id: client.clientId
          }
          json: true
        }, (err, resp, body) ->
          #console.log 'resp.statusCode', resp.statusCode
          #console.log 'body', body
          resp.statusCode.should.equal 200
          body.transactionID.should.be.a 'string'
          transactionId= body.transactionID
          done()

      it 'should redirect to registered uri', (done)->
        request.post {
          uri: PROVIDER_BASEURL + '/dialog/authorize/decision'
          form:
            transaction_id: transactionId
        },(err, resp)->
          resp.statusCode.should.equal 302
          location = resp.headers.location
          parts = location.split(client.redirectURI + '?code=')
          parts[0].should.equal ''
          grantCode = parts[1]
          done()

      it 'should return valid grant code', ->
        grantCode.should.be.a 'string'

      it 'should exchange grant code for access token', (done)->
        request.post {
          uri: PROVIDER_BASEURL + '/oauth/token'
          json: true
          body:
            grant_type: 'authorization_code'
            code: grantCode
            redirect_uri: client.redirectURI
            client_id: client.clientId
            client_secret: client.clientSecret
        }, (err, resp, body)->
          resp.statusCode.should.equal 200
          body.access_token.should.be.a 'string'
          token =
            token_type : 'Bearer'
            access_token: body.access_token
          done()

      it 'should return valid access token (more than 5 characters in length)', ->
        token.access_token.should.be.a 'string'
        token.access_token.length.should.gte 5

      it 'should allow returned token to access protected resources', (done)->
        apiRequest token, (err, resp, body)->
          body.name.should.equal 'correct'
          done()



