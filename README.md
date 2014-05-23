oauth2-provider
===============

Provide a base class for OAuth2 Provider

## Supported Grant Types

1. authorization code
2. implicit
3. user password
4. client password

## Setup
Assume that you already instantiate a `provider` from my base class, you need to listen the following 3 paths from you app

``` coffeescript
  app.get "/dialog/authorize", provider.authorization()
  app.post "/dialog/authorize/decision", provider.decision()
  app.post "/oauth/token", provider.token()
```

For protected resource, you need to add a `passport` middleware to make sure bearer tokens are checked before your api processes

```coffeescript
  api.use '/', passport.authenticate "bearer", session:false
```

Note: your path names can be different; however, I will use the above names in this guide.

- - -

## How to use

### Client Password

Client Password grant type is used when the consumer need to make API calls to protected resources *as an application*, not *as a resource owner*. It's useful to get total online users for example (which not related to any particular user).

To use client password grant types, the consumer code need to do a `POST` to `{hostname}/oauth/token`

``` coffeescript
  body = {
    grant_type: 'client_credentials'
    client_id: client.clientId
    client_secret: client.clientSecret
    scope: '*'
  }

  request.post '{hostname}/oauth/token', {json:true, body}, (err, res, code)->
    res.statusCode.should.equal 200
    code.access_token.should.be.a 'string'
    code.token_type.should.equal 'Bearer'
    done()

```

The consumer should receive a json object with the following format:

``` json
  {
    "token_type": "Bearer",
    "access_token": "<your access token>"
  }
```

From now on, your consumer can call protected resource by adding a header in each request

```
  Authorization: Bearer <your access token>
```

**Note**: It's important to set `json:true` because the endpoint expects an `application/json` request content-type.

#### How it works:
#### 1. validation step
When a `POST` to `/oauth/token` is made, provider will verify your client credentials by calling `provider.validateClient(clientId, clientSecret, done)` which will asynchronously return the client object or `false` depend on the input's validity via `done` (which is an err-first node-style callback).

#### 2. token issue step
If valid, that request will login with the given client and call next middleware, where an access token is actually issued. 
In this step, `provider.exchangeClientCredentialsForToken(client, scope, done)` is called with client with `scope` is the requesting scope.
You will have to asynchronously return a new token as a string via done (which is also an err-first node-style callback).





