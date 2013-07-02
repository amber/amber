{ Base, extend, addClass, removeClass, toggleClass, hasClass, format, htmle, htmlu, bbTouch, inBB } = amber.util
{ Event, PropertyEvent, ControlEvent, TouchEvent, WheelEvent } = amber.event
{ getText: tr, maybeGetText: tr.maybe, getList: tr.list, getPlural: tr.plural } = amber.locale
{ Control, Label, Image, App, Menu, MenuItem, MenuSeparator, FormControl, TextField, TextField, TextField, Button, Checkbox, ProgressBar, Container, Form, FormGrid, Dialog } = amber.ui

urls = [
    [/^$/, 'index']
    [/^search$/, 'search']
    [/^search\/(.+)$/, 'search']
    [/^projects\/new$/, 'project.new']
    [/^projects\/(\w+)$/, 'project.view']
    [/^projects\/(\w+)\/edit$/, 'project.edit']
    [/^users\/([\w-]+)$/, 'user.profile']
    [/^settings$/, 'settings']
    [/^help$/, 'help']
    [/^help\/about$/, 'help.about']
    [/^help\/tos$/, 'help.tos']
    [/^help\/educators$/, 'help.educators']
    [/^help\/contact$/, 'contact']
    [/^explore$/, 'explore']
    [/^forums$/, 'forums.index']
    [/^forums\/(\w+)$/, 'forums.forum.view']
    [/^forums\/(\w+)\/add-topic$/, 'forums.forum.newTopic']
    [/^forums\/t\/(\w+)$/, 'forums.topic.view']
    [/^forums\/p\/(\w+)$/, 'forums.post.link']
]
views =
    index: ->
        @reloadOnAuthentication = true
        if @user
            @page
                .add(new Label('d-r-title', tr 'News Feed'))
                .add(new Label('d-r-subtitle', tr 'Follow people to see their activity here.'))
                .add(new ActivityCarousel().setLoader (offset, length, callback) ->
                    callback({
                        icon: @server.getAsset('')
                        description: [
                            '<a href=#users/nXIII class="d-r-link black">nXIII</a> shared the project <a href=# class=d-r-link>Summer</a>',
                            '<a href=#users/Lightnin class="d-r-link black">Lightnin</a> followed <a href=#users/MathWizz class=d-r-link>MathWizz</a>',
                            '<a href=#users/MathWizzFade class="d-r-link black">MathWizzFade</a> loved <a href=# class=d-r-link>Amber is Cool</a>',
                            '<a href=#users/nXIII class="d-r-link black">nXIII</a> followed <a href=#users/MathWizz class=d-r-link>MathWizz</a>',
                            '<a href=#users/MathWizz class="d-r-link black">MathWizz</a> shared the project <a href=# class=d-r-link>Custom Blocks</a>'
                        ][i % 5]
                        time: new Date
                    } for i in [offset..Math.min offset + length, 100]))
        else
            @page
                .add(new Label('d-r-splash-title', tr 'Amber'))
                .add(new Label('d-r-splash-subtitle', tr 'Collaborate in realtime with others around the world to create your own interactive stories, games, music & art.'))
                .add(new Container('d-r-splash-links')
                    .add(new Link('d-r-splash-link').setView('project.new')
                        .add(new Label('d-r-splash-link-title', tr 'Get Started'))
                        .add(new Label('d-r-splash-link-subtitle', tr 'Make an Amber project')))
                    .add(new Link('d-r-splash-link').setView('explore')
                        .add(new Label('d-r-splash-link-title', tr 'Explore'))
                        .add(projectCount = new Label('d-r-splash-link-subtitle')))
                    .add(new Link('d-r-splash-link').onExecute(@showSignIn, @)
                        .add(new Label('d-r-splash-link-title', tr 'Sign In'))
                        .add(new Label('d-r-splash-link-subtitle', tr 'With a Scratch account')))
                    .add(new Link('d-r-splash-link').setView('help.about')
                        .add(new Label('d-r-splash-link-title', tr 'About Amber'))
                        .add(new Label('d-r-splash-link-subtitle', tr 'What is @ thing?')))
                    .add(new Link('d-r-splash-link').setView('help.tos')
                        .add(new Label('d-r-splash-link-title', tr 'Terms of Service'))
                        .add(new Label('d-r-splash-link-subtitle', tr 'How can I use it?')))
                    .add(new Link('d-r-splash-link').setView('help.educators')
                        .add(new Label('d-r-splash-link-title', tr 'For Educators'))
                        .add(new Label('d-r-splash-link-subtitle', tr 'How can I teach with it?'))))
                .add(new Container('d-r-splash-footer'))
        @page
            .add(new Label('d-r-title', tr 'Featured Projects'))
            .add(new Label('d-r-subtitle', tr 'Selected projects from the community'))
            .add(featured = new ProjectCarousel(@).setRequestName('featured'))
        if @user
            @page
                .add(new Label('d-r-title', tr 'Made by People I\'m Following'))
                .add(new Label('d-r-subtitle', tr 'Follow people to see their projects here'))
                .add(byFollowing = new ProjectCarousel(@).setRequestName('user.byFollowing'))
                .add(new Label('d-r-title', tr 'Loved by People I\'m Following'))
                .add(new Label('d-r-subtitle', tr 'Follow people to see their interests here'))
                .add(lovedByFollowing = new ProjectCarousel(@).setRequestName('user.lovedByFollowing'))
        @page
            .add(new Label('d-r-title', tr 'Top Remixed'))
            .add(new Label('d-r-subtitle', tr 'What the community is remixing @ week'))
            .add(topRemixed = new ProjectCarousel(@).setRequestName('topRemixed'))
            .add(new Label('d-r-title', tr 'Top Loved'))
            .add(new Label('d-r-subtitle', tr 'What the community is loving @ week'))
            .add(topLoved = new ProjectCarousel(@).setRequestName('topLoved'))
            .add(new Label('d-r-title', tr 'Top Viewed'))
            .add(new Label('d-r-subtitle', tr 'What the community is viewing @ week'))
            .add(topViewed = new ProjectCarousel(@).setRequestName('topViewed'))

        @watch (if @user then 'home.signedIn' else 'home.signedOut'),
            projectCount: (x) ->
                projectCount.setText(tr('% projects', x))
            featured: featured,
            byFollowing: byFollowing,
            lovedByFollowing: lovedByFollowing,
            topRemixed: topRemixed,
            topLoved: topLoved,
            topViewed: topViewed

    explore: (args) ->
        @page
            .add(new LazyList('d-r-fluid-project-list')
                .setLoader((offset, length, callback) =>
                    return @request('projects.topLoved',
                        offset: offset,
                        length: length
                    , callback))
                .setTransformer((info) ->
                    return new Link('d-r-fluid-project').setView('project.view', info.id)
                        .add(new Image('d-r-fluid-project-thumbnail').setURL(@app.server.getAsset(info.project.thumbnail)))
                        .add(new Label('d-r-fluid-project-label', info.project.name))))

    notFound: (args) ->
        @page
            .add(new Label('d-r-title', tr 'Page Not Found'))
            .add(new Label('d-r-paragraph', tr('The page at the URL "%" could not be found.', args[0])))

    forbidden: (args) ->
        @page
            .add(new Label('d-r-title', tr 'Authentication Required'))
            .add(new Label('d-r-paragraph', tr 'You need to log in to see @ page.'))

    help: (args) ->
        @page
            .add(new Label('d-r-title', tr 'Help'))
            .add(new Label('d-r-paragraph', tr 'This is a placeholder help section.'))

    'help.about': (args) ->
        @page
            .add(new Label('d-r-title', tr 'About Amber'))
            .add(new Label('d-r-paragraph', tr 'Copyright \xa9 2013 Nathan Dinsmore and Truman Kilen.'))

    'help.tos': ->
        @page
            .add(new Label('d-r-title', tr 'Terms of Service'))
            .add(new Label('d-r-paragraph', tr 'You just do what the **** you want to.'))

    search: ->
        @page
            .add(new Label('d-r-title', tr 'Search'))
            .add(new Label('d-r-paragraph', 'This is a placeholder search page.'))

    settings: ->
        @requireAuthentication()
        @page
            .add(new Label('d-r-title', tr 'Settings'))
            .add(new Container('d-r-block-form')
                .add(new Label('d-r-form-label', tr 'Username'))
                .add(new TextField().setText(@user.name))
                .add(new Label('d-r-form-label', tr 'About Me'))
                .add(new TextField.Multiline().setAutoSize(true))
                .add(new Label('d-r-form-label', tr 'What I\'m Working On'))
                .add(new TextField.Multiline().setAutoSize(true)))

    'project.view': (args, isEdit) ->
        toggleNotes = () ->
            notes.element.style.height = 'auto'
            height = notes.element.offsetHeight + 'px'
            open = not notes.hasClass 'open'
            notes.element.style.height = if open then fixedHeight else height
            notes.toggleClass 'open'
            notesDisclosure.setText (if open then tr 'Show less' else tr 'Show more')
            setTimeout =>
                notes.element.style.WebkitTransition =
                    notes.element.style.MozTransition =
                    notes.element.style.MSTransition =
                    notes.element.style.OTransition =
                    notes.element.style.transition = 'height .3s'
                notes.element.style.height = if open then height else fixedHeight
                setTimeout (=>
                    notes.element.style.WebkitTransition =
                        notes.element.style.MozTransition =
                        notes.element.style.MSTransition =
                        notes.element.style.OTransition =
                        notes.element.style.transition = 'none'
                ), 300

        fixedHeight = '6em'
        @page
            .add(title = new Label('d-r-title'))
            .add(authors = new Label('d-r-subtitle'))
            .add(new Container('d-r-project-player-wrap')
                .add(player = new Container('d-r-project-player')
                    .add(new Label('d-r-project-player-title', 'v234'))))
            .add(new Container('d-r-paragraph d-r-project-stats')
                .add(favorites = new Label().setText(tr.plural('% Favorites', '% Favorite', 0)))
                .add(new Separator)
                .add(loves = new Label().setText(tr.plural('% Loves', '% Love', 0)))
                .add(new Separator)
                .add(views = new Label().setText(tr.plural('% Views', '% View', 0)))
                .add(new Separator)
                .add(remixes = new Label().setText(tr.plural('% Remixes', '% Remix', 0))))
            .add(notes = new Label('d-r-paragraph d-r-project-notes'))
            .add(new Container('d-r-paragraph d-r-project-notes-disclosure')
                .add(notesDisclosure = new Button('d-r-link').setText(tr 'Show more').onExecute(toggleNotes).hide()))
            # .add(new Container('d-r-project-player-wrap')
            #     .add(authors = new Label('d-r-project-authors', tr('by %', '')))
            #     .add(new Container('d-r-project-player'))
            #     .add(new Container('d-r-project-stats')
            #         .add(favorites = new Label('d-r-project-stat', tr.plural('% Favorites', '% Favorite', 0)))
            #         .add(loves = new Label('d-r-project-stat', tr.plural('% Loves', '% Love', 0)))
            #         .add(views = new Label('d-r-project-stat', tr.plural('% Views', '% View', 0)))
            #         .add(remixes = new Label('d-r-project-stat', tr.plural('% Remixes', '% Remix', 0)))))
            # .add(notes = new Label('d-r-project-notes d-scrollable'))
            # .add(new Label('d-r-project-comments-title', tr 'Comments'))
            # .add(new Label('d-r-project-remixes-title', tr 'Remixes'))
            # .add(new Container('d-r-project-comments'))
        @request 'project', project$id: args[1], (project) =>
            console.log(project)
            authors.richText = tr 'by %', tr.list ('<a class=d-r-link href="' + (htmle @abs @reverse 'user.profile', author) + '">' + (htmle author) + '</a>' for author in project.authors)
            title.text = project.name
            notes.text = project.notes
            if (project.notes.split '\n').length > 4
                notes.element.style.height = fixedHeight
                notesDisclosure.show()

            favorites.text = tr.plural '% Favorites', '% Favorite', project.favorites
            loves.text = tr.plural '% Loves', '% Love', project.loves
            views.text = tr.plural '% Views', '% View', project.views
            remixes.text = tr.plural '% Remixes', '% Remix', project.remixes.length
        # @request('GET', 'projects/' + args[1] + '/', null, (info) ->
        #     title.setText(info.project.name)
        #     authors.setRichText(tr('by %', tr.list(info.project.authors.map((author) ->
        #         return '<a class=d-r-link href="' + @abs(htmle(@reverse('user.profile', author))) + '">' + htmle(author) + '</a>'
        #     , @))))
        #     notes.setText(info.project.notes)
        #     favorites.setText(tr.plural('% Favorites', '% Favorite', info.favorites))
        #     loves.setText(tr.plural('% Loves', '% Love', info.loves))
        #     views.setText(tr.plural('% Views', '% View', info.views))
        #     remixes.setText(tr.plural('% Remixes', '% Remix', info.remixes.length))
        #     player.setProject(info.project)
        #     if isEdit
        #         player.setEditMode(true)
        #
        # , (status) ->
        #     if status is 404
        #         @notFound()
        #
        # )
        # @onUnload(->
        #     player.parent.remove(player)
        # )

    'project.edit': (args) -> views['project.view'].call(@, args, true)

    'user.profile': (args) ->
        @page
            .add(new Container('d-r-user-icon'))
            .add(new Label('d-r-title', args[1]))
            .add(new Container('d-r-user-icon'))
            .add(new ActivityCarousel().setLoader (offset, length, callback) ->
                    callback({
                        icon: @server.getAsset('')
                        description: [
                            '<a href=#users/' + args[1] + ' class="d-r-link black">' + args[1] + '</a> shared the project <a href=# class=d-r-link>Summer</a>',
                            '<a href=#users/' + args[1] + ' class="d-r-link black">' + args[1] + '</a> followed <a href=#users/MathIncognito class=d-r-link>MathIncognito</a>',
                            '<a href=#users/' + args[1] + ' class="d-r-link black">' + args[1] + '</a> loved <a href=# class=d-r-link>Amber is Cool</a>',
                            '<a href=#users/' + args[1] + ' class="d-r-link black">' + args[1] + '</a> followed <a href=#users/nXIII- class=d-r-link>nXIII-</a>',
                            '<a href=#users/' + args[1] + ' class="d-r-link black">' + args[1] + '</a> shared the project <a href=# class=d-r-link>Custom Blocks</a>'
                        ][i % 5]
                        time: new Date
                    } for i in [offset..Math.min offset + length, 100]))
            .add(new Container('d-r-title')
                .add(new Label().setText('About Me'))
                .add(new Button('d-r-edit-button d-r-section-edit')))
            .add(new Label('d-r-section', 'Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur.'))
            .add(new Container('d-r-title')
                .add(new Label().setText('What I\'m Working On'))
                .add(new Button('d-r-edit-button d-r-section-edit')))
            .add(new Label('d-r-section', 'Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.'))
            .add(new Label('d-r-title', tr 'Shared Projects'))
            .add(new ProjectCarousel(@).setRequestName('byUser').setRequestArguments(user: args[1] ))
            .add(new Label('d-r-title', tr 'Favorite Projects'))
            .add(new ProjectCarousel(@).setRequestName('topLoved'))
            .add(new Label('d-r-title', tr 'Collections'))
            .add(new Carousel())
            .add(new Label('d-r-title', tr 'Following'))
            .add(new Carousel())
            .add(new Label('d-r-title', tr 'Followers'))
            .add(new Carousel())

    'forums.index': ->
        @request 'forums.categories', {}, (categories) =>
            for category in categories
                @page
                    .add(new Label('d-r-title', tr.maybe category.name))
                for forum in category.forums
                    @page
                        .add(new Container('d-r-forum-list')
                            .add(new Link('d-r-forum-list-item')
                                 .add(new Label('d-r-forum-list-item-title', tr.maybe(forum.name)))
                                 .add(new Label('d-r-forum-list-item-description', tr.maybe(forum.description)))
                                 .setView('forums.forum.view', forum.id)))

    'forums.forum.view': (args) ->
        forumId = args[1]
        @page
            .add(new Container('d-r-title')
                .add(new Link('d-r-list-up-button').setView('forums.index'))
                .add(title = new Label))
            .add(new Container('d-r-subtitle')
                .add(subtitle = new Label())
                .add(new Separator('d-r-authenticated'))
                .add(new Link('d-r-link d-r-authenticated')
                    .setText(tr 'New Topic')
                    .setURL(@reverse('forums.forum.newTopic', forumId))))
            .add(new LazyList('d-r-topic-list')
                .setLoader((offset, length, callback) =>
                    return @request('forums.topics',
                        forum$id: forumId,
                        offset: offset,
                        length: length
                    , callback))
                .setTransformer((topic) =>
                    link = new Link('d-r-topic-list-item')
                        .setURL(t.reverse('forums.topic.view', topic.id))
                        .add(new Container('d-r-topic-list-item-title')
                            .add(new Label('d-r-topic-list-item-name', topic.name))
                            .add(userLabel = new Label('d-r-topic-list-item-author', tr('by %', tr.list(topic.authors)))))
                        .add(new Container('d-r-topic-list-item-description')
                            .add(new Label().setText(tr.plural('% posts', '% post', topic.posts)))
                            .add(new Separator())
                            .add(new Label().setText(tr.plural('% views', '% view', topic.views))))
                    userLabel.text = tr 'by %', tr.list topic.authors
                    return link))
        @request 'forums.forum', forum$id: forumId, (forum) =>
            title.text = tr.maybe forum.name
            subtitle.text = tr.maybe forum.description

    'forums.forum.newTopic': (args) ->
        post = =>
            username = @user.name
            bodyText = body.text
            name = topicName.text
            @page
                .clear()
                .add(new Container('d-r-title d-r-topic-title')
                    .add(new Link('d-r-list-up-button').setView('forums.forum.view', forumId))
                    .add(new Label('d-inline', name)))
                .add(new Container('d-r-post-list')
                    .add(new Container('d-r-post pending')
                        .add(new Label('d-r-post-author')
                            .add(new Link().setView('user.profile', username)
                                .add(new Label().setText(username))))
                        .add(new Label('d-r-post-body').setRichText(parse(bodyText))))
                    .add(new Container('d-r-post-spinner')))
                .add(@template('replyForm'))
            @request 'forums.topic.add',
                forum$id: forumId,
                name: name,
                body: bodyText
            , (info) =>
                @page.clear()
                @redirect(@reverse('forums.topic.view', info.topic$id), true)
                views['forums.topic.view'].call @, [null, info.topic$id],
                    topic:
                        forum$id: forumId
                        name: name
                    posts: [
                        authors: [username]
                        body: bodyText
                        id: info.post$id
                    ]

        forumId = args[1]
        @requireAuthentication()
        @page
            .add(base = new Container('d-r-new-topic-editor')
                .add(new Container('d-r-title')
                    .add(new Link('d-r-list-back-button').setView('forums.forum.view', forumId))
                    .add(title = new Label))
                .add(subtitle = new Label('d-r-subtitle'))
                .add(postForm = new Container('d-r-block-form')
                    .add(topicName = new TextField('d-textfield d-r-block-field').setPlaceholder(tr 'Topic Name').autofocus())
                    .add(new Container('d-r-new-topic-editor-wrap')
                        .add(new Container('d-r-new-topic-editor-inner')
                            .add(new Container('d-r-new-topic-editor-inner-wrap')
                                .add(body = new TextField.Multiline('d-textfield d-r-new-topic-editor-body').setPlaceholder(tr 'Post Body')))))
                    .add(new Button('d-button d-r-new-topic-button').setText(tr 'Create Topic').onExecute(post))))
        @request 'forums.forum', forum$id: forumId, (forum) =>
            title.text = tr.maybe forum.name
            subtitle.text = tr.maybe forum.description

    'forums.topic.view': (args, info) ->
        load = (topic) =>
            up.setView('forums.forum.view', topic.forum$id)
            title.text = tr.maybe topic.name

        topicId = args[1]
        @page
            .add(new Container('d-r-title d-r-topic-title')
                .add(up = new Link('d-r-list-up-button'))
                .add(title = new Label('d-inline')))
            .add(list = new LazyList('d-r-post-list')
                .setLoader((offset, length, callback) =>
                    @request 'forums.posts',
                        topic$id: topicId,
                        offset: offset,
                        length: length
                    , callback)
                .setTransformer(template.post.bind(@)))
            .add(@template 'replyForm', topicId)
        if info
            load info.topic
            list.setItems(info.posts)
        else
            @request 'forums.topic', topic$id: topicId, load

        @request 'forums.topic.view',topic$id: topicId, ->

template =
    post: (post) ->
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

    replyForm: (topicId) ->
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


class SiteApp extends App
    @event 'Unload'

    constructor: ->
        super()
        @setConfig()
        @pendingRequests = 0

    setElement: (element) ->
        addClass element, 'd-r-app unauthenticated'
        super(element)
            .add((@signInForm = new Form('d-r-header-sign-in'))
                .hide()
                .onSubmit(@signIn, @)
                .onCancel(@hideSignIn, @)
                .add(@signInUsername = new TextField('d-textfield d-r-header-sign-in-field').setPlaceholder(tr 'Username'))
                .add(@signInPassword = new TextField.Password('d-textfield d-r-header-sign-in-field').setPlaceholder(tr 'Password'))
                .add(@signInButton = new Button().setText(tr 'Sign In').onExecute(@signInForm.submit, @signInForm))
                .add(@signUpLink = new Link().setText(tr 'Register').setExternalURL('http://scratch.mit.edu/signup'))
                .add(@signInError = new Label('d-label d-r-header-sign-in-error').hide()))
            .add(new Container('d-r-header')
                .add(@panelLink('Amber', 'index'))
                .add(@panelLink('Create', 'project.new'))
                .add(@panelLink('Explore', 'explore'))
                .add(@panelLink('Discuss', 'forums.index'))
                .add(@userButton = new Button('d-r-panel-button d-r-header-user')
                    .onExecute(@toggleUserPanel, @)
                    .add(@userLabel = new Label('d-r-header-user-label', tr 'Sign In'))
                    .add(new Label('d-r-header-user-arrow')))
                .add(@search = new TextField('d-textfield d-r-header-search').setPlaceholder(tr 'Search\u2026').onInputDone =>
                    if @search.text
                        @show 'search', @search.text
                    else
                        @show 'search')
                .add(@spinner = new Container('d-r-spinner').hide())
                .add(@connectionWarning = new Container('d-r-connection-warning').setTooltip(tr 'Lost connection to server. Trying again\u2026').hide()))
            .add(@wrap = new Container('d-r-wrap').addClass('d-scrollable').withScrollEvent()
                .add(@page = @createPage())
                .add(new Container('d-r-footer')
                    .add(@panelLink 'Help', 'help')
                    .add(@panelLink 'About', 'help.about')
                    .add(@panelLink 'Feedback', 'forums.topic.view', 1)
                    .add(@panelLink 'Contact', 'contact')))

        window.addEventListener 'hashchange', =>
            if @isRedirect
                @isRedirect = false
                return

            @go location.hash.substr(1), true
        @

    @property 'config'

    @property 'server',
        apply: (server) ->
            server.app = @
            @go location.hash.substr 1

    @property 'connected',
        apply: (connected) ->
            @connectionWarning.visible = not connected
            if not connected
                @spinner.hide()
                @pendingRequests = 0


    @property 'user',
        value: null,
        apply: (user) ->
            if user
                @signInForm.hide()
                @signInError.hide()
                @userButton.removeClass 'd-r-panel-button-pressed'
                @userLabel.text = user.name
            else
                @userLabel.text = tr 'Sign In'

            @toggleClass 'authenticated', user
            @toggleClass 'unauthenticated', not user
            if @reloadOnAuthentication
                @reload()

            for a in @authenticators
                a.call @

    createPage: ->
        return new Container('d-r-page').setSelectable(true)

    showSignIn: (autohide) ->
        return if @signInForm.visible
        @signInAutohide = autohide
        @signInForm.show()
        @signInUsername.clear()
        @signInPassword.clear()
        @signInError.hide()
        @signInButton.setEnabled true
        @signInButton.removeClass 'd-button-pressed'
        @signInUsername.focus()
        @userButton.addClass 'd-r-panel-button-pressed'

    hideSignIn: ->
        @userButton.removeClass 'd-r-panel-button-pressed'
        @signInForm.hide()

    toggleUserPanel: ->
        if @user
            @userButton.addClass('d-r-panel-button-pressed')
            new Menu().addClass('d-r-header-user-menu').set(
                items: [
                    title: tr 'Profile', action: ['show', 'user.profile', @user.name],
                    title: tr 'Settings', action: ['show', 'settings'],
                    Menu.separator,
                    title: tr 'Sign Out', action: 'signOut'
                ]
                target: @
            ).onClose(=>
                @userButton.removeClass('d-r-panel-button-pressed'))
            .show(@userButton, @userButton.element)
        else
            if @signInForm.visible and @signInButton.enabled
                @hideSignIn()
            else
                @showSignIn()


    authenticationError: {}

    requireAuthentication: ->
        @reloadOnAuthentication = true
        unless @user
            @showSignIn true
            throw @authenticationError

    authenticate: (users, controls) ->
        authenticator = ->
            user = @user
            visible = false
            if user
                username = user.name
                i = users.length
                while (i--)
                    if typeof users[i] is 'string'
                        pass = users[i] is username
                    else
                        pass = users[i] is user
                    if pass
                        visible = true
                        break

            for control in controls
                control.visible = visible

        users = [users] unless users instanceof Array
        controls = [controls] unless controls instanceof Array
        @authenticators.push authenticator
        authenticator.call @

    signOut: ->
        return unless @user
        @request 'auth.signOut', {}, ->
            @user = null

    signIn: ->
        enable = =>
            @signInButton.removeClass('d-button-pressed').setEnabled(true)

        @signInButton.addClass('d-button-pressed').setEnabled(false)
        @request(
            'auth.signIn'
            username: @signInUsername.text,
            password: @signInPassword.text
            (user) ->
                enable()
                @user = (new User @server).fromJSON user
            ->
                enable()
                @signInError.show().text = tr 'Incorrect username or password.'
        )

    requestStart: ->
        ++@pendingRequests
        @spinner.show()

    requestEnd: ->
        if not --@pendingRequests
            @spinner.hide()
            @swapIfComplete()

    request: (name, options, callback, error) ->
        @requestStart()
        @server.request(name, options
            (result) =>
                @requestEnd()
                callback.call @, result if callback
            (e) =>
                @requestEnd()
                error.call t, e if error)

    watch: (name, params, config) ->
        initial = true

        watcher = (data) =>
            for key, d of data
                handler = config[key]
                if typeof handler is 'function'
                    handler.call @, d
                else if config.start and config.update
                    if initial
                        handler.start d
                        initial = false
                    else
                        handler.update d

        unless params
            params = {}
        unless config
            config = params
            params = {}

        @watcher = watcher
        @request 'watch.' + name, params, watcher

    panelLink: (t, view) ->
        new Link('d-r-panel-button').setText(tr t ).setURL(@reverse.apply @, [].slice.call arguments, 1)

    notFound: ->
        @page.clear()
        views.notFound.call @, [@url]
        @

    abs: (url) -> '#' + url

    reverse: (view) ->
        args = [].slice.call arguments, 1
        for url in urls
            if url[1] is view
                source = url[0].source.replace(/^\^/, '').replace(/\\\//g, '/').replace(/\$$/, '')
                arg = 0
                out = source.replace /\((?:[^\)]|\\\))+\)/g, -> args[arg++]
                if args.length is arg
                    return out
        throw new Error 'No reverse match for "' + view + '" with arguments [' + args + ']'

    show: (view) -> @go @reverse.apply @, arguments

    redirect: (loc, keep) ->
        while loc[loc.length - 1] is '/'
            loc = loc.substr 0, loc.length - 1
        while loc[0] is '/'
            loc = loc.substr 1

        if keep
            return @ if @url is loc
            @isRedirect = true
            location.hash = '#' + loc
        else
            location.replace ('' + location).split('#')[0] + '#' + loc
        @url = loc
        @

    go: (loc) ->
        while loc[loc.length - 1] is '/'
            loc = loc.substr 0, loc.length - 1
        while loc[0] is '/'
            loc = loc.substr 1

        location.hash = loc
        return if @url is loc

        @hideSignIn() if @signInForm.visible and @signInAutohide

        @authenticators = []
        @dispatch 'Unload', new ControlEvent @
        @clearListeners 'Unload'
        @pendingRequests = 0
        @reloadOnAuthentication = false
        @url = loc
        @oldPage = @page if @page.parent

        @page = @createPage()
        try
            for url in urls
                if match = url[0].exec loc
                    if not views[url[1]]
                        console.error 'Undefined view ' + url[1]
                        break

                    views[url[1]].call @, match
                    @swapIfComplete()
                    return @

            views.notFound.call @, [loc]
        catch e
            if e is @authenticationError
                views.forbidden.call @, [loc]
            else
                throw e

        @swapIfComplete()
        @

    swapIfComplete: ->
        return @ unless @oldPage
        if @pendingRequests == 0
            @wrap.replace @oldPage, @page
            @wrap.element.scrollTop = 0
            @oldPage = undefined

        @

    reload: ->
        url = @url
        @url = null
        @go url
        @

    template: (name) ->
        template[name].apply @, [].slice.call arguments, 1

RequestError =
    notFound: 0,
    auth$incorrectCredentials: 1

class Server extends Base
    INITIAL_REOPEN_DELAY: 100,

    constructor: (socketURL, assetStoreURL) ->
        @socketURL = socketURL
        @assetStoreURL = assetStoreURL
        @requestId = 0
        @requests = {}
        @usersByName = {}
        @usersById = {}
        @userIdCallbacks = {}
        @log = []
        @_sessionId = sessionStorage.getItem 'sessionId'
        @reopenDelay = @INITIAL_REOPEN_DELAY
        @open()

    open: =>
        @socket = new WebSocket(@socketURL)
        @socket.onopen = @listeners.open.bind @
        @socket.onclose = @listeners.close.bind @
        @socket.onmessage = @listeners.message.bind @
        @socket.onerror = @listeners.error.bind @
        @socketQueue = []

    @property 'app'

    @property 'sessionId', apply: (sessionId) ->
        sessionStorage.setItem('sessionId', sessionId)

    on:
        'connect': (p) ->
            @app.user = if p.user then (new User @).fromJSON p.user else null
            @setSessionId p.sessionId

        'result': (p) ->
            request = @requests[p.request$id]
            unless request
                console.warn 'Invalid request id:', p
                return

            request.callback p.result
            delete @requests[p.request$id]

        'error': (p) ->
            request = @requests[p.request$id]
            unless request
                console.warn 'Invalid request id:', p
                return

            if request.error
                request.error p.code
            else
                console.error 'RequestError: ' + @requestErrors[p.code] + ' in ' + request.name, request.options

            delete @requests[p.request$id]

    requestErrors: [
        'Not found',
        'Incorrect credentials'
    ]

    listeners:
        open: ->
            socketQueue = @socketQueue
            packet = sessionId: @sessionId

            @app.connected = true
            @reopenDelay = @INITIAL_REOPEN_DELAY

            raw = JSON.stringify @encodePacket 'Client', 'connect', packet
            @socket.send raw

            packet.$type = 'connect'
            packet.$time = new Date
            packet.$side = 'Client'

            @log.splice @log.length - socketQueue.length, 0, packet
            config = @app.config

            if config.rawPacketLog
                console.log 'Client:', raw
            if config.livePacketLog
                @logPacket packet

            while (packet = socketQueue.pop())
                if config.livePacketLog
                    @logPacket @log[@log.length - socketQueue.length - 1]
                if config.rawPacketLog
                    console.log 'Client:', packet

                @socket.send packet

        close: ->
            @app.connected = false
            console.warn 'Socket closed. Reopening.'
            if @signInErrorCallback
                @signInErrorCallback 'Connection lost.'
                @signInErrorCallback = undefined

            setTimeout @open, @reopenDelay
            if @reopenDelay < 5 * 60 * 1000
                @reopenDelay *= 2

        message: (e) ->
            config = @app.config

            if config.rawPacketLog
                console.log 'Server:', e.data

            packet = @decodePacket 'Server', e.data
            return unless packet

            packet.$time = new Date
            packet.$side = 'Server'

            @log.push packet
            if config.livePacketLog
                @logPacket packet

            if hasOwnProperty.call @on, packet.$type
                @on[packet.$type].call @, packet
            else
                console.warn 'Missed packet:', packet

        error: (e) ->
            console.warn('Socket error:', e)

    decodePacket: (side, packet) ->
        try
            packet = JSON.parse(packet)
        catch
            console.warn 'Packet syntax error:', packet
            return

        if not packet or typeof packet isnt 'object'
            console.warn 'Invalid packet:', e
            return

        return packet unless packet instanceof Array

        type = packet[0]
        info = PACKETS[side + ':' + type]
        if not info
            console.warn 'Invalid packet type:', packet
            return

        result = {}
        result.$type = type
        i = info.length
        while i--
            result[info[i]] = packet[i + 1]

        result

    encodePacket: (side, type, properties) ->
        if (@app.config.verbosePackets)
            (properties ?= {}).$type = type
            return properties

        info = PACKETS[side + ':' + type]
        if not info
            console.warn 'Invalid packet type:', type, properties
            return

        i = 0
        l = info.length
        result = [type]
        while i < l
            result.push properties[info[i++]]

        result

    send: (type, properties, censorFields) ->
        config = @app.config

        p = @encodePacket 'Client', type, properties
        return unless p

        log = {}
        log.$type = type
        for key, value of properties
            log[key] = if censorFields and censorFields[key] then '********' else value

        log.$time = new Date
        log.$side = 'Client'
        @log.push log

        packet = JSON.stringify p
        if @socket.readyState isnt 1
            @socketQueue.push packet
            return

        if config.rawPacketLog
            console.log 'Client:', packet
        if config.livePacketLog
            @logPacket log

        @socket.send packet

    request: (name, options, callback, error) ->
        id = ++@requestId
        @requests[id] =
            name: name,
            options: options,
            callback: callback,
            error: error

        options.request$id = id
        @send name, options

    getAsset: (hash) -> @assetStoreURL + hash + '/'

    logPacket: (packet) ->
        log = (object, dollar) ->
            for key, value of object when not dollar or key[0] isnt '$'
                if value and typeof value is 'object'
                    console.group "#{key}:"
                    log value
                    console.groupEnd()
                else
                    console.log "#{key}:", value

        time = packet.$time.toLocaleTimeString()
        side = packet.$side
        type = packet.$type

        console.groupCollapsed "[#{time}] #{side}:#{type}"
        log packet, true
        console.groupEnd()

    showLog: ->
        for log in @log
            @logPacket log

parse = (text) ->
    text
        .trim()
        .split('\n')
        .filter((p) -> p.length)
        .map((p) ->
            '<div class=d-r-post-paragraph>' + (htmle p) + '</div>')
        .join('')

class User extends Base
    constructor: (server) ->
        super()
        @setServer server

    @property 'server'

    @property 'name', apply: (name) ->
        @server.usersByName[name] = @

    @property 'id', apply: (id) ->
        @server.usersById[id] = @

    @property 'rank',
        value: 'default'

    avatarURL: ->
        id = '' + @id
        trim = id.length - 4
        a = id.substr 0, trim
        b = id.substr trim
        "http://scratch.mit.edu/static/site/users/avatars/#{a}/#{b}.png"

    profileURL: ->
        name = encodeURIComponent @name
        "http://scratch.mit.edu/users/#{name}"

    toJSON: ->
        rank = @rank
        result =
            id: @id
            name: @name

        result.rank = rank if rank isnt 'default'
        result

    fromJSON: (o) ->
        return @set
            id: o.id
            name: o.name
            rank: o.rank ? 'default'

class Link extends Button
    constructor: (className = 'd-r-link') ->
        super()
        @element = @container = @newElement className, 'a'
        @element.tabIndex = 0

    setView: (view) ->
        return @setURL SiteApp::reverse arguments...

    @property 'URL', apply: (url) ->
        @element.target = ''
        @element.href = @_externalURL = SiteApp::abs url

    @property 'externalURL', apply: (url) ->
        @_url = null
        @element.target = '_blank'
        @element.href = url


class Separator extends Label
    constructor: (className = '') ->
        super "d-r-separator #{className}"
        @setText '\xb7'

class Carousel extends Control
    acceptsScrollWheel: true

    constructor: ->
        @items = []
        @visibleItems = []
        super()
        @initElements 'd-r-carousel'
        @element.appendChild @wrap = @newElement 'd-r-carousel-wrap'
        @wrap.appendChild @container = @newElement 'd-r-carousel-container'
        @element.appendChild @newElement 'd-r-carousel-shade d-r-carousel-shade-left'
        @element.appendChild @newElement 'd-r-carousel-shade d-r-carousel-shade-right'

        button = new Button('d-r-carousel-button d-r-carousel-button-left')
            .onExecute =>
                if @offset > 0
                    @scroll -1
        @element.appendChild @leftButton = button.element
        button = new Button('d-r-carousel-button d-r-carousel-button-right').onExecute =>
            if @loaded is @items.length or @offset + @maxVisibleItemCount isnt @loaded
                if @scroll(1)
                    @load()
        @element.appendChild @rightButton = button.element
        @offset = 0
        @scrollX = 0
        @max = -1
        @onLive ->
            @load()
        @onScrollWheel @scrollWheel

    @property 'hasDetails',
        apply: (hasDetails) ->
            toggleClass @element, 'd-r-carousel-detail', hasDetails

    @property 'loader'

    @property 'transformer'

    ITEM_WIDTH: 195
    INITIAL_LOAD: 20

    scrollWheel: (e) ->
        max =
            if @max > -1
                Math.max 0, @max * @ITEM_WIDTH - @visibleWidth()
            else
                @container.offsetWidth
        @scrollX += e.x
        @scrollX = 0 if @scrollX < 0
        @scrollX = max if @scrollX > max
        if (offset = @getOffset()) isnt @offset
            @offset = offset
            @container.style.left = @getX() + 'px'
            if (@offset + @maxVisibleItemCount() * 2 > @loaded)
                @load()


        e.setAllowDefault(true)

    visibleWidth: -> @wrap.offsetWidth - @leftButton.offsetWidth * 2

    getOffset: -> Math.ceil @scrollX / @ITEM_WIDTH
    getX: -> -@offset * @ITEM_WIDTH

    visibleItemCount: -> Math.max 1, Math.floor @visibleWidth() / @ITEM_WIDTH
    maxVisibleItemCount: -> Math.max 1, Math.ceil @visibleWidth() / @ITEM_WIDTH

    scroll: (screens) ->
        length = @visibleItemCount()
        if screens > 0 and @max > -1 and @offset + length >= @max
            return false

        @offset += screens * length
        if @offset < 0
            @offset = 0
        @scrollX = -@getX()
        @container.style.left = -@scrollX + 'px'
        return true

    loaded: 0
    loadItems: (offset, length, callback) ->
        return unless @_loader and length
        if offset + length < @loaded
            callback.call @, []
            return

        if offset < @loaded
            delta = @loaded - offset
            @_loader offset + delta, length - delta, (result) =>
                if result.length < length - delta
                    @max = offset + delta + result.length
                callback.call @, result
        else
            @_loader offset, length, (result) =>
                if result.length < length
                    @max = offset + result.length
                callback.call @, result

        @loaded = offset + length

    addItems: (items) ->
        for item in items
            @add control = @_transformer item
            @items.push control

    load: (length) ->
        return unless @max is -1
        offset = @offset + @maxVisibleItemCount()
        length = @maxVisibleItemCount() * 2 if length == null
        @loadItems offset, length, @addItems

    start: (items) ->
        @items = []
        @addItems items
        @offset = items.length

    update: (delta) ->
        # TODO

class CarouselItem extends Link

    constructor: ->
        super('d-r-carousel-item')
        @element.appendChild(@thumbnailImage = @newElement('d-r-carousel-item-thumbnail', 'img'))
        @element.appendChild(@labelElement = @newElement('d-r-carousel-item-label'))
        @element.appendChild(@detailElement = @newElement('d-r-carousel-item-detail'))
    @property 'label',
        apply: (label) ->
            @labelElement.textContent = label

    @property 'detail',
        apply: (detail) ->
            @detailElement.textContent = detail
            @detailElement.style.display = detail ? 'block' : 'none'

    @property 'thumbnail',
        apply: (url) ->
            @thumbnailImage.src = url


class ProjectCarousel extends Carousel

    constructor: (app) ->
        @_initApp = app
        @_requestArguments = {}
        super()

    _loader: (offset, length, callback) ->
        @_initApp.request 'projects.' + @requestName, extend(
            offset: offset,
            length: length
        , @requestArguments), (result) ->
            callback result

    _transformer: (project) ->
        request = @requestName
        return new ProjectCarouselItem().setProject(project).setDetail(switch request
            when 'topViewed' then tr.plural '% Views', '% View', project.views
            when 'topLoved' then tr.plural '% Loves', '% Love', project.loves
            when 'topRemixed' then tr.plural '% Remixes', '% Remix', project.remixes.length)

    @property 'requestName', apply: (name) ->
        @setHasDetails -1 isnt ['topViewed', 'topLoved', 'topRemixed'].indexOf name

    @property 'requestArguments',

class ProjectCarouselItem extends CarouselItem
    @property 'project', apply: (info) ->
        @setView 'project.view', info.id
        @label = info.project.name
        @onLive ->
            @thumbnail = @app.server.getAsset info.project.thumbnail


class ActivityCarousel extends Carousel

    constructor: ->
        super()
        @addClass 'd-r-activity-carousel'

    _transformer: (item) ->
        return new ActivityCarouselItem()
            .setIcon(item.icon)
            .setDescription(item.description)
            .setTime(item.time)

    load: (length = @maxVisibleItemCount() * 2) ->
        return unless @max is -1
        offset = @offset
        @loadItems offset, length, (items) =>
            for item in items
                if (offset + i - 1) % 3 is 0
                    @add @column = new Container 'd-r-activity-carousel-column'

                @column.add @items[offset + i - 1] = @_transformer item

    ITEM_WIDTH: 400

    getOffset: -> (Math.ceil @scrollX / @ITEM_WIDTH) * 3
    getX: -> -@offset / 3 * @ITEM_WIDTH
    maxVisibleItemCount: -> super() * 3
    visibleItemCount: -> super() * 3

class ActivityCarouselItem extends Container
    constructor: ->
        super('d-r-activity-carousel-item')
        @element.appendChild @iconElement = @newElement 'd-r-activity-carousel-item-icon', 'img'
        @element.appendChild @descriptionElement = @newElement 'd-r-activity-carousel-item-description'
        @element.appendChild @timeElement = @newElement 'd-r-activity-carousel-item-time'
    @property 'description', apply: (description) ->
        @descriptionElement.innerHTML = description

    @property 'time', apply: (time) ->
        @timeElement.textContent = time.toLocaleString()

    @property 'icon', apply: (url) ->
        @iconElement.src = url


class LazyList extends Container
    constructor: (className = 'd-r-list') ->
        @items = []
        @visibleItems = []
        super(className)
        @element.style.paddingBottom = @buffer + 'px'
        @offset = 0
        @max = -1
        @onLive ->
            app = @app
            app.wrap.onScroll @loadIfNecessary, @
            app.onUnload ->
                app.wrap.unScroll @loadIfNecessary
        setTimeout =>
            @load()

    @property 'loader'

    @property 'transformer'

    LOAD_AMOUNT: 20,
    loaded: 0,
    buffer: 200,

    loadItems: (offset, length, callback) ->
        return unless @_loader and length
        return if offset + length <= @loaded

        if offset < @loaded
            delta = @loaded - offset
            @_loader offset + delta, length - delta, (result) =>
                if result.length < length - delta
                    @max = offset + delta + result.length
                    @element.style.paddingBottom = ''
                callback.call @, result
        else
            @_loader offset, length, (result) =>
                if result.length < length
                    @max = offset + result.length
                    @element.style.paddingBottom = ''

                callback.call @, result

        @loaded = offset + length

    setItems: (items) ->
        @clear()
        @offset = items.length
        @max = items.length
        @addItems items
        @element.style.paddingBottom = ''

    addItems: (items) ->
        for item in items
            @add control = @_transformer item
            @items.push control

        @offset += items.length
        @loadIfNecessary()

    load: ->
        return unless @max is -1
        offset = @offset
        @loadItems offset, @LOAD_AMOUNT, (items) ->
            if offset is @offset
                @addItems items

    loadIfNecessary: ->
        return unless @max is -1
        wrap = @app.wrap.element
        if @element.offsetHeight - @buffer - wrap.scrollTop < wrap.offsetHeight * 2
            @load()

module 'amber', {
    Server
    SiteApp
}
