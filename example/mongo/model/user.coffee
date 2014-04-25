mongoose = require 'mongoose'

schema = new mongoose.Schema {
  username: String
  password: String
  name: String
}

model = mongoose.model 'user',  schema