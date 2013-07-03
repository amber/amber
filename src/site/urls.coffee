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
    [/^forums$/, 'forums']
    [/^forums\/(\w+)$/, 'forums.forum']
    [/^forums\/(\w+)\/add-topic$/, 'forums.addTopic']
    [/^forums\/t\/(\w+)$/, 'forums.topic']
    [/^forums\/p\/(\w+)$/, 'forums.post']
    [/^mdtest\/(.+)$/, 'mdtest']
]

@module 'amber.site', {
    urls
}
