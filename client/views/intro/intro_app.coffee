Template.intro.events
  'click img': ->
    avatarUrl = @.toString()
    Meteor.call 'setAvatar', avatarUrl, (error) ->
      return console.log (error.reason) if error 

Template.intro.avatars = [
  "https://s3-us-west-2.amazonaws.com/privy-application/avatar_1.png",
  "https://s3-us-west-2.amazonaws.com/privy-application/avatar_2.png",
  "https://s3-us-west-2.amazonaws.com/privy-application/avatar_3.png",
  "https://s3-us-west-2.amazonaws.com/privy-application/avatar_4.png", 
  "https://s3-us-west-2.amazonaws.com/privy-application/avatar_5.png", 
  "https://s3-us-west-2.amazonaws.com/privy-application/avatar_6.png"
]

Template.intro.rendered = ->
  Notify.popup("#successAlert", "Welcome to Strange! Let's take a tour.", true)

Template.intro1.events
  'click .intro-finish': ->
    mixpanel.track("Tour(1): exited")

  'click .intro-next': ->
    mixpanel.track("Tour(1): continued")
    

Template.intro2.events
  'click .intro-finish': ->
    mixpanel.track("Tour(2): exited")

  'click .intro-next': ->
    mixpanel.track("Tour(2): continued")


Template.intro3.events
  'click .intro-next': ->
    mixpanel.track("Tour(3): completed")
