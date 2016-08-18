exports.staticTags = "announcement tutorial help question request suggestion bug wiki open_issues".split " "
exports.filter =
  openIssues: "([bug] OR [suggestion]) -[fixed] -[duplicate] -[closed] "
