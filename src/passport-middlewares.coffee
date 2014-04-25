LocalStrategy = require("passport-local").Strategy
BasicStrategy = require("passport-http").BasicStrategy
ClientPasswordStrategy = require("passport-oauth2-client-password").Strategy
BearerStrategy = require("passport-http-bearer").Strategy

module.exports = (passport, provider)->
  ###
  LocalStrategy

  This strategy is used to authenticate users based on a username and password.
  Anytime a request is made to authorize an application, we must ensure that
  a user is logged in before asking them to approve the request.
  ###
  passport.use new LocalStrategy (username, password, done)->
    provider.validateUser username, password, done

  ## passport session serialization
  passport.serializeUser (user, done) ->
    provider.serializeUser user, done

  passport.deserializeUser (sessionString, done) ->
    provider.deserializeUser sessionString, done

  ###
  BasicStrategy & ClientPasswordStrategy

  These strategies are used to authenticate registered OAuth clients.  They are
  employed to protect the `token` endpoint, which consumers use to obtain
  access tokens.  The OAuth 2.0 specification suggests that clients use the
  HTTP Basic scheme to authenticate.  Use of the client password strategy
  allows clients to send the same credentials in the request body (as opposed
  to the `Authorization` header).  While this approach is not recommended by
  the specification, in practice it is quite common.
  ###

  passport.use new BasicStrategy (clientId, clientSecret, done) ->
    provider.validateClient clientId, clientSecret, done

  passport.use new ClientPasswordStrategy (clientId, clientSecret, done) ->
    provider.validateClient clientId, clientSecret, done

  ###
  BearerStrategy

  This strategy is used to authenticate either users or clients based on an access token
  (aka a bearer token).  If a user, they must have previously authorized a client
  application, which is issued an access token to make requests on behalf of
  the authorizing user.
  ###
  passport.use new BearerStrategy (accessToken, done) ->
    provider.validateToken accessToken, done
