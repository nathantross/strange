# Start monitoring whether a user is idle
Meteor.startup ->
  Notify.trackChanges()
  if Meteor.isClient
    Deps.autorun ->
      try
        UserStatus.startMonitor
          threshold: (15*1000) # Time until user is idle
          interval: (15*1000)
        @pause()

# Check in/out depending on whether user is idle
if Meteor.isClient
  Deps.autorun ->
    try
      user = Meteor.user()
      if user
        if user.status?.idle && !Session.get('isIdle')
          # mixpanel.track("User: is idle")  
          note = Notes.findOne(currentViewer: Meteor.userId())
          if note
            Meteor.call 'unlockAll', {}, (err) ->
              return console.log(err) if err
              Session.set("currentNoteId", false)

          # If idle, check out of all threads
          if user.inThreads.length > 0
            for threadId in user.inThreads
              Notify.toggleCheckIn(threadId, false)

          Session.set('isIdle', true)

        else if !user.status?.idle && Session.get('isIdle')
          # mixpanel.track("User: is not idle")
          url = window.location.pathname.split("/")

          # Check into their current thread if they're in a thread
          if url[1] == "threads" 
            threadId = url[2]
            Notify.toggleCheckIn(threadId, true)

            # Turn the flashing title off and the highlighted item
            notification = Notifications.findOne
                userId: user._id
                threadId: threadId
            Notify.toggleItemHighlight(notification, false) if notification
            Notify.toggleTitleFlashing(false)

          # Check into their current note if they're in a note
          if url[1] == "notes"
            Notify.toggleLock(Session.get("currentNoteId"), true)

          Session.set('isIdle', false)

if Meteor.isServer
  Accounts.onCreateUser (options, user) ->
    # Setup notifications tracking for the user
    user.notifications = [
      count: 0
      email: true
      sound: true
      sms: true
      isTitleFlashing: false
      isNavNotified: false
    ]

    user.profile = options.profile if options.profile
    user.services.password.srp = options.srp if options.srp
    
    # Set user's email if user created account w/Facebook or Google
    if user.services?
      service = _.keys(user.services)[0]
      if service == "facebook" || service == "google"
        if user.services[service].email?
          user.emails = [{
            address: user.services[service].email, 
            verified: true
          }]          
        else
          console.log "#{service} account has no email attached"
          throw new Meteor.Error(500, "#{service} account has no email attached")

    return user



Meteor.methods
  toggleNavHighlight: (userAttr) ->
    userId = userAttr._id

    unless Meteor.userId()
      throw new Meteor.Error(401, "You have to log in to make this change.")

    unless userId == Meteor.userId()
      throw new Meteor.Error(401, "You can't make this change to other people's profiles")

    now = new Date().getTime()
    userUpdate = _.extend(_.pick(userAttr, 'notifications.0.isNavNotified'),
      updatedAt: now
    )
    Meteor.users.update(
        userId
      ,
        $set: userUpdate
    )

  toggleTitleFlashing: (toggle) ->
    unless Meteor.userId()
      throw new Meteor.Error(401, "You have to log in to make this change.")

    unless typeof toggle == "boolean"
      throw new Meteor.Error 401, "Toggle must be a boolean"
        
    now = new Date().getTime()
    Meteor.users.update Meteor.userId(),
      $set: 
        'notifications.0.isTitleFlashing': toggle
        updatedAt: now

    toggle

  changeCount: (inc)->
    unless Meteor.userId()
      throw new Meteor.Error 401, "You have to log in to make this change."

    unless typeof inc == "number" && inc % 1 == 0 
      throw new Meteor.Error 401, "#{inc} is not an integer."

    now = new Date().getTime()
    Meteor.users.update Meteor.userId(),
      $set: 
        updatedAt: now
      $inc: 
        'notifications.0.count': inc

  getUserAttr: (userId) ->
    if Meteor.isServer
      user = Meteor.users.findOne(userId)
      isIdle = 
        if user.status?.online? then user.status?.idle == true else !online?
      avatar = user.profile.avatar || false
        
      return (
        isIdle: isIdle
        avatar: avatar
      )

  getAvatar: (userId) ->
    if Meteor.isServer
      user = Meteor.users.findOne(userId)      
      avatar = user.profile.avatar || false
        
  setAvatar: (avatarAttr) ->
    user = Meteor.user()

    unless user
      throw new Meteor.Error(401, "You have to log in to make this change.")

    Meteor.users.update user._id,
      $set:
        'profile.avatar': avatarAttr

    # Update the avatar in each thread
    threads = Threads.find
      participants:
        $elemMatch:
          userId: user._id

    if threads 
      threads.forEach (thread) ->
        index = Notify.userIndex(thread._id)
        modifier = $set: {}
        modifier.$set["participants." + index + ".avatar"] = avatarAttr
        Threads.update(thread._id, modifier)
        
        # Update the notification when the user is the only one in thread
        if thread.participants.length == 1 
            Notifications.update
              userId: user._id
              threadId: thread._id
            ,
              $set: 
                lastAvatar: avatarAttr
            , 
              multi: true

        # Update the user's avatar in other people's notifications
        if Meteor.isServer
          Notifications.update
              userId: 
                $ne: user._id
              threadId: thread._id
            ,
              lastAvatar: avatarAttr

    avatarAttr


  toggleBlockUser: (toggle, blockedId) ->

    # check for invalid inputs
    unless Meteor.userId()
      throw new Meteor.Error(401, "You have to log in to make this change.")

    unless typeof toggle == "boolean"
      throw new Meteor.Error(400, "Toggle must be a boolean.")

    unless blockedId
      throw new Meteor.Error(404, "You must included a blockedId.")      

    if Meteor.isServer
      unless Meteor.users.findOne(blockedId)
        throw new Meteor.Error(404, "This user does not exist.")   

    # Add/remove blockedId to/from blocker's block list
    if toggle
      Meteor.users.update Meteor.userId(),
        $addToSet:
          blockedIds: blockedId
          
    else
      Meteor.users.update Meteor.userId(),
        $pull:
          blockedIds: blockedId

    # Add/remove blockerId to/from blocker's blocker list
    if Meteor.isServer
      if toggle
        Meteor.users.update blockedId,
          $addToSet:
            blockerIds: Meteor.userId()
      else
        Meteor.users.update blockedId,
          $pull:
            blockerIds: Meteor.userId()

  toggleFirstSkip: ->
    unless Meteor.user()
      throw new Meteor.Error(401, "You have to log in to make this change.")

    Meteor.users.update Meteor.userId(),
      $set:
        'notifications.0.firstSkip': true

  toggleSound: (toggle) ->
    unless Meteor.user()
      throw new Meteor.Error(401, "You have to log in to make this change.")

    unless typeof toggle == "boolean"
      throw new Meteor.Error(400, "Toggle must be a boolean.")

    Meteor.users.update Meteor.userId(),
      $set:
        'notifications.0.sound': toggle
