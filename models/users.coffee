# Start monitoring whether a user is idle
Meteor.startup ->
  Notify.trackChanges()
  if Meteor.isClient
    Deps.autorun ->
      try
        UserStatus.startMonitor
          threshold: (15*1000) # Time until user is idle
          interval: 5000
        @pause()

# Check in/out depending on whether user is idle
if Meteor.isClient
  Deps.autorun ->
    try
      user = Meteor.user()
      if user
        if UserStatus.isIdle() && user.inThreads.length > 0
          for threadId in user.inThreads
            Notify.toggleCheckIn(threadId, false)
        else unless UserStatus.isIdle()
          url = window.location.pathname.split("/")
          if url[1] == "threads" 
            threadId = url[2]
            Notify.toggleCheckIn(threadId, true)
            notification = Notifications.findOne
                userId: user._id
                threadId: threadId
            Notify.toggleItemHighlight(notification, false) if notification
            Notify.toggleTitleFlashing(false)

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

  toggleTitleFlashing: (userAttr) ->
    userId = userAttr._id

    unless Meteor.userId()
      throw new Meteor.Error(401, "You have to log in to make this change.")

    unless userId == Meteor.userId()
      throw new Meteor.Error(401, "You can't make this change to other people's profiles")
        
    now = new Date().getTime()
    userUpdate = _.extend(_.pick(userAttr, 'notifications.0.isTitleFlashing'),
      updatedAt: now
    )
    Meteor.users.update(
        userId
      ,
        $set: userUpdate
    )

  changeCount: (userAttr) ->
    userId = userAttr._id

    unless Meteor.userId()
      throw new Meteor.Error(401, "You have to log in to make this change.")

    unless userId == Meteor.userId()
      throw new Meteor.Error(401, "You can't make this change to other people's profiles")

    now = new Date().getTime()
    userUpdate = _.pick(userAttr, 'notifications.0.count')
    
    Meteor.users.update(userId,
      $set: 
        updatedAt: now
      $inc: userUpdate
    )