_ = require 'lodash'
Provider = require 't-oauth2-provider'

class InMemoryProvider extends Provider
  constructor: ()->
    @db =
      user: {
        'adw12asd23': {
          username: 'admin'
          password: 'admin'
          name: 'Admin'
          id: 'adw12asd23'
        }
      }
      client: {
        'awesome-app': {
          clientId: 'awesome-app'
          clientSecret: 'awesome-secret'
          name: 'Awesome'
        }
      }
      grant: {}
      accessToken: {}

    @exchangeMethods = ['basic', 'oauth2-client-password']
    super {}, {passport: require 'passport'}

  ## supporting method
  newToken: (client, user)->
    token = Provider.uid 32

    @db.accessToken[token] = {token, client, user}
    return token

  findUserByUsername: (username)->
    _.filter @db.user, (user)-> user.username is username
    .pop()

  issueGrantCode: (client, redirectURI, user, ares, callback)->
    code = Provider.uid 16
    @db.grant[code] = {
      code
      redirectURI
      client: client.id
      user: user.id
    }

    callback null, code

  issueImplicitToken: (client, user, ares, callback) ->
    callback null, @newToken client.clientId, user.id

  exchangeCodeForToken: (client, code, redirectURI, done) ->
    grant = @db.grant[code]

    return done null, false if client.id isnt grant.client or redirectURI isnt grant.redirectURI

    done null, @newToken grant.client, grant.user

  exchangePasswordForToken: (client, username, password, scope, done)->
    try
    ## validating client
      clientId = client.clientId
      clientSecret = client.clientSecret
      localClient = @db.client[clientId]

      return done null, false unless localClient?.clientSecret is clientSecret

      ## validating user
      user =  @findUserByUsername username

      return done null, false unless user?.password is password

      ## provide new token
      return done null, @newToken clientId, user.id

    catch ex
      done ex

  findClient: (clientId, redirectURI, cb)->
    ## WARNING: For security purposes, it is highly advisable to check that
    ##          redirectURI provided by the client matches one registered with
    ##          the server.  For simplicity, this example does not.  You have
    ##          been warned.
    cb null, @db.client[clientId], redirectURI

  validateUser: (username, password, done)->
    ## password must be provided
    return done null, false unless password
    user = @findUserByUsername username

    return done null, false if user?.password isnt password

    return done null, user

  validateClient: (clientId, clientSecret, done)->
    return done null, false unless clientSecret
    client = @db.client[clientId]
    return done null, false if client?.clientSecret isnt clientSecret

    return done null, client

  validateToken: (accessToken, done)->
    token = @db.accessToken[accessToken]
    return done null, false unless token

    ## token provided to a user (via login)
    if token.user?
      ## find user by user id
      user = @db.user[token.user]

      ## invalid user (user might be removed since login)
      return done null, false unless user

      ## to keep this example simple, restricted scopes are not implemented,
      ## and this is just for illustrative purposes
      return done null, user, scope:'*'

    ## token provided to a client (consumer)
    ## find client by id
    client = @db.client[token.client]
    return done null, false unless client
    ## to keep this example simple, restricted scopes are not implemented,
    ## and this is just for illustrative purposes
    return done null, client, scope:'*'

  ## serialize client into session storage (can be overwrite)
  serializeClient: (client, done)-> done null, client.clientId

  ## deserialize client from session storage (can be overwrite)
  deserializeClient: (id, done)-> done null, @db.client[id]

  serializeUser: (user, done) -> done null, user.id

  deserializeUser: (id, done) ->  done null, @db.user[id]

module.exports = InMemoryProvider