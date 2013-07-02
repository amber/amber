post = (post) ->
    edit = =>
        update = =>
            body.richText = parse post.body = editor.text
            container.addClass('pending').add(spinner = new Container('d-r-post-spinner'))
            @request 'forums.post.edit',
                post$id: post.id,
                body: editor.text
            , ->
                container.removeClass('pending').remove(spinner)
            cancel()

        cancel = =>
            container.replace(editor, body).remove(updateButton).remove(cancelButton)
            editButton.show()

        return unless post.id
        container.replace(body, editor = new TextField.Multiline('d-textfield d-r-post-editor').setAutoSize(true).setText(post.body))
            .add(updateButton = new Button().setText(tr 'Update Post').onExecute(update))
            .add(cancelButton = new Button('d-button light').setText(tr 'Cancel').onExecute(cancel))
        editButton.hide()
        editor.select()

    username = @user?.name
    container = new Container('d-r-post')
    container.add(editButton = new Button('d-r-edit-button d-r-post-edit').onExecute(edit))
    @authenticate post.authors, editButton
    container
        .add(users = new Label('d-r-post-author'))
        .add(body = new Label('d-r-post-body').setRichText(parse post.body))
    for author in post.authors
        if users.children.length
            users.add(new Label().setText(', '))
        users.add(new Link().setView('user.profile', author)
            .add(new Label().setText(author)))
    container.usePostId = (id) ->
        post.id = id

    return container

replyForm = (topicId) ->
    post = =>
        return unless topicId
        username = @user.name
        newPost = new Container('d-r-post-list')
            .add(container = @template('post',
                authors: [username],
                body: body.text
            ).addClass('pending'))
            .add(spinner = new Container('d-r-post-spinner'))
        postForm.parent.insert(newPost, postForm)
        postForm.hide()
        @wrap.scrollTop = 'max'
        @request 'forums.post.add',
            topic$id: topicId,
            body: body.text
        , (id) =>
            newPost.children[0].removeClass 'pending'
            newPost.remove spinner
            body.text = ''
            postForm.show()
            container.usePostId id
            @wrap.scrollTop = 'max'

    return postForm = new Container('d-r-block-form d-r-new-post-editor')
            .add(body = new TextField.Multiline('d-textfield d-r-new-post-editor-body').setAutoSize(true).setPlaceholder(tr 'Write something\u2026'))
            .add(new Button('d-button d-r-authenticated').setText('Reply').onExecute(post))
            .add(new Button('d-button d-r-hide-authenticated').setText('Sign In to Reply').onExecute(@showSignIn, @))

@module 'amber.templates', {
    post
    replyForm
}
