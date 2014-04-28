export NODE_ENV=testing

mocha --compilers coffee:coffee-script/register --reporter spec -G
#mocha debug --compilers coffee:coffee-script/register --reporter spec -G