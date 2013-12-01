{ Base, extend, addClass, removeClass, toggleClass, hasClass, format, htmle, htmlu, bbTouch, inBB } = amber.util

parse = null

emoticons =
  smile: /^(?:=|:-?)\)/
  wink: /^;-?\)/
  'wide-eyed': /^o\.o/i
  'big-smile': /^(?:=|:-?)D/
  slant: /^(?:=|:-?)[\/\\]/
  tongue: /^(?:=|:-?)P/
  neutral: /^(?:=|:-?)\|/
  frown: /^(?:=|:-?)\(/
  cry: /^(?:=|:-?)'\(/
  confused: /^(?:=|:-?)S/
  'big-frown': /^D(?:=|-?:)/
  heart: /^<3\b/

symbols = [
  [/^<--?>/, '&harr;']
  [/^<--?/, '&larr;']
  [/^--?>/, '&rarr;']
  [/^\s+x\s+/, '&times;']
  [/^\(\s*tm\s*\)/i, '&trade;']
  [/^\(\s*r\s*\)/i, '&reg;']
  [/^\(\s*c\s*\)/i, '&copy;']
]

templates =
  title: (x, title) -> x.config.title = title; ''
  'splash-link': (x, href, title, subtitle) ->
    """
    <a class=d-r-splash-link href="#{htmle linkHref href}">
      <div class=d-r-splash-link-title>#{title}</div>
      <div class=d-r-splash-link-subtitle>#{subtitle}</div>
    </a>
    """
  'splash-links': (x, content) ->
    "<div style=\"overflow: hidden\">#{content}</div>"
  echo: (x, content) -> content

REFERENCE = /^ {0,3}\[([^[\]]+)\]:\s*(.+?)\s*((?:"(?:[^"]|\\[\\"])+"|'(?:[^']|\\[\\'])+'|\((?:[^()]|\\[\\()])+\))?)\s*$/gm
VALID_LINK = /^\w+:|^$|^#/

HORIZONTAL_RULE = /^\s*(?:\*(?:\s*\*){2,}|-(?:\s*-){2,})\s*\n\n+/
HEADING = /^(#{1,6})([^#][^\n]*?)#{0,6}(\n|$)/

LINE_BREAK = /^\\\n/
ESCAPE = /^\\(.)/
CODE = /^`+/
EMPHASIS = /^[_*]/
STRONG = /^(?:__|\*\*)/
DASH_SEQUENCE = /^---+/
EM_DASH = /^(\s*)--(?!-)(\s*)/
EN_DASH = /^\s+-\s+/
DOTS = /^\.{5,}/
ELLIPSIS = /^\.\.\.(\.?)/
SPACE = /^\s+('(?:"')*"?|"(?:'")*'?)/
WORD = /^(['"]*)([a-z0-9][a-z0-9'"]*)/i
QUOTE = /^['"]+/
NON_EMPHASIS = /^\s+(?:\*+|_+)\s+/
LINK = /^(!?)\[([^[\]]+)\]\s*\(([^(\)]*?)\s*((?:"(?:[^"]|\\[\\"])+"|'(?:[^']|\\[\\'])+'|\((?:[^()]|\\[\\()])+\))?)\)/
REFERENCE_LINK = /^(!?)\[([^[\]]+)\]\s*\[([^[\]]*)\]/
AUTOMATIC_LINK = /^<((?:https?|s?ftp|data|file|wss?|about|irc):[^>]*|[0-9a-z-]+(\.[0-9a-z\-]+)+\.*(?::\d+)?(?:\/[^>]*)?)>/
EMAIL_ADDRESS = /^<((?:[a-z0-9!#$%&'*+\-\/=?^_`{|}~]+(?:\.[a-z0-9!#$%&'*+\-\/=?^_`{|}~]+)*|"(?:[^\\"]|\\.)+")@(?:[a-z0-9!#$%&'*+\-\/=?^_`{|}~]+(?:\.[a-z0-9!#$%&'*+\-\/=?^_`{|}~]+)*|\[[^[\]\\]*\]))>/i
TAG = /^<(\/?)(br|del|dd|dl|dt|ins|kbd|sup|sub|mark)>/i
TEMPLATE = /^\{\{\s*/

linkHref = (href) ->
  if href[0] is ':'
    parts = href.substr(1).split(' ')
    amber.site.App::abs amber.site.App::reverse.apply null, parts
  else if href[0] is '%'
    amber.site.App::abs amber.site.App::reverse 'wiki', href.substr(1)
  else if not VALID_LINK.test href
    'http://' + href
  else
    href

link = (image, label, href, title) ->
  href = linkHref href
  if image
    "<img title=\"#{title}\" src=\"#{href}\" alt=\"#{label}\">"
  else
    "<a class=d-r-link title=\"#{title}\" href=\"#{href}\">#{label}</a>"

parseTitle = (title) ->
  switch title[0]
    when '"' then title.substr(1, title.length - 2).replace /\\([\\"])/g, '$1'
    when "'" then title.substr(1, title.length - 2).replace /\\([\\'])/g, '$1'
    when "(" then title.substr(1, title.length - 2).replace /\\([\\()])/g, '$1'
    else ''

parse = (text) ->
  references = {}
  config = {}
  context = { source: text, config, references }

  parseTemplate = (string) ->
    return unless e = /^\s*(\S+)\s*/.exec string
    name = e[1]
    i = e[0].length
    args = []
    while not f = /^\s*}}/.exec (sub = string.substr i)
      if e = /^\s*\{\{\s*/.exec sub
        i += e[0].length
        result = parseTemplate string.substr i
        return unless result
        args.push result.contents
        i += result.length
      else if e = /^\s*('(?:[^']|\\[\\'])*')\s*/.exec sub
        args.push htmle parseTitle e[1]
        i += e[0].length
      else if e = /^\s*(\|+)/.exec sub
        i += e[0].length
        j = string.indexOf e[1], i
        if j is -1
          return
        else
          args.push parseParagraph string.substring i, j
          i = j + e[1].length
      else if e = /^\s*\[/.exec sub
        i += e[0].length
        start = i
        j = 1
        while j
          a = string.indexOf '[', i + 1
          b = string.indexOf ']', i + 1
          return if a is -1 and b is -1
          if a isnt -1 and (a < b or b is -1)
            ++j
            i = a
          if b isnt -1 and (b < a or a is -1)
            --j
            i = b
        args.push parseParagraph string.substring start, i
        i += 1
      else if e = /^\s*(\S+)\s*/.exec sub
        args.push htmle e[1]
        i += e[0].length
      else
        return
    i += f[0].length
    return unless template = templates[name]
    length: i
    contents: template.apply null, [context].concat args

  parseBlock = (text) ->
    index = 0
    if e = /^\n+/.exec text
      result = ''
      index += e[0].length
    else if e = /^\*\s+/.exec text
      index += e[0].length
      items = []
      useParagraph = false
      loop
        p = text.substr index
        match = /\n(\n*)\*\s+/.exec p
        next = match?.index
        terminator = p.search /\n\n+(?!    )(?!\n)|$/
        end = Math.min terminator, if match then next else p.length
        items.push item = p.substr 0, end
        index += end
        useParagraph or= /\n+/.test item
        break if not match or terminator < next
        useParagraph or= match[1]
        e = /\n+\*\s+/.exec p.substr end
        index += e[0].length
      result = ''
      result += "<ul>\n"
      for item in items
        if useParagraph
          i = 0
          item = item.replace(/^    /gm, '')
          length = item.length
          t = ''
          while i < length
            r = parseBlock item.substr i
            t += r.content
            i += r.length
          result += "<li>\n#{t}\n</li>\n"
        else
          t = parseParagraph item
          result += "<li>#{t}</li>\n"
      result += "</ul>\n"
      e = null
    else if e = HEADING.exec text
      n = e[1].length
      title = parseParagraph e[2].trim()
      result = "<h#{n}>#{title}</h#{n}>"
      index += e[0].length
    else if e = /^```/.exec text
      index += e[0].length
      p = text.substr index
      i = p.search /^```/m
      if i is -1
        result = "```"
      else
        code = htmle p.substr 0, i
        result = "<pre class=d-scrollable>#{code}</pre>\n"
        index += i + 3
    else if e = HORIZONTAL_RULE.exec text
      result = '<hr>\n'
      index += e[0].length
    else if /^    /.test text
      i = text.search /\n\n+(?!    )/
      i = text.length if i is -1
      code = text.substr 0, i
      code = htmle code.replace /^    /gm, ''
      result = "<pre class=d-scrollable>#{code}</pre>\n"
      index += i
    else
      i = text.search /\n\n+/
      i = text.length if i is -1
      s = parseParagraph text.substr 0, i
      result = "<div class=d-r-md-paragraph>#{s}</div>\n"
      index += i
    content: result
    length: index

  parseParagraph = (p) ->
    stack = []

    find = (kind) ->
      for entry, j in stack
        if entry.kind is kind
          return j
      -1

    pop = (kind) ->
      return if -1 is i = find kind
      entries = []
      while stack.length > i + 1
        entry = stack.pop()
        s += "</#{entry.kind}>"
        entries.push entry
      entry = stack.pop()
      s += "</#{entry.kind}>"
      for entry in entries
        s += "<#{entry.kind}>"
        stack.push entry

    push = (kind, original) ->
      stack.push {
        kind
        index: s.length
        original: original
      }
      s += "<#{kind}>"

    toggle = (kind, original) ->
      if -1 is find kind
        push kind, original
      else
        pop kind

    leftQuote = (s) -> s.replace(/'/g, "&lsquo;").replace(/"/g, "&ldquo;")
    rightQuote = (s) -> s.replace(/'/g, "&rsquo;").replace(/"/g, "&rdquo;")

    i = 0
    length = p.length
    s = ''
    while i < length
      sub = p.substr i
      done = false
      for name, regex of emoticons
        if e = regex.exec sub
          name = htmle name
          label = htmle e[0]
          s += "<span class=\"d-r-md-emoticon #{name}\">#{label}</span>"
          done = true
          break
      unless done
        for [regex, substitution] in symbols
          if e = regex.exec sub
            s += substitution
            done = true
            break
      if done
      else if e = LINE_BREAK.exec sub
        s += '<br>'
      else if e = ESCAPE.exec sub
        s += e[1]
      else if e = TEMPLATE.exec sub
        if result = parseTemplate p.substr i + e[0].length
          i += result.length
          s += result.contents
        else
          s += e[0]
      else if e = STRONG.exec sub
        toggle 'strong', e[0]
      else if e = EMPHASIS.exec sub
        toggle 'em', e[0]
      else if e = DASH_SEQUENCE.exec sub
        s += e[0]
      else if e = EM_DASH.exec sub
        s += if e[1] then " " else ""
        s += "&mdash;"
        s += if e[2] then " " else ""
      else if e = EN_DASH.exec sub
        s += " &ndash; "
      else if e = DOTS.exec sub
        s += e[0]
      else if e = ELLIPSIS.exec sub
        s += "&hellip;" + e[1]
      else if e = CODE.exec sub
        i += e[0].length
        j = p.indexOf e[0], i
        if j is -1
          s += '`'
        else
          code = htmle p.substring i, j
          code = code.trim()
          s += "<code>#{code}</code>"
          i = j + e[0].length
        e = null
      else if e = WORD.exec sub
        s += leftQuote e[1]
        s += rightQuote e[2]
      else if e = QUOTE.exec sub
        s += rightQuote e[0]
      else if e = NON_EMPHASIS.exec sub
        s += e[0]
      else if e = SPACE.exec sub
        s += ' '
        s += leftQuote e[1]
      else if e = EMAIL_ADDRESS.exec sub
        chunked = ''
        left = e[1]
        while left
          obfuscator = ''
          for x in [1..3]
            obfuscator += String.fromCharCode Math.floor Math.random() * 26 + 97
          chunked += htmle left.substr 0, 6
          chunked += "<span class=d-r-md-email>#{obfuscator}</span>"
          left = left.substr 6
        url = htmle e[1].split('').reverse().join('').replace(/\\/g, '\\\\').replace(/'/g, '\\\'')
        s += "<a class=d-r-link href=\"javascript:window.open('mailto:'+'#{url}'.split('').reverse().join(''))\">#{chunked}</a>"
      else if e = LINK.exec sub
        label = htmle e[2]
        href = e[3]
        title = parseTitle e[4]
        title = htmle title
        href = htmle href
        s += link e[1], label, href, title
      else if e = REFERENCE_LINK.exec sub
        label = htmle e[2]
        href = (e[3] or e[2]).toLowerCase()
        if ref = references[href]
          href = htmle ref.href
          title = htmle ref.title
          s += link e[1], label, href, title
        else
          s += "<span class=d-r-md-error title=\"#{htmle tr 'Missing reference "%"', href}\">#{label}</span>"
      else if e = AUTOMATIC_LINK.exec sub
        url = e[1]
        href = url
        url = htmle url
        href = htmle href
        s += "<a class=d-r-link href=\"#{href}\">#{url}</a>"
      else
        e = null
        unless e
          s += htmle p[i]
          i += 1
      if e
        i += e[0].length
    while entry = stack.pop()
      s = s.substr(0, entry.index) + entry.original + s.substr entry.index + entry.kind.length + 2
    s

  text = text.trim()
  text = text.replace REFERENCE, ({}, name, href, title) ->
    references[name.toLowerCase()] =
      href: href
      title: parseTitle title
    ''

  textLength = text.length
  content = ''
  index = 0
  while index < textLength
    result = parseBlock text.substr index
    content += result.content
    index += result.length

  context.rawResult = content
  context.result = "<div class=d-r-md>#{content}</div>"
  context

module 'amber.markup', {
  emoticons
  symbols
  templates
  parse
}
