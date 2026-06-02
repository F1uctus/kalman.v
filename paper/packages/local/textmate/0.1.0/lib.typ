// .tmLanguage.json -> .sublime-syntax

#let has-key(obj, key) = {
  obj.keys().find(candidate => candidate == key) != none
}

#let get-opt(obj, key) = {
  let found = obj.keys().find(candidate => candidate == key)
  if found != none {
    obj.at(found)
  }
}

#let format-comment(value) = {
  let text = str(value).replace("\t", "    ")
  let trimmed = text.trim()
  if "\n" in trimmed {
    trimmed + "\n"
  } else {
    trimmed
  }
}

#let needs-quoting(value) = {
  let chars = "\"'%-:?@`&*!,#|>0123456789=".codepoints()
  let first = if value.len() > 0 {
    value.at(0)
  } else {
    ""
  }

  return (
    value.len() == 0
      or value.starts-with("<<")
      or chars.find(c => c == first) != none
      or "# " in value
      or ": " in value
      or "[" in value
      or "]" in value
      or "{" in value
      or "}" in value
      or "\n" in value
      or value.ends-with(":")
      or value.ends-with("#")
      or value.trim() != value
  )
}

#let yaml-str(text) = {
  if needs-quoting(text) {
    if "\\" in text or "\"" in text {
      "'" + text.replace("'", "''") + "'"
    } else {
      "\"" + text.replace("\\", "\\\\").replace("\"", "\\\"") + "\""
    }
  } else {
    text
  }
}

#let map-include(value) = {
  let inc = str(value)
  if inc.len() == 0 {
    inc
  } else if inc.at(0) == "#" {
    inc.slice(1)
  } else if inc == "$self" {
    "main"
  } else if inc == "$base" {
    "$top_level_main"
  } else {
    inc
  }
}

#let map-primary-scope(scope) = {
  if scope.starts-with("keyword.") {
    "keyword"
  } else {
    scope
  }
}

#let render-captures(captures, indent) = {
  let lines = ()
  let scope = none
  let list = ()

  for (key, raw) in captures.pairs() {
    let capture-name = if type(raw) == dictionary and has-key(raw, "name") {
      raw.at("name")
    } else {
      raw
    }
    if key == "0" {
      scope = capture-name
    } else {
      list.push((key, capture-name))
    }
  }

  if scope != none {
    lines.push(indent + "scope: " + map-primary-scope(scope))
  }

  if list.len() > 0 {
    lines.push(indent + "captures:")
    for pair in list {
      lines.push(indent + "  " + yaml-str(pair.at(0)) + ": " + yaml-str(pair.at(1)))
    }
  }

  lines
}

#let render-match(rule, indent) = {
  let lines = ()
  let match = get-opt(rule, "match")

  lines.push(indent + "- match: " + yaml-str(match))

  if has-key(rule, "comment") {
    lines.push(indent + "  comment: " + yaml-str(format-comment(get-opt(rule, "comment"))))
  }

  let captures = get-opt(rule, "captures")
  let primary-scope = if type(captures) == dictionary and has-key(captures, "1") {
    let capture-raw = captures.at("1")
    if type(capture-raw) == dictionary and has-key(capture-raw, "name") {
      capture-raw.at("name")
    } else {
      capture-raw
    }
  }
  if captures != none {
    if primary-scope != none {
      lines.push(indent + "  scope: " + map-primary-scope(primary-scope))
    }
    for row in render-captures(captures, indent + "  ") {
      lines.push(row)
    }
  } else if has-key(rule, "name") {
    lines.push(indent + "  scope: " + map-primary-scope(get-opt(rule, "name")))
  }

  lines
}

#let render-end-pattern(end-pattern, end-captures, indent) = (
  indent + "- match: " + yaml-str(end-pattern),
  ..if end-captures != none {
    render-captures(end-captures, indent + "  ")
  },
  indent + "  pop: true",
)

#let render-begin(rule, indent, self) = {
  let lines = ()
  let begin = get-opt(rule, "begin")
  let end = get-opt(rule, "end")
  let end-captures = none
  let child-rows = ()

  lines.push(indent + "- match: " + yaml-str(begin))

  lines.push(indent + "  push:")
  if has-key(rule, "name") {
    lines.push(indent + "    - meta_scope: " + get-opt(rule, "name"))
  } else if has-key(rule, "scope") {
    lines.push(indent + "    - meta_scope: " + get-opt(rule, "scope"))
  }

  if has-key(rule, "patterns") {
    for pat in get-opt(rule, "patterns") {
      for row in self(pat, indent + "    ", self) {
        child-rows.push(row)
      }
    }
  }

  let end-rows = if end != none {
    render-end-pattern(end, end-captures, indent + "    ")
  } else {
    ()
  }
  for row in child-rows {
    lines.push(row)
  }
  for row in end-rows {
    lines.push(row)
  }

  lines
}

#let render-pattern-rule(rule, indent, self) = {
  if has-key(rule, "include") {
    (indent + "- include: " + yaml-str(map-include(get-opt(rule, "include"))),)
  } else if has-key(rule, "match") {
    render-match(rule, indent)
  } else if has-key(rule, "begin") {
    render-begin(rule, indent, self)
  } else {
    ()
  }
}

#let render-pattern-list(patterns, indent, render-rule) = {
  let lines = ()
  if patterns == none {
    return lines
  }
  for pattern in patterns {
    for row in render-rule(pattern, indent, render-rule) {
      lines.push(row)
    }
  }
  lines
}

#let to-sublime-syntax(tmLanguage-path) = {
  let grammar = if type(tmLanguage-path) == str {
    json(bytes(read(tmLanguage-path)))
  } else if type(tmLanguage-path) == bytes {
    json(tmLanguage-path)
  } else {
    tmLanguage-path
  }

  let name = get-opt(grammar, "name")
  let scope = get-opt(grammar, "scopeName")
  let file-types = get-opt(grammar, "fileTypes")
  let top-patterns = get-opt(grammar, "patterns")
  let repository = get-opt(grammar, "repository")

  let lines = (
    "%YAML 1.2",
    "---",
    "# http://www.sublimetext.com/docs/3/syntax.html",
    "name: " + str(name),
    "file_extensions:",
    for ext in file-types {
      "  - " + str(ext)
    },
    "scope: " + str(scope),
    "contexts:",
    "  main:",
    ..render-pattern-list(
      top-patterns,
      "    ",
      render-pattern-rule,
    ),
  )

  for (repo-name, repo-body) in repository.pairs() {
    lines.push("  " + repo-name + ":")
    let repo-rules = if type(repo-body) == array {
      repo-body
    } else {
      (repo-body,)
    }
    for row in render-pattern-list(repo-rules, "    ", render-pattern-rule) {
      lines.push(row)
    }
  }

  let result = lines.join("\n")
  result + "\n"
}
