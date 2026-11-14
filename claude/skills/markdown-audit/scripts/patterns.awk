# Print each line of the Markdown files given that breaks a writing rule a
# pattern can find, as "file:line: rule: text".
#
# The rule names match the headings in ~/.claude/CLAUDE.md, so the skill can
# keep only hits whose rule a CLAUDE.md in force states. A hit is a place to
# look, not a verdict: "now" in "six months from now" breaks no rule.
#
# Front matter and fenced code are skipped, and inline code and link targets
# are removed before matching, since neither is prose.

function hit_at(rule, line, shown) {
  sub(/^[ \t]+/, "", shown)
  if (length(shown) > 100) shown = substr(shown, 1, 97) "..."
  printf "%s:%d: %s: %s\n", FILENAME, line, rule, shown
}
function hit(rule) { hit_at(rule, FNR, raw) }

# A whole word, ignoring case.
function has_word(words) {
  return lower ~ ("(^|[^a-z'])(" words ")([^a-z']|$)")
}

{ sub(/\r$/, ""); raw = $0 }

# A prose line that ends mid-sentence, followed by more of the same
# paragraph, is a hard wrap. The check needs the next line, so the line in
# question waits in wrap_line; anything but a continuation clears it.
FNR == 1 { wrap_line = 0 }
wrap_line && ($0 ~ /^[ \t]*$/ || $0 ~ /^ {0,3}(#|>|\||```|~~~|<)/ || $0 ~ /^[ \t]*([-*+]|[0-9]+[.)])[ \t]/) {
  wrap_line = 0
}
wrap_line {
  hit_at("one sentence per line", wrap_line, wrap_text)
  wrap_line = 0
}

FNR == 1 {
  fence = ""
  front = ($0 ~ /^---[ \t]*$/)
  if (front) next
}

front {
  if ($0 ~ /^(---|\.\.\.)[ \t]*$/) front = 0
  next
}

# A fence closes only on the marker that opened it.
fence != "" {
  if ($0 ~ ("^[ \t]*" fence "[ \t]*$")) fence = ""
  next
}
/^[ \t]*(```|~~~)/ {
  match($0, /(```+|~~~+)/)
  fence = substr($0, RSTART, RLENGTH)
  if ($0 ~ /^[ \t]*(```+|~~~+)[ \t]*$/) hit("code blocks name their language")
  next
}

# HTML comments and reference definitions are not prose. A comment can run
# over many lines, such as a list kept out of the rendered page.
FNR == 1 { comment = 0 }
comment { if ($0 ~ /-->/) comment = 0; next }
/^[ \t]*<!--/ { if ($0 !~ /-->/) comment = 1; next }
/^ {0,3}\[[^]]+\]:/ { next }

{
  text = $0
  gsub(/``[^`]+``|`[^`]*`/, "", text)
  link_text = text
  gsub(/\]\([^)]*\)/, "]", text)
  gsub(/<https?:[^>]*>/, "", text)
  # A word in quotes is mentioned, not used.
  lower = tolower(text)
  gsub(/"[^"]*"/, "", lower)

  heading = (text ~ /^ {0,3}#{1,6}[ \t]/)
  item = (text ~ /^[ \t]*([-*+]|[0-9]+[.)])[ \t]/)
  table = (text ~ /^[ \t]*\|/)

  if (text ~ /—/) hit("no em dashes")

  if (has_word("just|simply|easily|obviously|very|really|actually")) hit("filler words")

  # "new" is left out: it describes ("a new machine") far more often than it
  # dates, and reading finds the rare case where it dates.
  if (has_word("today|currently|now|recently|soon")) hit("no details that go stale")

  if (lower ~ /not un[a-z]+/ && lower !~ /not un(til|der|less|ion|it)/ \
      || has_word("not without|no small|not a bad|no accident|would not be unreasonable"))
    hit("no litotes")

  if (!item && text ~ /^ {0,3}(\*\*|__)[^*_]+(\*\*|__)/) hit("headings and lists, not bold titles")

  if (text ~ /^ {0,3}([-*_][ \t]*){3,}$/) hit("no horizontal rules")

  if (heading) {
    h = text
    sub(/^ *#+[ \t]+([0-9]+[.)][ \t]+)?/, "", h)
    n = split(h, w, /[ \t]+/)
    for (i = 2; i <= n; i++)
      if (w[i] ~ /^[A-Z][a-z]/) { hit("headings in sentence case"); break }
  }

  if (tolower(link_text) ~ /\[(here|this|this link|link|click here)\]\(/) hit("link text names the target")
  if (text ~ /https?:\/\//) hit("link text names the target")

  if (!heading && !item && !table) {
    s = text
    gsub(/(e\.g|i\.e|etc|vs|cf)\./, "", s)
    if (s ~ /[a-z0-9)\]`"'*_][.!?][)"'*_]* +[A-Z`*_[]/) hit("one sentence per line")
  }

  # Two trailing spaces or a backslash is a deliberate line break.
  if (!heading && !table && raw !~ /^[ \t]*$/ && raw !~ /[.!?:;][]`"')*_]*[ \t]*$/ \
      && raw !~ /(  |\\)$/) {
    wrap_line = FNR
    wrap_text = raw
  }
}
