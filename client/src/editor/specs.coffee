so = (x) -> sprite: x
go = (x) -> stage: x

specs =
    motion: [
        so ['c', 'motion', 'forward:', 'move %f steps', 10]
        so ['c', 'motion', 'turnRight:', 'turn @turnRight %f degrees', 15]
        so ['c', 'motion', 'turnLeft:', 'turn @turnLeft %f degrees', 15]
        so '-'
        so ['vs', $:'direction']
        so ['c', 'motion', 'pointTowards:', 'point towards %m.spriteOrMouse']
        so '-'
        so ['c', 'motion', 'gotoX:y:', 'go to x: %f y: %f', 0, 0]
        so ['c', 'motion', 'gotoSpriteOrMouse:', 'go to %m.spriteOrMouse']
        so ['c', 'motion', 'glideSecs:toX:y:elapsed:from:', 'glide %f secs to x: %f y: %f', 1, 0, 0]
        so '-'
        so ['vc', $:'x position']
        so ['vs', $:'x position']
        so ['vc', $:'y position']
        so ['vs', $:'y position']
        so '-'
        so ['c', 'motion', 'bounceOffEdge', 'if on edge, bounce']
        so '-'
        so ['vs', $:'rotation style']
        so '-'
        so ['v', $:'x position']
        so ['v', $:'y position']
        so ['v', $:'direction']
        so ['v', $:'rotation style']
        go ['!', $:'Stage selected: no motion blocks']
    ]
    looks: [
        so ['c', 'looks', 'say:duration:elapsed:from:', 'say %s for %f secs', 'Hello!', 2]
        so ['c', 'looks', 'say:', 'say %s', 'Hello!']
        so ['c', 'looks', 'think:duration:elapsed:from:', 'think %s for %f secs', 'Hmm\u2026', 2]
        so ['c', 'looks', 'think:', 'think %s', 'Hmm\u2026']
        so '-'
        so ['c', 'looks', 'show', 'show']
        so ['c', 'looks', 'hide', 'hide']
        so '-'
        so ['c', 'looks', 'lookLike:', 'switch costume to %m.costume']
        so ['c', 'looks', 'nextCostume', 'next costume']
        so '-'
        ['c', 'looks', 'startScene', 'switch backdrop to %m.backdrop']
        ['c', 'looks', 'startNextScene', 'next backdrop']
        '-'
        ['vc', $:'color effect']
        ['vs', $:'color effect']
        ['c', 'looks', 'filterReset', 'clear graphic effects']
        '-'
        so ['vc', $:'size']
        so ['vs', $:'size']
        so '-'
        so ['c', 'looks', 'comeToFront', 'go to front']
        so ['c', 'looks', 'goBackByLayers:', 'go back %i layers', 1]
        so '-'
        so ['v', $:'costume #']
        so ['v', $:'costume name']
        ['v', $:'backdrop #']
        ['v', $:'backdrop name']
        so ['v', $:'size']
    ]
    sound: [
        ['c', 'sound', 'playSound:', 'play sound %m.sound']
        ['c', 'sound', 'doPlaySoundAndWait', 'play sound %m.sound until done']
        ['c', 'sound', 'stopAllSounds', 'stop all sounds']
        '-'
        ['c', 'sound', 'playDrum', 'play drum %i.drum for %f beats', 48, .2]
        ['c', 'sound', 'rest:elapsed:from:', 'rest for %f beats', .2]
        '-'
        ['c', 'sound', 'noteOn:duration:elapsed:from:', 'play note %i.note for %f beats', 60, .5]
        ['vs', $:'instrument']
        '-'
        ['vc', $:'volume']
        ['vs', $:'volume']
        ['v', $:'volume']
        '-'
        ['vc', $:'tempo']
        ['vs', $:'tempo']
        ['v', $:'tempo']
    ]
    pen: [
        ['c', 'pen', 'clearPenTrails', 'clear']
        '-'
        ['c', 'pen', 'stampCostume', 'stamp']
        '-'
        ['c', 'pen', 'putPenDown', 'pen down']
        ['c', 'pen', 'putPenUp', 'pen up']
        '-'
        ['vs', $:'pen color']
        ['vc', $:'pen hue']
        ['vs', $:'pen hue']
        '-'
        ['vc', $:'pen lightness']
        ['vs', $:'pen lightness']
        '-'
        ['vc', $:'pen size']
        ['vs', $:'pen size']
    ]
    data: [
        ['&', 'createVariable', $:'Make a Variable']
        '-'
        so 'gv'
        so '-'
        'v'
        '-'
        ['vs']
        ['vc']
        ['c', 'data', 'showVariable:', 'show variable %m.var']
        ['c', 'data', 'hideVariable:', 'hide variable %m.var']
        '-'
        ['c', 'lists', 'append:toList:', 'add %s to %m.list', $:'thing', '']
        '-'
        ['c', 'lists', 'deleteLine:ofList:', 'delete %i.deletionIndex of %m.list', 1, '']
        ['c', 'lists', 'insert:at:ofList:', 'insert %s at %i.index of %m.list', $:'thing', 1, '']
        ['c', 'lists', 'setLine:ofList:to:', 'replace item %i.index of %m.list with %s', 1, '', $:'thing']
        '-'
        ['r', 'lists', 'getLine:ofList:', 'item %i.index of %m.list', 1, '']
        ['r', 'lists', 'lineCountOfList:', 'length of %m.list']
        ['b', 'lists', 'list:contains:', '%m.list contains %s?', '', $:'thing']
        '-'
        ['c', 'lists', 'showList:', 'show list %m.list', '']
        ['c', 'lists', 'hideList:', 'hide list %m.list', '']
    ]
    events: [
        ['h', 'events', 'whenGreenFlag', 'when @greenFlag clicked']
        ['h', 'events', 'whenKeyPressed', 'when %m.key key pressed', $:'space']
        ['h', 'events', 'whenClicked', 'when @target clicked']
        ['h', 'events', 'whenSceneStarts', 'when backdrop switches to %m.backdrop']
        '-'
        ['h', 'events', 'whenSensorGreaterThan', 'when %m.triggerSensor > %f', $:'loudness', 10]
        '-'
        ['h', 'events', 'whenIReceive', 'when I receive %m.event']
        ['c', 'events', 'broadcast:', 'broadcast %m.event']
        ['c', 'events', 'doBroadcastAndWait', 'broadcast %m.event and wait']
    ]
    control: [
        ['r', 'system', 'commandClosure', '%parameters %c']
        ['r', 'system', 'reporterClosure', '%parameters %reporter']
        '-'
        ['c', 'control', 'wait:elapsed:from:', 'wait %f secs', 1]
        '-'
        ['c', 'control', 'doRepeat', 'repeat %i %c', 10]
        ['t', 'control', 'doForever', 'forever %c']
        '-'
        ['c', 'control', 'doIf', 'if %b %c']
        ['c', 'control', 'doIfElse', 'if %b %c else %c']
        ['c', 'control', 'doWaitUntil', 'wait until %b']
        ['c', 'control', 'doUntil', 'repeat until %b %c']
        '-'
        ['t', 'control', 'stopScripts', 'stop %m.stop', $:'all']
        '-'
        so ['h', 'control', 'whenCloned', 'when I start as a clone']
        ['c', 'control', 'createCloneOf', 'create clone of %m.spriteOrSelf', $:'myself']
        so ['t', 'control', 'deleteClone', 'delete this clone']
    ]
    sensing: [
        so ['b', 'sensing', 'touching:', 'touching %m.spriteOrMouse?']
        so ['b', 'sensing', 'touchingColor:', 'touching color %color?']
        so ['b', 'sensing', 'color:sees:', 'color %color is touching %color?']
        so ['r', 'sensing', 'distanceTo:', 'distance to %m.spriteOrMouse']
        so '-'
        ['c', 'sensing', 'doAsk', 'ask %s and wait', $:"What's your name?"]
        ['v', $:'answer']
        '-'
        ['b', 'sensing', 'keyPressed:', 'key %m.key pressed?', $:'space']
        ['v', $:'mouse down?']
        ['v', $:'mouse x']
        ['v', $:'mouse y']
        '-'
        ['v', $:'loudness']
        '-'
        ['r', 'sensing', 'senseVideoMotion', 'video %m.videoMotion on %m.stageOrThis', ($:'motion'), ($:'this sprite')]
        ['c', 'sensing', 'setVideoState', 'turn video %m.videoState', $:'on']
        ['vs', $:'video transparency']
        '-'
        ['v', $:'timer']
        ['vs', $:'timer']
        '-'
        ['r', 'sensing', 'getAttribute:of:', '%m.attribute of %m.spriteOrStage', ($:'backdrop name'), ($:'Stage')]
        '-'
        ['r', 'sensing', 'timeAndDate', 'current %m.timeAndDate', $:'minute']
        ['r', 'sensing', 'timestamp', 'days since 2000']
        ['r', 'sensing', 'getUserName', 'username']
    ]
    operators: [
        ['r', 'operators', '+', '%f + %f']
        ['r', 'operators', '-', '%f - %f']
        ['r', 'operators', '*', '%f \xd7 %f']
        ['r', 'operators', '/', '%f / %f']
        '-'
        ['r', 'operators', 'randomFrom:to:', 'pick random %f to %f', 1, 10]
        '-'
        ['b', 'operators', '<', '%s < %s']
        ['b', 'operators', '=', '%s = %s']
        ['b', 'operators', '>', '%s > %s']
        '-'
        ['b', 'operators', '&', '%b and %b']
        ['b', 'operators', '|', '%b or %b']
        ['b', 'operators', 'not', 'not %b']
        '-'
        ['b', 'operators', 'true', 'true']
        ['b', 'operators', 'false', 'false']
        '-'
        ['r', 'operators', 'concatenate:with:', 'join %s %s', 'hello ', 'world']
        ['r', 'operators', 'letter:of:', 'letter %i of %s', 1, 'world']
        ['r', 'operators', 'stringLength:', 'length of %s', 'world']
        '-'
        ['r', 'operators', '%', '%f mod %f']
        ['r', 'operators', 'rounded', 'round %f']
        '-'
        ['r', 'operators', 'computeFunction:of:', '%m.math of %f', $:'sqrt', 10]
    ]
    undefined: [
        ['c', undefined, 'drum:duration:elapsed:from:', 'play drum %f for %f beats', 1, 0.25],
        ['c', undefined, 'midiInstrument:', 'set instrument to %f', 1],
        ['b', undefined, 'isLoud', 'loud?'],
        ['r', undefined, 'abs', 'abs %f'],
        ['r', undefined, 'sqrt', 'sqrt %f'],
        ['t', undefined, 'doReturn', 'stop script'],
        ['t', undefined, 'stopAll', 'stop all'],
        ['c', undefined, 'showBackground:', 'switch to background %m.costume', 'backdrop1'],
        ['c', undefined, 'nextBackground', 'next background'],
        ['t', undefined, 'doForeverIf', 'forever if %b %c'],

        ['r', undefined, 'COUNT', 'noop']
        ['r', undefined, 'COUNT', 'counter']
        ['c', undefined, 'CLR_COUNT', 'clear counter']
        ['c', undefined, 'INCR_COUNT', 'incr counter']
        ['c', undefined, 'doForLoop', 'for each %m.var in %s %c']
        ['c', undefined, 'doWhile', 'while %b %c']
        ['c', undefined, 'warpSpeed', 'all at once %c']
        ['c', undefined, 'scrollRight', 'scroll right %f']
        ['c', undefined, 'scrollUp', 'scroll up %f']
        ['c', undefined, 'scrollAlign', 'align scene %m.scrollAlign', $:'bottom-left']
        ['v', $:'x scroll']
        ['v', $:'y scroll']
        ['c', undefined, 'hideAll', 'hide all sprites']
        ['r', undefined, 'getUserId', 'user id']
    ]

specsBySelector =
    'setVar:to:': ['vs', 'var']
    'changeVar:by:': ['vc', 'var']
    'readVariable': ['v', 'var']

categoryColors =
    # motion: 'rgb(29%, 42%, 83%)'
    # motor: 'rgb(11%, 31%, 73%)'
    # looks: 'rgb(56%, 34%, 89%)'
    # sound: 'rgb(81%, 29%, 85%)'
    # pen: 'rgb(0%, 63%, 47%)'
    # control: 'rgb(90%, 66%, 13%)'
    # sensing: 'rgb(2%, 58%, 86%)'
    # operators: 'rgb(38%, 76%, 7%)'
    # variables: 'rgb(95%, 46%, 11%)'
    # lists: 'rgb(85%, 30%, 7%)'
    # other: 'rgb(62%, 62%, 62%)'
    system: 'rgb(50%, 50%, 50%)'

    # Object.keys(d.categoryColors).reduce(function (o,k) { var c = d.categoryColors[k].toString(16); o[k] = '#' + '000000'.substr(c.length) + c; return o }, {});
    # 'undefined': 13903912,
    # motion: 4877524,
    # looks: 9065943,
    # sound: 12272323,
    # pen: 957036,
    # events: 13140784,
    # control: 14788890,
    # sensing: 2926050,
    # operators: 6076178,
    # data: 15629590,
    # custom: 5447321,
    # parameter: 5851057,
    # lists: 13392674,
    # extensions: 6761849
    control: '#e1a91a'
    custom: '#531e99'
    data: '#ee7d16'
    events: '#c88330'
    extensions: '#672d79'
    lists: '#cc5b22'
    looks: '#8a55d7'
    motion: '#4a6cd4'
    operators: '#5cb712'
    parameter: '#5947b1'
    pen: '#0e9a6c'
    sensing: '#2ca5e2'
    sound: '#bb42c3'
    undefined: '#d42828'

do ->
    for name, category of specs
        for spec in category when spec isnt '-'
            spec = spec.sprite if spec.sprite
            spec = spec.stage if spec.stage
            switch spec[0]
                when 'c', 't', 'r', 'b', 'h'
                    specsBySelector[spec[2]] = spec

checkScratchSpecs = (specs) ->
    for spec in specs when spec.length > 1
        if not specsBySelector[spec[3]]
            console.warn "Missing block '#{spec[0]}' for ##{spec[3]}"

module 'amber.editor', {
    specs
    specsBySelector
    checkScratchSpecs
    categoryColors
}
