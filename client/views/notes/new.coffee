Template.newNote.events
  "submit form": (e) ->
    e.preventDefault()

    Meteor.call 'createThread', {}, (error, threadId) -> 
      return alert(error.reason) if error
      
      noteAttr = 
        body: $(e.target).find("[name=notes-body]").val()
        threadId: threadId

      Meteor.call 'createNote', noteAttr, (error, threadId) -> 
        return alert(error.reason) if error

        # Creates new note
        message = 
          body: noteAttr.body
          threadId: threadId
          lastMessage: noteAttr.body       

        Meteor.call 'createMessage', message, (error, id) ->
          return alert(error.reason) if error 

          Meteor.call 'createNotification', message, (error, id)->
            alert(error.reason) if error

    Router.go "feed"


  "keyup input": (e)->
      val = $(e.target).find("[name=notes-body]").prevObject[0].value
      len = val.length
      $("#charNum").text(len + "/65")
