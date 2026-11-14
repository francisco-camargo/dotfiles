# Read the links between the Markdown files given, paths relative to the repo
# root, and print the files that break the structure rules:
#
#   unreachable    README.md does not reach it by following links
#   orphan         no other file links to it
#   no way back    it links neither to README.md nor to a file linking to it
#   plan not in TODO.md   a file under plans/ that TODO.md does not link to
#   self link      a link to its own file by name, where "#anchor" would do
#
# Links to other sites, and links within a file, are not edges.

function dirname(p) { return p ~ /\// ? substr(p, 1, match(p, /\/[^\/]*$/) - 1) : "" }

# Resolve a relative link against the directory of the file it is in.
function resolve(dir, target,    parts, n, i, out, k, path) {
  path = (target ~ /^\//) ? substr(target, 2) : (dir == "" ? target : dir "/" target)
  n = split(path, parts, "/")
  k = 0
  for (i = 1; i <= n; i++) {
    if (parts[i] == "" || parts[i] == ".") continue
    if (parts[i] == "..") { if (k > 0) k--; continue }
    out[++k] = parts[i]
  }
  path = ""
  for (i = 1; i <= k; i++) path = path (i > 1 ? "/" : "") out[i]
  return path
}

# Record a raw link; it resolves in END, once every file is known.
function edge(from, target) { raw[from, ++nraw[from]] = target; raw_line[from, nraw[from]] = FNR }

function resolve_edge(from, target, line,    t) {
  sub(/^<|>$/, "", target)
  sub(/[ \t].*$/, "", target)
  if (target ~ /^[a-zA-Z][a-zA-Z0-9+.-]*:/ || target ~ /^#/ || target == "") return
  sub(/#.*$/, "", target)
  gsub(/%20/, " ", target)
  t = resolve(dirname(from), target)
  if (!(t in md)) {
    if ((t "/README.md") in md) t = t "/README.md"
    else return
  }
  if (t != from) link[from, t] = 1
  else self_links = self_links "    " from ":" line "\n"
}

FNR == 1 { md[FILENAME] = 1; files[++nfiles] = FILENAME; fence = "" }

{ sub(/\r$/, "") }

fence != "" { if ($0 ~ ("^[ \t]*" fence "[ \t]*$")) fence = ""; next }
/^[ \t]*(```|~~~)/ { match($0, /(```+|~~~+)/); fence = substr($0, RSTART, RLENGTH); next }

/^ {0,3}\[[^]]+\]:[ \t]*[^ \t]/ {
  line = $0
  sub(/^ {0,3}\[[^]]+\]:[ \t]*/, "", line)
  edge(FILENAME, line)
  next
}

{
  line = $0
  gsub(/`[^`]*`/, "", line)
  while (match(line, /\]\([^)]+\)/)) {
    edge(FILENAME, substr(line, RSTART + 2, RLENGTH - 3))
    line = substr(line, RSTART + RLENGTH)
  }
}

function report(label, list) {
  printf "  %s:\n", label
  if (list == "") print "    (none)"
  else printf "%s", list
}

END {
  for (i = 1; i <= nfiles; i++)
    for (j = 1; j <= nraw[files[i]]; j++) resolve_edge(files[i], raw[files[i], j], raw_line[files[i], j])

  root = ("README.md" in md) ? "README.md" : ""

  # Breadth-first from README.md; small repos make the square loop cheap.
  if (root != "") {
    seen[root] = 1
    queue[1] = root; head = 1; tail = 1
    while (head <= tail) {
      f = queue[head++]
      for (i = 1; i <= nfiles; i++) {
        t = files[i]
        if (((f, t) in link) && !(t in seen)) { seen[t] = 1; queue[++tail] = t }
      }
    }
  }

  for (i = 1; i <= nfiles; i++) {
    f = files[i]
    if (f == root) continue
    if (root == "") unreachable = unreachable "    " f "\n"
    else if (!(f in seen)) unreachable = unreachable "    " f "\n"

    linked = 0; back = ((f, root) in link)
    for (j = 1; j <= nfiles; j++) {
      g = files[j]
      if ((g, f) in link) { linked = 1; if ((f, g) in link) back = 1 }
    }
    if (!linked) orphans = orphans "    " f "\n"
    # TODO.md is the index of the plans, and the owner opens each from there.
    if (f ~ /^plans\// && (("TODO.md", f) in link)) back = 1
    if (!back) noback = noback "    " f "\n"

    if (f ~ /^plans\// && ("TODO.md" in md) && !(("TODO.md", f) in link))
      unplanned = unplanned "    " f "\n"
  }

  if (root == "") print "  no README.md at the root, so nothing is reachable from it"
  report("unreachable from README.md", unreachable)
  report("linked from no other file", orphans)
  report("no link back to README.md or to a file linking here", noback)
  report("plans that TODO.md does not link to", unplanned)
  report("links to their own file by name, where an anchor alone would do", self_links)
}
