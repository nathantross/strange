Template.notification.helpers
  lastMessagePreview: ->
    textPreview @lastMessage, 20

  originalNotePreview: -> 
    textPreview @originalNote, 20

  sender: ->
    user = Meteor.users.findOne @lastAvatarId
    isOnline =
      if user.status?.online && !user.status?.idle && user._id != Meteor.userId() then "•" else ""

    return(
      avatar: user.profile.avatar
      isOnline: isOnline
    )

  textPreview = (message, previewLength) ->
    if previewLength < message.length
      message.slice(0, previewLength) + "..."
    else
      message
    
Template.notification.events
  'click .archive': (e)->
    e.preventDefault()
    Meteor.call "toggleArchived", @_id, true, (err, notId)->
      console.log err if err       
