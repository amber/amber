{ Base, extend, addClass, removeClass, toggleClass, hasClass, format, htmle, htmlu, bbTouch, inBB } = amber.util
{ Event, PropertyEvent, ControlEvent, TouchEvent, WheelEvent } = amber.event
{ getText: tr, maybeGetText: tr.maybe, getList: tr.list, getPlural: tr.plural } = amber.locale
{ Control, Label, RelativeDateLabel, Image, Menu, MenuItem, MenuSeparator, FormControl, TextField, TextField, TextField, Button, Checkbox, ProgressBar, Container, Form, FormGrid, Dialog } = amber.ui
{ Server, Group, User, RequestError } = amber.models
{ parse } = amber.markup
{ urls } = amber.site

views =
  index: ->
    @setTitle tr('Amber')
    @reloadOnAuthentication = true
    if @user
      @page
        .add(new Label('d-r-title', tr 'News Feed'))
        .add(new Label('d-r-subtitle', tr 'Follow people to see their activity here.'))
        .add(new ActivityCarousel().setLoader (offset, length, callback) =>
          callback({
            icon: @server.getAsset ''
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
          .add(new Link('d-r-splash-link').setView('wiki', 'Help:About')
            .add(new Label('d-r-splash-link-title', tr 'About Amber'))
            .add(new Label('d-r-splash-link-subtitle', tr 'What is this thing?')))
          .add(new Link('d-r-splash-link').setView('wiki', 'Help:Terms of service')
            .add(new Label('d-r-splash-link-title', tr 'Terms of Service'))
            .add(new Label('d-r-splash-link-subtitle', tr 'How can I use it?')))
          .add(new Link('d-r-splash-link').setView('wiki', 'Help:Educators')
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
      .add(new Label('d-r-subtitle', tr 'What the community is remixing this week'))
      .add(topRemixed = new ProjectCarousel(@).setRequestName('topRemixed'))
      .add(new Label('d-r-title', tr 'Top Loved'))
      .add(new Label('d-r-subtitle', tr 'What the community is loving this week'))
      .add(topLoved = new ProjectCarousel(@).setRequestName('topLoved'))
      .add(new Label('d-r-title', tr 'Top Viewed'))
      .add(new Label('d-r-subtitle', tr 'What the community is viewing this week'))
      .add(topViewed = new ProjectCarousel(@).setRequestName('topViewed'))

    @watch (if @user then 'home.signedIn' else 'home.signedOut'), {
      projectCount: (x) ->
        projectCount.setText(tr('% projects', x))
      featured
      byFollowing
      lovedByFollowing
      topRemixed
      topLoved
      topViewed
    }

  explore: ->
    @setTitle tr('Explore'), tr('Amber')
    @page
      .add(list = new LazyList('d-r-fluid-project-list')
        .setLoader((offset, length, callback) =>
          return @request('projects.topLoved',
            offset: offset,
            length: length
          , callback))
        .setCreator(->
          link = new Link('d-r-fluid-project')
          link.add(link.icon = new Image('d-r-fluid-project-thumbnail'))
          link.add(link.name = new Label('d-r-fluid-project-label'))
          link)
        .setHandler((info, link) =>
          link.setView('project', info.id, false)
          link.icon.URL = @app.server.getAsset info.project.thumbnail
          link.name.text = info.project.name))
    list.onLive list.loadIfNecessary

  notFound: (url) ->
    @setTitle tr('Page not found'), tr('Amber')
    @page
      .add(new Label('d-r-title', tr 'Page Not Found'))
      .add(new Label('d-r-paragraph', tr 'The page at the URL "%" could not be found.', url))

  error: (name, message, stack) ->
    @setTitle name, tr('Amber')
    @page
      .add(new Label('d-r-title', name))
      .add(new Label('d-r-paragraph', message))
    if stack?
      @page
        .add(new Label('d-r-error-stack d-scrollable', stack))

  forbidden: ->
    @setTitle tr('Authentication Required'), tr('Amber')
    @page
      .add(new Label('d-r-title', tr 'Authentication Required'))
      .add(new Label('d-r-paragraph', tr 'You need to log in to see this page.'))

  wiki: (rawPage, url) ->
    page = rawPage[0].toUpperCase() + rawPage.slice(1)
    url = page
    if e = /^([^:]+):/.exec page
      [match, namespace] = e
      base = page.substr match.length
      page = namespace[0].toUpperCase() + namespace.slice(1).toLowerCase() + ':' + base[0].toUpperCase() + base.slice(1)
      url = "#{namespace}/#{base}"
    else
      base = page
    @redirect @reverse 'wiki', page
    @requestStart()
    xhr = new XMLHttpRequest
    xhr.open 'GET', "docs/wiki/#{url}.md", true
    xhr.onload = =>
      @requestEnd()
      if xhr.status isnt 200
        return views.notFound.call @, url
      context = parse xhr.responseText
      @setTitle context.config.title ? base, tr('Amber Wiki')
      @page
        .add(title = new Label('d-r-title', context.config.title ? page))
        .add(new Label('d-r-section').setRichText(context.result))
    xhr.send()

  search: (query) ->
    if query then @setTitle query, tr('Amber Search') else @setTitle tr('Search'), tr('Amber')
    @page
      .add(new Label('d-r-title', tr 'Search'))
      .add(new Label('d-r-paragraph', 'This is a placeholder search page.'))

  settings: ->
    @requireAuthentication()
    @setTitle tr('Settings'), tr('Amber')
    @page
      .add(new Label('d-r-title', tr 'Settings'))
      .add(new Container('d-r-block-form')
        .add(new Label('d-r-form-label', tr 'Username'))
        .add(new TextField().setText(@user.name))
        .add(new Label('d-r-form-label', tr 'About Me'))
        .add(new TextField.Multiline().setAutoSize(true))
        .add(new Label('d-r-form-label', tr 'What I\'m Working On'))
        .add(new TextField.Multiline().setAutoSize(true)))

  project: (id, isEdit) ->
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
        .add(player = new amber.editor.ui.Editor().setProjectId(id)))
      .add(new Container('d-r-paragraph d-r-project-stats')
        .add(loves = new Label().setText(tr.plural('% Loves', '% Love', 0)))
        .add(new Separator)
        .add(viewCount = new Label().setText(tr.plural('% Views', '% View', 0)))
        .add(new Separator)
        .add(remixes = new Label().setText(tr.plural('% Remixes', '% Remix', 0))))
      .add(notes = new Label('d-r-paragraph d-r-project-notes'))
      .add(new Container('d-r-paragraph d-r-project-notes-disclosure')
        .add(notesDisclosure = new Button('d-r-link').setText(tr 'Show more').onExecute(toggleNotes).hide()))

    @request 'project', project$id: id, (project) =>
      @setTitle project.name, tr('Amber')
      authors.richText = tr 'by %', tr.list ('<a class=d-r-link href="' + (htmle @abs @reverse 'user.profile', author) + '">' + (htmle author) + '</a>' for author in project.authors)
      title.text = project.name
      notes.text = project.notes
      if (project.notes.split '\n').length > 4
        notes.element.style.height = fixedHeight
        notesDisclosure.show()

      loves.text = tr.plural '% Loves', '% Love', project.loves
      viewCount.text = tr.plural '% Views', '% View', project.views

      player.projectAsset = project.latest
      if isEdit
        player.editMode = true

  'project.new': ->
    @request 'project.create', {}, (project$id) =>
      @redirect @reverse 'project', project$id, true
      views.project.call @, project$id, true

  'user.profile': (user) ->
    @setTitle tr('%\'s Profile', user), tr('Amber')
    @page
      .add(new Container('d-r-user-icon'))
      .add(new Label('d-r-title', user))
      .add(new Container('d-r-user-icon'))
      .add(new ActivityCarousel().setLoader (offset, length, callback) =>
        callback({
          icon: @server.getAsset ''
          description: [
            '<a href=#users/' + user + ' class="d-r-link black">' + user + '</a> shared the project <a href=# class=d-r-link>Summer</a>',
            '<a href=#users/' + user + ' class="d-r-link black">' + user + '</a> followed <a href=#users/MathIncognito class=d-r-link>MathIncognito</a>',
            '<a href=#users/' + user + ' class="d-r-link black">' + user + '</a> loved <a href=# class=d-r-link>Amber is Cool</a>',
            '<a href=#users/' + user + ' class="d-r-link black">' + user + '</a> followed <a href=#users/nXIII- class=d-r-link>nXIII-</a>',
            '<a href=#users/' + user + ' class="d-r-link black">' + user + '</a> shared the project <a href=# class=d-r-link>Custom Blocks</a>'
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
      .add(new ProjectCarousel(@).setRequestName('byUser').setRequestArguments({ user }))
      .add(new Label('d-r-title', tr 'Favorite Projects'))
      .add(new ProjectCarousel(@).setRequestName('topLoved'))
      .add(new Label('d-r-title', tr 'Collections'))
      .add(new Carousel())
      .add(new Label('d-r-title', tr 'Following'))
      .add(new Carousel())
      .add(new Label('d-r-title', tr 'Followers'))
      .add(new Carousel())

  forums: ->
    @setTitle tr('Amber Forums')
    @request 'forums.categories', {}, (categories) =>
      for category in categories
        @page
          .add(new Label('d-r-title', tr.maybe category.name))
        for forum in category.forums
          @page
            .add(new Container('d-r-forum-list')
              .add(new Link('d-r-forum-list-item')
                 .add(new Label('d-r-forum-list-item-title d-r-link', tr.maybe(forum.name)))
                 .add(new Label('d-r-forum-list-item-description', tr.maybe(forum.description)))
                 .setView('forums.forum', forum.id)))

  'forums.forum': (id) ->
    @page
      .add(new Container('d-r-title')
        .add(new Link('d-r-list-up-button').setView('forums'))
        .add(title = new Label))
      .add(new Container('d-r-subtitle')
        .add(subtitle = new Label())
        .add(new Separator('d-r-authenticated'))
        .add(new Link('d-r-link d-r-authenticated')
          .setText(tr 'New Topic')
          .setURL(@reverse('forums.addTopic', id))))
      .add(topics = new LazyList('d-r-topic-list')
        .setLoader((offset, length, callback) =>
          return @request('forums.topics',
            forum$id: id
            offset: offset
            length: length
          , callback))
        .setCreator((topic) =>
          link = new Link('d-r-topic-list-item')
          link.add(new Container('d-r-topic-list-item-title')
              .add(link.nameLabel = new Label('d-r-topic-list-item-name d-r-link'))
              .add(link.userLabel = new Label('d-r-topic-list-item-author')))
            .add(new Container('d-r-topic-list-item-description')
              .add(link.postLabel = new Label)
              .add(new Separator)
              .add(link.viewLabel = new Label))
          link)
        .setHandler((topic, link) =>
          link.setView('forums.topic', topic.id) if topic.id?
          link.nameLabel.text = topic.name if topic.name?
          link.userLabel.richText = tr 'by %', tr.list ('<a class="d-r-link subtle" href="' + (htmle @abs @reverse 'user.profile', author) + '">' + (htmle author) + '</a>' for author in topic.authors)
          link.postLabel.text = tr.plural '% posts', '% post', topic.posts if topic.posts?
          link.viewLabel.text = tr.plural '% views', '% view', topic.views if topic.views?))

    @watch 'forum', forum$id: id, {
      name: (x) ->
        @setTitle tr.maybe(x), tr('Amber Forums')
        title.text = tr.maybe x
      description: (x) -> subtitle.text = tr.maybe x
      topics
    }

  'forums.addTopic': (id) ->
    post = =>
      username = @user.name
      bodyText = body.text
      name = topicName.text
      return unless bodyText.trim() and name.trim()
      @page
        .clear()
        .add(new Container('d-r-title d-r-topic-title')
          .add(new Link('d-r-list-up-button').setView('forums.forum', id))
          .add(new Label('d-inline', name)))
        .add(new Label('d-r-subtitle').setText(tr.plural '% Views', '% View', 0))
        .add(new Container('d-r-post-list')
          .add(new Container('d-r-post pending')
            .add(new Container('d-r-post-title')
              .add(new Label('d-r-post-author')
                .add(new Link().setView('user.profile', username)
                  .add(new Label().setText(username))))
              .add(new RelativeDateLabel('d-r-post-timestamp').setDate(new Date)))
            .add(new Label('d-r-post-body').setRichText(parse(bodyText).result)))
          .add(new Container('d-r-post-spinner')))
        .add(replyForm = @template('replyForm'))
      replyForm.forumId = id
      @request 'forums.topic.add',
        forum$id: id,
        name: name,
        body: bodyText
      , (info) =>
        @page.clear()
        @redirect @reverse('forums.topic', info.topic$id), true
        views['forums.topic'].call @, info.topic$id, 0, null,
          topic:
            forum$id: id
            name: name
            views: 0
          posts: [
            authors: [username]
            body: bodyText
            id: info.post$id
            modified: new Date().toJSON()
          ]

    @requireAuthentication()
    @page
      .add((base = new Form('d-r-new-topic-editor'))
        .onSubmit(post)
        .onCancel(=> @show 'forums.forum', id)
        .add(new Container('d-r-title')
          .add(new Link('d-r-list-back-button').setView('forums.forum', id))
          .add(title = new Label))
        .add(subtitle = new Label('d-r-subtitle'))
        .add(postForm = new Container('d-r-block-form')
          .add(topicName = new TextField('d-textfield d-r-block-field').setPlaceholder(tr 'Topic Name').autofocus())
          .add(new Container('d-r-new-topic-editor-wrap')
            .add(new Container('d-r-new-topic-editor-inner')
              .add(new Container('d-r-new-topic-editor-inner-wrap')
                .add(body = new TextField.Multiline('d-textfield d-r-new-topic-editor-body').setPlaceholder(tr 'Post Body')))))
          .add(new Button('d-button d-r-new-topic-button').setText(tr 'Create Topic').onExecute(base.submit, base))))

    @watch 'forum', forum$id: id,
      name: (x) ->
        @setTitle tr('New Topic'), tr.maybe(x), tr('Amber Forums')
        title.text = tr.maybe x
      description: (x) -> subtitle.text = tr.maybe x

  'forums.topic': (id, num, url, info) ->
    @page
      .add(new Container('d-r-title d-r-topic-title')
        .add(up = new Link('d-r-list-up-button'))
        .add(title = new Label('d-inline')))
      .add(subtitle = new Label('d-r-subtitle'))
      .add(posts = new LazyList('d-r-post-list', +num || 0)
        .setLoader((offset, length, callback) =>
          @request 'forums.posts',
            topic$id: id,
            offset: offset,
            length: length
          , callback)
        .setCreator(-> new Post(replyForm.forumId))
        .setHandler((model, post) -> post.model = model))
      .add(replyForm = @template 'replyForm', id, posts)

    watcher = {
      forum$id: (x) ->
        replyForm.forumId = x
        up.setView 'forums.forum', x
      name: (x) =>
        @setTitle tr.maybe(x), tr('Amber Forums')
        title.text = tr.maybe x
      views: (x) -> subtitle.text = tr.plural '% Views', '% View', x
      posts
    }

    if info
      watcher.forum$id info.topic.forum$id
      watcher.name info.topic.name
      watcher.views info.topic.views
      posts.items = info.posts
    else
      @watch 'topic',
        topic$id: id
        offset: +num || 0
      , watcher

class Post extends Container
  pending: false

  constructor: (@forumId, model) ->
    super 'd-r-post'
    @add(@title = new Label('d-r-post-title'))
    @title.add(@users = new Label('d-r-post-author'))
    @title.add(@timestamp = new RelativeDateLabel('d-r-post-timestamp'))
    @add(@actionButton = new Button('d-r-action-button d-r-post-action').onExecute(@showActions, @))
    @add(@body = new Label('d-r-post-body'))

    @model = model

  @property 'model',
    get: ->
    set: (post) ->
      return unless post?
      @id = post.id if post.id?
      @body.setRichText(parse(@source = post.body).result) if post.body?
      if post.authors?
        @authors = post.authors
        # TODO: should be a delta
        @users.clear()
        for author in post.authors
          if @users.children.length
            @users.add(new Label().setText(',\xa0'))
          @users.add(new Link().setView('user.profile', author)
            .add(new Label().setText(author)))
      if post.modified?
        @timestamp.date = new Date(post.modified)

  update: ->
    @body.richText = parse(@source = @bodyEditor.text).result
    @addClass('pending').add(spinner = new Container('d-r-post-spinner'))
    @app.request 'forums.post.edit',
      post$id: @id,
      body: @bodyEditor.text
    , =>
      @removeClass('pending').remove(spinner)
      @model = { modified: Date.now() }
    @cancel()

  cancel: ->
    @replace(@form, @body).remove(@updateButton).remove(@cancelButton)
    @actionButton.show()

  edit: =>
    return unless @id
    @form = new Form().onSubmit(@update, @).onCancel(@cancel, @)
    @form.add(@bodyEditor = new TextField.Multiline('d-textfield d-r-post-editor').setAutoSize(true).setText(@source))
      .add(@updateButton = new Button().setText(tr 'Update Post').onExecute(@form.submit, @form))
      .add(@cancelButton = new Button('d-button light').setText(tr 'Cancel').onExecute(@form.cancel, @form))
    @replace @body, @form
    @actionButton.hide()
    setTimeout => @bodyEditor.select()

  deletePost: =>
    @pending = true
    @addClass('pending').add(spinner = new Container('d-r-post-spinner'))
    topic = @parent.children[0] is @
    @app.request 'forums.post.delete', post$id: @id, =>
      if topic
        @app.show 'forums.forum', @forumId

  report: =>
    dialog = new Dialog()
      .add((form = new Form())
        .add(new Label('d-r-post-body d-r-report-preview d-scrollable')
          .setRichText(parse(@source).result))
        .add(new TextField.Multiline('d-textfield d-r-report-editor')
          .autofocus()
          .setPlaceholder(tr('Why are you reporting this post?')))
        .add(new Button()
          .setText(tr 'Report')
          .onExecute form.submit, form)
        .add(new Button()
          .setText(tr 'Cancel')
          .onExecute form.cancel, form)
        .onSubmit(=>
          # TODO: report backend
          dialog.close())
        .onCancel(=> dialog.close()))
      .show(@app)

  showActions: ->
    return if @pending or not @id?
    items = [
      { title: tr('Report'), action: @report }
    ]
    if @app.matchesAuthentication @authors
      items = items.concat [
        Menu.separator
        { title: tr('Edit'), action: @edit }
        { title: tr('Delete'), action: @deletePost }
      ]
    new Menu()
      .setItems(items)
      .popDown(@actionButton)

templates =
  replyForm: (topicId, list) ->
    reply = =>
      return unless topicId
      username = @user.name
      post = new Post(postForm.forumId,
          authors: [username]
          body: body.text
          modified: new Date().toJSON()
        ).addClass('pending')
        .add(spinner = new Container('d-r-post-spinner'))
      list.add(post, postForm)
      postForm.hide()
      @wrap.scrollTop = 'max'
      @request 'forums.post.add',
        topic$id: topicId
        body: body.text
      , (id) =>
        post.removeClass 'pending'
        post.remove spinner
        body.text = ''
        postForm.show()
        body.focus()
        post.model = { id }
        @addedPosts[id] = true
        @wrap.scrollTop = 'max'
        ++list.offset
        ++list.max

    return (postForm = new Form('d-r-block-form d-r-new-post-editor'))
      .onSubmit(=>
        return if list.max is -1 or body.text.trim() is ''
        if @user then reply() else @showSignIn())
      .add(body = new TextField.Multiline('d-textfield d-r-new-post-editor-body').setAutoSize(true).autofocus().setPlaceholder(tr 'Write something\u2026'))
      .add(new Button('d-button d-r-authenticated').setText('Reply').onExecute(postForm.submit, postForm))
      .add(new Button('d-button d-r-hide-authenticated').setText('Sign In to Reply').onExecute(postForm.submit, postForm))

class App extends amber.ui.App
  @event 'Unload'

  constructor: ->
    super()
    @setConfig()
    @pendingRequests = 0
    @authenticators = []
    @addedPosts = {}

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
        .add(@panelLink('Discuss', 'forums'))
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
          .add(@panelLink 'Help', 'wiki', 'Help:Contents')
          .add(@panelLink 'About', 'wiki', 'Help:About')
          .add(@panelLink 'Feedback', 'forums.topic', 1)
          .add(@panelLink 'Contact', 'wiki', 'Help:Contact')))

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
    new Container('d-r-page').setSelectable(true)

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
          {
            title: tr 'Profile'
            action: ['show', 'user.profile', @user.name]
          }
          {
            title: tr 'Settings'
            action: ['show', 'settings']
          }
          Menu.separator
          {
            title: tr 'Sign Out'
            action: 'signOut'
          }
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

  matchesAuthentication: (users, user = @user, andAdmin = true) ->
    return false unless user
    return true if andAdmin and user.group is 'administrator'
    username = user.name
    for u in users
      if typeof u is 'string'
        return true if u is username
      else if typeof u is 'number'
        return true if (switch user.group
          when 'administrator' then u & Group.ADMINISTRATOR
          when 'moderator' then u & Group.MODERATOR
          when 'default' then u & Group.DEFAULT)
      else
        return true if u is user
    false

  authenticate: (users, controls, andAdmin = true) ->
    authenticator = ->
      visible = @matchesAuthentication users, @user, andAdmin

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
    @signInError.hide()
    @request(
      'auth.signIn'
      username: @signInUsername.text
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
        error.call @, e if error)

  watch: (name, params, config) ->
    watcher = (data, initial = false) =>
      for key, d of data when handler = config[key]
        if key is 'posts' and not initial
          i = d.length
          while i--
            t = d[i]
            if t[0] is ListChangeType.ADD and t[2] and @addedPosts[t[2].id]
              delete @addedPosts[t[2].id]
              d.splice i, 1
        if typeof handler is 'function'
          handler.call @, d
        if initial
          handler.start d if handler.start
        else
          handler.update d if handler.update

    unless params
      params = {}
    unless config
      config = params
      params = {}

    @watcher = watcher
    @request 'watch.' + name, params, (data) ->
      watcher data, true

  panelLink: (t, view) ->
    new Link('d-r-panel-button').setText(tr t).setURL(@reverse.apply @, [].slice.call arguments, 1)

  notFound: ->
    @page.clear()
    views.notFound.call @, @url
    @

  abs: (url) -> '#' + url

  reverse: (view) ->
    args = [].slice.call arguments, 1
    for url in urls
      if url[1] is view
        source = url[0].source.replace(/^\^/, '').replace(/\\\//g, '/').replace(/\$$/, '')
        arg = 0
        out = source.replace /\((?:[^\)]|\\\))+\)/g, -> args[arg++]
        match = true
        for x in url[2..]
          if x isnt args[arg++]
            match = false
            break
        if match and args.length is arg and url[0].test out
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

  go: (loc, soft) ->
    while loc[loc.length - 1] is '/'
      loc = loc.substr 0, loc.length - 1
    while loc[0] is '/'
      loc = loc.substr 1

    if soft
      location.replace ('' + location).split('#')[0] + '#' + loc
    else
      location.hash = loc
    return if @url is loc

    @hideSignIn() if @signInForm.visible and @signInAutohide

    @_resetPage()
    @url = loc

    try
      for url in urls
        if match = url[0].exec loc
          unless views[url[1]]
            console.error 'Undefined view ' + url[1]
            break

          for x in url[2..]
            match.push x

          match.push match.shift()

          views[url[1]].apply @, match
          @swapIfComplete()
          return @

      views.notFound.call @, loc
    catch e
      if e is @authenticationError
        views.forbidden.call @, loc
      else
        throw e

    @swapIfComplete()
    @

  _resetPage: ->
    @authenticators = []
    @oldListeners = @listeners 'Unload'
    @clearListeners 'Unload'
    @pendingRequests = 0
    @spinner.hide()
    @reloadOnAuthentication = false
    @oldPage = @page if @page.parent
    @page = @createPage()

  load: (view, args...) ->
    @_resetPage()
    views[view].apply @, args.concat [this.url]
    @swapIfComplete()
    @

  swapIfComplete: ->
    return @ unless @oldPage
    if @pendingRequests is 0
      @wrap.replace @oldPage, @page
      @wrap.element.scrollTop = 0
      @dispatch 'Unload', new ControlEvent(@), @oldListeners
      @oldPage = undefined

    @

  reload: ->
    url = @url
    @url = null
    @go url
    @

  template: (name) ->
    templates[name].apply @, [].slice.call arguments, 1

  setTitle: (parts...) ->
    document.title = parts.join ' \xb7 '

class Link extends Button
  constructor: (className = 'd-r-link') ->
    super()
    @element = @container = @newElement className, 'a'
    @element.tabIndex = 0

  setView: (view) ->
    return @setURL App::reverse arguments...

  @property 'URL', apply: (url) ->
    @element.target = ''
    @element.href = @_externalURL = App::abs url

  @property 'externalURL', apply: (url) ->
    @_url = null
    @element.target = '_blank'
    @element.href = url


class Separator extends Label
  constructor: (className = '') ->
    super "d-r-separator #{className}"
    @setText '\xb7'

ListChangeType =
  ADD: 1
  CHANGE: 2
  REMOVE: 3

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

  load: (length = @maxVisibleItemCount() * 2) ->
    return unless @max is -1
    offset = @offset + @maxVisibleItemCount()
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
    @setView 'project', info.id, false
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
      for item, i in items
        if (offset + i) % 3 is 0
          @add @column = new Container 'd-r-activity-carousel-column'

        @column.add control = @_transformer item
        @items.push control

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
    @add @timestamp = new RelativeDateLabel('d-r-activity-carousel-item-time')
  @property 'description', apply: (description) ->
    @descriptionElement.innerHTML = description

  @property 'time', apply: (time) ->
    @timestamp.date = time

  @property 'icon', apply: (url) ->
    @iconElement.src = url


class LazyList extends Container
  constructor: (className = 'd-r-list', @min = 0) ->
    @visibleItems = []
    super(className)
    @element.style.paddingBottom = @buffer + 'px'
    @element.style.paddingTop = if @min then @buffer + 'px' else ''
    @offset = @min
    @max = -1
    @onLive ->
      w = @app.wrap
      if @min isnt 0
        setTimeout =>
          w.element.scrollTop = @element.getBoundingClientRect().top - w.element.getBoundingClientRect().top + @buffer
      w.onScroll @loadIfNecessary, @
    @onUnlive ->
      @app.wrap.unScroll @loadIfNecessary

  @property 'loader'

  @property 'transformer',
    set: (t) ->
      @creator = t
      @handler = ->
    get: -> null
  @property 'creator'
  @property 'handler'

  LOAD_AMOUNT: 20
  loaded: 0
  buffer: 200

  loadItems: (offset, length, callback) ->
    return unless @_loader and length
    return if offset >= @min and offset + length <= @loaded + @min

    if offset < @min
      delta = @min - offset
      @_loader offset, delta, (result) =>
        if @min is 0
          @element.style.paddingTop = ''
        callback.call @, result

      @min -= delta
      @loaded += delta
    else
      if offset < @min + @loaded
        delta = @min + @loaded - offset
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

  @property 'items', apply: (items) ->
    @clear()
    @offset = 0
    @max = items.length
    @addItems items
    @element.style.paddingBottom = ''

  prependItems: (items) ->
    wrap = @app.wrap.element
    h = wrap.scrollHeight

    for item, i in items
      @insert @create(item), @children[i]

    wrap.scrollTop += wrap.scrollHeight - h

    @loadIfNecessary()

  addItems: (items) ->
    for item in items
      @add @create item

    @offset += items.length
    @loadIfNecessary()

  load: ->
    return unless @max is -1
    offset = @offset
    @loadItems offset, @LOAD_AMOUNT, (items) ->
      if offset is @offset
        @addItems items

  loadBackward: ->
    return if @min is 0
    min = @min
    offset = Math.max 0, min - @LOAD_AMOUNT
    @loadItems offset, @LOAD_AMOUNT, (items) ->
      if offset is @min
        @prependItems items

  loadIfNecessary: ->
    wrap = @app.wrap.element
    if @min isnt 0 and wrap.scrollTop + @buffer < wrap.offsetHeight * 2
      @loadBackward()
    if @max is -1 and @element.offsetHeight - @buffer - wrap.scrollTop < wrap.offsetHeight * 2
      @load()

  create: (item) ->
    c = @_creator item
    @_handler item, c
    c

  start: (items = []) ->
    @clear()
    @offset = @min
    @max = if items.length < @LOAD_AMOUNT then items.length else -1
    @element.style.paddingBottom = if @max is -1 then @buffer + 'px' else ''
    @element.style.paddingTop = if @min then @buffer + 'px' else ''
    @addItems items

  update: (changes) ->
    for change in changes
      i = change[1]
      item = change[2]
      switch change[0]
        when ListChangeType.ADD
          if i <= @offset
            bottom = @app.wrap.scrollTop is @app.wrap.maxScrollTop and i is @max
            @insert @create(item), @children[i]
            if @max isnt -1
              ++@max
            ++@offset
            if bottom
              @app.wrap.scrollTop = 'max'
        when ListChangeType.CHANGE
          if c = @children[i]
            @_handler item, c
        when ListChangeType.REMOVE
          if c = @children[i]
            @remove c
            if @max isnt -1
              --@max
            --@offset

module 'amber.site', {
  views
  templates
  App
  parse
  Link
  Separator
  ListChangeType
  Carousel
  CarouselItem
  ProjectCarousel
  ProjectCarouselItem
  ActivityCarousel
  ActivityCarouselItem
  LazyList
}
