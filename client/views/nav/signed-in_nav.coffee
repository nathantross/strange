Template.signedInNav.helpers
  isIntro: ->
    disabledPaths = ['intro', 'intro_1', 'intro_2', 'intro_3']
    currentPath = Router.current().path.split('/')[1]
    
    if currentPath[1] == 'notes' && !currentPath[2] && currentPath[2] != "new"
      return true 
    
    _.indexOf(disabledPaths, currentPath) != -1

  isNavNotified: ->
    user = Meteor.user().notifications
    if user && user[0].isNavNotified then "nav-notify" else ""

    
Template.signedInNav.events
  'click #addNote': ->
    mixpanel.track("Nav: clicked add note")

  'click #dropdown-li': (event)->
    Notify.toggleNavHighlight(false)
    Notify.toggleTitleFlashing(false)
    mixpanel.track("Nav: clicked comment bubble")

