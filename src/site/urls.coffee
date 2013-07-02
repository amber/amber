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
    [/^mdtest$/, 'mdtest']
]

@module 'amber.site', {
    urls
}
