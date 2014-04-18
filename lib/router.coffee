# Provide the router with the name of a loading template
Router.configure 
  layoutTemplate: "layout"
  yieldTemplates:
    'navbar':
      to: 'navRegion'
  loadingTemplate: "loading"
  notFoundTemplate: 'notFound'
  waitOn: -> 
    Meteor.subscribe 'userData'
    Meteor.subscribe 'notifications'
    Meteor.subscribe 'threads' #enables switching between threads

Router.map ->
  # Sets route for Index to '/' for the application
  @route "index",
    path: "/"
    onBeforeAction: ->
      document.title = "Privy"
      Session.set("isTrackingChanges", false)
  
  # User Routes    
  @route "editUser",
    path: "/profile/edit"

  @route "termsUrl",
    path: "/terms-of-use"

  @route "privacyUrl",
    path: "/privacy-policy"

  @route "contact",
    path: "/contact" 


  # Note Routes
  @route "newNote",
    path: "/notes/new"

  @route "feed",
    path: "/notes" 
    controller: FeedController


  # Thread Route
  @route "showThread",
    path: "/threads/:_id"
    controller: showThreadController

  @route "faq",
    path: "/faq"
  

requireLogin = (pause)-> 
  unless Meteor.user() 
    @render( if Meteor.loggingIn() then @loadingTemplate else "accessDenied" )
    pause()
  return

loggedOutPages = ["index", "register", "termsUrl", "privacyUrl", "entrySignUp", "entrySignIn", "resetPassword", "forgotPassword"]

Router.onBeforeAction requireLogin,
  except: loggedOutPages