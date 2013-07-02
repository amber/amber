@module 'amber.site.views',
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
