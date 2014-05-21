Template.showThread.helpers
  isMuted: ->
    Threads.findOne(@threadId)?.participants[@userIndex].isMuted

  isBlocked: ->
    if @threadId? && @userIndex?
      blockedIndex = if @userIndex == 1 then 0 else 1
      blockedId = Threads.findOne(@threadId).participants[blockedIndex].userId
      return _.indexOf(Meteor.user().blockedIds, blockedId) > -1

Template.showThread.events
  'click .load-more': (e)->
    e.preventDefault()
    Session.set('bodyScrollTop', $('body').scrollTop())
    Session.set('msgWrapHeight', $('#msg-wrap').height())
    Router.go(@nextPath)

  'click #leave-chat': (e) ->
    Notify.toggleIsMuted(true, "left the chat", @threadId, @userIndex)

  'click #enter-chat': (e) ->
    Notify.toggleIsMuted(false, "entered the chat", @threadId, @userIndex)

  'click #block-user': (e)->
    e.preventDefault()
    $('#block-user-alert').slideDown "slow"

    blockedIndex = if @userIndex == 1 then 0 else 1
    blockedId = Threads.findOne(@threadId).participants[blockedIndex].userId

    mixpanel.track("Block user: clicked", {
      threadId: @threadId 
      blockerId: Meteor.userId()
      blockedId: blockedId
    })

  'click #unblock-user': (e)->
    e.preventDefault()
    Notify.toggleBlock(false, @threadId, @userIndex)
