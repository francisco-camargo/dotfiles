# Minimal Markdown -> HTML converter for this repo's documents.
# Supports: ATX headings, GFM pipe tables, flat bulleted and numbered lists,
# paragraphs, **bold**, `code`.
# Deliberately small -- extend it when a document needs more.

function rep(s, from, to,   out, p) {
  out = ""
  while ((p = index(s, from)) > 0) {
    out = out substr(s, 1, p - 1) to
    s = substr(s, p + length(from))
  }
  return out s
}

function inline(s,   pre, mid, post) {
  s = rep(s, "&", "&amp;")
  s = rep(s, "<", "&lt;")
  s = rep(s, ">", "&gt;")
  while (match(s, /\*\*[^*]+\*\*/)) {
    pre  = substr(s, 1, RSTART - 1)
    mid  = substr(s, RSTART + 2, RLENGTH - 4)
    post = substr(s, RSTART + RLENGTH)
    s = pre "<strong>" mid "</strong>" post
  }
  while (match(s, /`[^`]+`/)) {
    pre  = substr(s, 1, RSTART - 1)
    mid  = substr(s, RSTART + 1, RLENGTH - 2)
    post = substr(s, RSTART + RLENGTH)
    s = pre "<code>" mid "</code>" post
  }
  return s
}

function closetable() { if (intable) { print "</tbody></table>"; intable = 0 } }
function closepara()  { if (inpara)  { print "</p>";             inpara  = 0 } }
function closelist()  { if (inlist)  { print "</" inlist ">";     inlist  = "" } }

function listitem(tag, text) {
  closepara(); closetable()
  if (inlist != tag) { closelist(); print "<" tag ">"; inlist = tag }
  print "<li>" inline(text) "</li>"
}

{
  line = $0
  sub(/\r$/, "", line)

  if (line ~ /^ *$/) { closepara(); closetable(); closelist(); next }

  if (line ~ /^[-*] /) { listitem("ul", substr(line, 3)); next }

  if (match(line, /^[0-9]+\. /)) { listitem("ol", substr(line, RLENGTH + 1)); next }

  if (line ~ /^#+ /) {
    closepara(); closetable(); closelist()
    match(line, /^#+/); lvl = RLENGTH
    printf "<h%d>%s</h%d>\n", lvl, inline(substr(line, lvl + 2)), lvl
    next
  }

  if (line ~ /^\|/) {
    closepara(); closelist()
    body = line
    sub(/^\|/, "", body)
    sub(/\| *$/, "", body)
    if (body ~ /^[ :|-]+$/) next          # header separator row
    n = split(body, cells, /\|/)
    if (!intable) {
      intable = 1
      print "<table><thead><tr>"
      for (i = 1; i <= n; i++) { c = cells[i]; gsub(/^ +| +$/, "", c); print "<th>" inline(c) "</th>" }
      print "</tr></thead><tbody>"
      next
    }
    print "<tr>"
    for (i = 1; i <= n; i++) { c = cells[i]; gsub(/^ +| +$/, "", c); print "<td>" inline(c) "</td>" }
    print "</tr>"
    next
  }

  closetable(); closelist()
  if (!inpara) { print "<p>"; inpara = 1 }
  print inline(line)
}

END { closepara(); closetable(); closelist() }
