Provider = require 't-oauth2-provider'
mongoose = require 'mongoose'
fibrous = require 'fibrous'

require './model/grant.coffee'
require './model/access-token.coffee'

class MongoOAuthProvider extends Provider
  constructor: (config) ->
    @db =
      user: mongoose.model 'user'
      client: mongoose.model 'client'
      grant: mongoose.model 'grant'
      accessToken: mongoose.model 'accessToken'

    @exchangeMethods = ['basic', 'oauth2-client-password']

    super config, {passport: require 'passport'}

  ## this should be rewrite as an external module
  getCode: (length)-> Provider.uid(length)

  issueGrantCode: (client, redirectURI, user, ares, callback) ->
    code = @getCode(16)
    grant = new @db.grant {
      code
      redirectURI
      client: client.id
      user: user.id
    }

    grant.save (err)->
      return callback err if err
      callback null, code

  issueImplicitToken: (client, user, ares, callback) ->
    code = @getCode(32)
    accessToken = new @db.accessToken {
      token: code
      client: client.clientId
      user: user.id
    }

    accessToken.save (err)->
      return callback err if err
      callback null, code

  exchangeCodeForToken: (client, code, redirectURI, done) ->
    @db.grant.findOne {code}, (err, grant)=>
      return done err if err
      return done err, false if client.id isnt grant.client or redirectURI isnt grant.redirectURI

      token = @getCode()
      accessToken = new @db.accessToken {
        token
        user: grant.user
        client: grant.client
      }

      accessToken.save (err)->
        return done err if err
        done null, token

  exchangePasswordForToken: (client, username, password, scope, done) ->
    fibrous.run =>
      ## validating client
      clientId = client.clientId
      clientSecret = client.clientSecret
      localClient = @db.client.sync.find clientId

      return false unless localClient?.clientSecret is clientSecret

      ## validating user
      user = @db.user.sync.find username
      return false unless user?.password is password

      ## response a access token
      token = @getCode()
      accessToken = new @db.accessToken {
        token
        user: user.id
        client: clientId
      }

      accessToken.save()
      return token
    , done


  findClient: (clientId, redirectURI, cb)->
    @db.client.findOne {clientId}, (err, client)->
      return cb err if err
      ## WARNING: For security purposes, it is highly advisable to check that
      ##          redirectURI provided by the client matches one registered with
      ##          the server.  For simplicity, this example does not.  You have
      ##          been warned.
      cb null, client, redirectURI

  validateUser: (username, password, done)->
    fibrous.run ()->
      ## password must be provided
      return false unless password
      user = mongoose.model('user').sync.findOne {username}
      return false if user?.password isnt password

      return user
    , done

  validateClient: (clientId, clientSecret, done)->
    fibrous.run ()->
      ## clientSecret must be provided
      return false unless clientSecret
      client = mongoose.model('client').sync.findOne {clientId}
      return false if client?.clientSecret isnt clientSecret

      return client
    , done

  validateToken: (accessToken, done)->
    fibrous.run ->
      token = mongoose.model('accessToken').sync.findOne {token: accessToken}
      ## invalid or expired token
      return false unless token

      ## token provided to a user (via login)
      if token.user?
        user = mongoose.model('user').sync.findById token.user
        ## invalid user (user might be removed since login)
        return false unless user
        ## to keep this example simple, restricted scopes are not implemented,
        ## and this is just for illustrative purposes
        return [user, scope:'*']

      ## token provided to a client (consumer)
      client = mongoose.model('client').sync.findById token.client
      return false unless client
      ## to keep this example simple, restricted scopes are not implemented,
      ## and this is just for illustrative purposes
      return [client, scope:'*']



    , (err, data)->
      return done err if err
      return done null, data if typeof data is 'Boolean'
      return done null, data[0], data[1]



  ## serialize client into session storage (can be overwrite)
  serializeClient: (client, done)-> done null, client.id

  ## deserialize client from session storage (can be overwrite)
  deserializeClient: (id, done)->
    ## get client (consumer)
    @db.client.findById id, (err, client)->
      return done err if err
      done null, client

  serializeUser: (user, done) ->
    done null, user.id
    return

  deserializeUser: (id, done) ->
    mongoose.model('user').findById id, (err, user) ->
      done err, user
      return


module.exports = MongoOAuthProvider