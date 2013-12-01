module 'amber.locales.en-US',
  __list: (list) =>
    if list.length is 1
      list[0]
    else if list.length is 2
      list[0] + ' and ' + list[1]
    else
      ((list.slice 0, list.length - 1).join ', ') + ', and ' + list[list.length - 1]
