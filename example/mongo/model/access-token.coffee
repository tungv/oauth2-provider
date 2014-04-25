mongoose = require 'mongoose'

schema = new mongoose.Schema {
  token: String             ## access token code
  client: String            ## client id
  user: String              ## user id
}


model = mongoose.model 'accessToken', schema