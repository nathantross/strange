exports = this
exports.Notify = 
  changeCount: (user, inc) ->
    console.log "User's count:  " + Meteor.user().notifications[0].count
    console.log "ChangeCount Inc: " + inc
    userAttr = 
      _id: user._id
      'notifications.0.count': inc
    Meteor.call('changeCount', userAttr, (error, id)->
      console.log "Count is now " + Meteor.user().notifications[0].count
      if error
        alert(error.reason)
    )

  playSound: (user, filename) ->
    if user.notifications[0].sound
      document.getElementById("sound").innerHTML = "<audio autoplay=\"autoplay\"><source src=\"" + filename + ".mp3\" type=\"audio/mpeg\" /><source src=\"" + filename + ".ogg\" type=\"audio/ogg\" /><embed hidden=\"true\" autostart=\"true\" loop=\"false\" src=\"" + filename + ".mp3\" /></audio><!-- \"Waterdrop\" by Porphyr (freesound.org/people/Porphyr) / CC BY 3.0 (creativecommons.org/licenses/by/3.0) -->"

  toggleNavHighlight: (user, toggle)->
    unless user.notifications[0].isNavNotified == toggle
      userAttr = 
        _id: user._id
        'notifications.0.isNavNotified': toggle
      Meteor.call('toggleNavHighlight', userAttr, (error, id)->
        alert(error.reason) if error
      )

  toggleItemHighlight: (notification, toggle) ->
    unless notification.isNotified == toggle
      notAttr = 
        _id: notification._id
        isNotified: toggle
      Meteor.call('toggleItemHighlight', notAttr, (error, id)->
        alert(error.reason) if error
      )

  # Toggling the title
  toggleTitleFlashing: (toggle) ->
    Meteor.clearInterval(Session.get('intervalId'))
    unless Meteor.user().notifications[0].isTitleFlashing == toggle
      userAttr =
        _id: Meteor.userId()
        'notifications.0.isTitleFlashing': toggle
      $({})
        .queue((next)->
          Meteor.call('toggleTitleFlashing', userAttr, (error, id)->
            alert(error.reason) if error
          )
          next()
        )
        .queue((next)->
          Notify.resetTitle(toggle)
          next()
        )
    else 
      @resetTitle(toggle)

  resetTitle: (toggle) ->
    if toggle
      intervalId = @flashTitle()
      Session.set('intervalId', intervalId)
    else
      document.title = @defaultTitle()

  flashTitle: ->
    title = @defaultTitle(Meteor.user())
    Meteor.setInterval( () -> 
        newTitle = "New private message..."
        document.title = 
          if document.title == newTitle then title else newTitle
      , 2500)

  defaultTitle: ->
    notCount = Meteor.user().notifications[0].count
    if notCount > 0 then "Privy (" + notCount + " unread)" else "Privy"

  # Popup activates the popup notification 
  popup: ->
    # console.log "Started popup"
    $("#popup").slideDown "slow", ->
      Meteor.setTimeout(()-> 
          $("#popup").slideUp("slow")
        , 3000)

  # This logic determines how to display notifications
  activate: (notification, user) ->
    # console.log "Running activate"
    if notification.lastSenderId != user._id && notification?
      # Determine if user is in the notification's thread
      isInThread = @isInThread(Meteor.userId(), notification.threadId)

      # Notification depends on whether user is online, idle, 
      # in the notification's thread, or not in the thread
      if user.status.online
        unless isInThread 
          @popup() # can I pass notifica/tion into popup?
          @changeCount(user, 1)
          @toggleNavHighlight(user, true)
          @toggleItemHighlight(notification, true)

        # If the user's online, always play sound and toggle title
        @playSound(user, '/waterdrop')
        @toggleTitleFlashing(true)

  # trackChanges observes any changes in notifications and activates a response
  trackChanges: ->
    userId = if Meteor.isClient then Meteor.userId() else @userId
    if userId
      Notifications.find(
            userId: userId
          , 
            fields: 
              _id: 1
              updatedAt: 1
        ).observe(
          changed: (oldNotification, newNotification) ->
            userId = if Meteor.isClient then Meteor.userId() else @userId
            user = Meteor.users.findOne(userId)
            notification = Notifications.findOne(newNotification._id)
            Notify.activate(notification, user)
        )

  # Helper function that determines whether a user is in a thread
  isInThread: (userId, threadId)->
    thread = Threads.findOne(threadId)
    if thread
      for participant in thread.participants
        if participant.userId == userId
          return participant.isInThread
    false
    