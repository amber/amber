Amber.Locale.impl['en-US'] = {
  list: function (list) {
    if (list.length === 1) return list[0];
    if (list.length === 2) return list[0] + ' and ' + list[1];
    return list.slice(0, list.length - 1).join(', ') + ', and ' + list[list.length - 1];
  }
};
Amber.Locale.strings['en-US'] = {};
