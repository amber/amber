Hello, world!

Do you see any *Teletubbies* in _here_? Do you see a slender plastic tag clipped to my shirt with my name printed on it? *Do you __see a* little__ Asian child with *a __blank__ expression* on ***his*** _**face**_ _**sitting_** outside on a mechanical helicopter that shakes when test_the_underscores M\*A\*S\*H you put quarters in it? No? Well, that's what you see at a toy store. And you must think you're in a __toy store__, because you're here shop*ping for an **infant named Jeb**.

This is a [plain old link](google.com/404) and another [link](http://ww.google.com/404/ 'Titles are cool!') and an [internal link](#forums 'Forums!') and a [data: URI link](data:text/html,Hello, World! 'Title'). This is a [reference]  [1] and an empty [reference] [] or unspaced [reference][] or [reference][foo].

  [reference]: http://google.com          'Title'
  [1]:google.com
  [foo]:       data:text/html,Hello World! 'Title'

Some URLs. First, google: <http://www.google.com> or <google.com> or <www.google.com>. Now <data:text/html,Hello, world!> and <ftp://ftp.example.com> and <sftp://sftp.example.com>. You can email me at <queryselector@gmail.com> or <notan\email@gmail.com>. Some more:

<niceandsimple@example.com>
<very.common@example.com>
<a.little.lengthy.but.fine@dept.example.com>
<disposable.style.email.with+symbol@example.com>
<user@[IPv6:2001:db8:1ff::a0b:dbd0]>
<"much.more unusual"@example.com>
<"very.unusual.@.unusual.com"@example.com>
<"very.(),:;<>[]\".VERY.\"very@\\ \"very\".unusual"@strange.example.com>
<postbox@com>
<admin@mailserver1>
<!#$%&'*+-/=?^_`{}|~@example.org>
<" "@example.org>
<"()<>[]:,;@\\\"!#$%&'*+-/=?^_`{}| ~.a"@example.org>

HTML tags: not a URL. <mark>Mark</mark> <span style="color: #888">Hello, world!</span> <ins data-awesome>inserted</ins>.

Quotations: "You live and learn. At any rate, you live." --Douglas Adams. Someone yelled "Fire! Watch out, 'it's a nested quote!'" The word 'antidisestablishmentarianism' is silly. Don't do it! "" '' "what!?"

"'"'Why did I nest so many quotes?'"'"

"""Do these even "*render*" correctly?"""

Dashes. Foo--bar. Foo - bar. Foo-bar. Foo -- bar. Foo ---- bar.

# Heading 1
## Heading 2
### Heading 3 ###
#### Heading 4 #
##### Heading #5 #
###### Heading 6
####### Heading 7 (*just* kidding)

# #!/bin/sh

---

Now that we know who you are, I know who I am. I'm not a mistake! It all makes sense! In a comic, you know how you can tell who the arch-villain's going to be? He's the exact opposite of the hero. And most times they're friends, like you and me! I should've known way back when... You know why, David? Because of the kids. They called me Mr Glass. `test(12)`. Multiple backticks: ``` `yada` ``foo`` ```. Triple-backtick block:

```
parse = (text) ->
    CODE = /^`/
    EMPHASIS = /^[_*]/
    STRONG = /^(?:__|\*\*)/
    SPACE = /^\s+/
    WORD = /^(?:[a-z0-9]+|\s+(?:\*+|_+)\s+)/i

    if /^    /.test p
        code = htmle p.replace /^    /gm, ''
        "<pre><code>#{code}</code></pre>"
```

Text.

    parse = (text) ->
        CODE = /^`/
        EMPHASIS = /^[_*]/
        STRONG = /^(?:__|\*\*)/
        SPACE = /^\s+/
        WORD = /^(?:[a-z0-9]+|\s+(?:\*+|_+)\s+)/i

        parseParagraph = (p) ->
            if /^\s*(?:\*(?:\s*\*){2,}|-(?:\s*-){2,})\s*$/.test p
                '<hr>'
            else if /^    /.test p
                code = htmle p.replace /^    /gm, ''
                "<pre>#{code}</pre>"
            else
                stack = []
                pop = (kind) ->
                    i = stack.lastIndexOf kind
                    return if i is -1
                    while stack.length > i
                        k = stack.pop()
                        s += "</#{k}>"
                push = (kind) ->
                    s += "<#{kind}>"
                    stack.push kind
                toggle = (kind) ->
                    if -1 is stack.indexOf kind
                        push kind
                    else
                        pop kind
                i = 0
                length = p.length
                s = ''
                while i < length
                    if p[i] is '\\'
                        s += p[i + 1]
                        i += 2
                    else if e = STRONG.exec p.substr i
                        toggle 'strong'
                        i += e[0].length
                    else if e = EMPHASIS.exec p.substr i
                        toggle 'em'
                        i += e[0].length
                    else if e = CODE.exec p.substr i
                        i += e[0].length
                        j = p.substr(i).search /`/
                        if j is -1
                            s += '`'
                        else
                            code = htmle p.substr i, j
                            s += "<code>#{code}</code>"
                            i += j + 1
                    else if e = WORD.exec p.substr i
                        s += e[0]
                        i += e[0].length
                    else if e = SPACE.exec p.substr i
                        s += ' '
                        i += e[0].length
                    else
                        s += htmle p[i]
                        i += 1
                "<div class=d-r-md-paragraph>#{s}</div>"
        content = text
            .trim()
            .split(/\n\n+/)
            .map(parseParagraph)
            .join('')
        "<div class=d-r-md>#{content}</div>"

This is a test. I hate arithmetic, like 1 + 4 * 6 + 2 _ 3 ** 4
