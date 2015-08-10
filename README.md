# Oomph 
[![Build Status](https://travis-ci.org/Kenspeckled/oomph.svg?branch=master)](https://travis-ci.org/Kenspeckled/oomph)
<!-- [![Code Climate](https://codeclimate.com/github/Kenspeckled/oomph/badges/gpa.svg)](https://codeclimate.com/github/Kenspeckled/oomph) -->

Object Oriented javascript application framework

## Work In Progress
This project has changed significantly since conception and is headed towards a new major release that will turn it towards a light-weight framework. Sit tight, still a lot of work to do!

---

## Add a little oomph to your project 

```
npm install --save oomph
```

Quick how to:

```
# Require oomph 
oomph = require 'oomph'

# Tell oomph which adaptor to use:
oomph.adaptor = require 'oomph-redis-adaptor'

# Create a class - oomph.createClass(name, classAttributes)
Address = oomph.createClass 'Address',
  streetAddressOne:
    dataType: 'string'
    validates:
      presence:
        prompt: 'Please enter Address line one'
  streetAddressTwo:
    dataType: 'string'

# Add methods to that class
Address.typeOfClass = -> console.log 'I am an Address'
Address::fullAddress = -> @streetAddressOne + ' ' + @streetAddressTwo

#For multiple methods you might want to mass assign like this:
Address::[k] = v for own k, v of {
  someInstanceMethod: -> 
    console.log 'some instance method'
}
Address[k] = v for own k, v of {
  someClassMethod: -> 
    console.log 'some class method'
}

# Classes can also be extended with another class (or an extended version of the same class)
# This is particularly useful for defining server/client variants without exposing code
class anotherClass
  @anotherClassMethod: -> console.log 'another class method'
  anotherInstanceMethod: -> console.log 'another instance method'

Address.extend(anotherClass)


#An initialize method defined on the prototype of a class will be called on initalization.
Address::initialize = -> console.log "init!"
new Address( streetAddressOne: '11 Downing Street') 
#> "init!"
#> { streetAddressOne: '11 Downing Street' }
```


## Scope
This project aims to provide a Object Oriented Javascript application framework that attempts to find as much unity as possible between serverside and clientside code. The aim is to decrease duplication of effort as well as code by:
  * building views that can be rendered by both server and client
  * constructing server and client models with common interfaces so client and server can share actions
  * generating (configurable) RESTful APIs for every model
  * providing named routes and a single set of route configurations

## To Do
* Full framework file structure implemented
* Better conceptual framework for "Actions"
* Tests
* File Generators 

## Licence

[Apache License 2.0](https://github.com/Kenspeckled/oomph/blob/master/LICENSE)
