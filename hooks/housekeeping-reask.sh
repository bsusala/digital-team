#!/usr/bin/env bash
# Housekeeping re-ask / re-check surfacer — companion to /housekeeping (step 2). Not an event hook: the command runs
# it. Self-test: housekeeping-selftest.sh.
#
# Usage: housekeeping-reask.sh <ISSUES.md> [TODAY=YYYY-MM-DD]
# Output, one line per item, tab-separated: KIND <TAB> id <TAB> date <TAB> excerpt
#   DUE        a governed re-ask/re-check date on the entry's CURRENT disposition line (with its wrapped continuation),
#              <= TODAY. Reported for Closed entries too: a closed entry with a live passed re-ask on its current
#              disposition is itself a finding.
#   TRIGGER    the current disposition is gated on a re-check / re-ask / trigger with no governed date — adjudicate
#              each pass: fired / not fired / cannot tell. Non-closed entries only.
#   STRAY      a line in a non-closed entry, outside the current disposition extent, carrying a trigger word FOLLOWED
#              by an ISO date on that line, not labelled as history — move the date onto the disposition line, label
#              the line as history, or reword it. A dead date after a live trigger word is one connective away from a
#              false DUE. A date that precedes its trigger word is not flagged: it can never become a DUE.
# Exit code: 0 when the file was read; 2 if it is missing. The VERDICT is the output, never the code.
#
# Governance: the governing trigger is the LAST re-ask/re-check before the date, with nothing between them but
# non-letters and at most one connective (by|on|at|due|until). A disposition line is a bullet whose LABEL starts with
# "Disposition" (one plain qualifier allowed before it); a line whose LABEL says superseded / retained as history /
# replaced / moot / historical never governs and is never STRAY. The current disposition is the LAST eligible line.
# Matching is case-insensitive, which is safe only because it is anchored to the disposition line: a tracker's own
# boilerplate contains the trigger words.

set -u
ISSUES="${1:?usage: housekeeping-reask.sh <ISSUES.md> [TODAY]}"
TODAY="${2:-$(date -u +%F)}"
[ -r "$ISSUES" ] || { echo "housekeeping-reask: cannot read $ISSUES" >&2; exit 2; }

awk -v today="$TODAY" '
function governs(gap) { return gap ~ /^[^A-Za-z]*((by|on|at|due|until)[^A-Za-z]*)?$/ }
# index of the last re-ask / re-check in s, or 0. match() sets the globals RSTART/RLENGTH: callers that iterate
# with match() must snapshot theirs BEFORE calling this, or the outer loop never advances.
function last_trigger(s,   p, n) {
    n = 0; p = tolower(s)
    while (match(p, /re-(ask|check)/)) { n = n + RSTART + RLENGTH - 1; p = substr(p, RSTART + RLENGTH) }
    return n
}
# governed_dates(text): fills gd[] with the dates a trigger word governs; returns the count
function governed_dates(text,   line, consumed, ms, ml, d, head, t, c) {
    c = 0; line = text; consumed = 0
    while (match(line, /[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]/)) {
        ms = RSTART; ml = RLENGTH
        d = substr(line, ms, ml); head = substr(text, 1, consumed + ms - 1)
        line = substr(line, ms + ml); consumed = consumed + ms + ml - 1
        t = last_trigger(head)
        if (t > 0 && governs(substr(head, t + 1))) gd[++c] = d
    }
    return c
}
# trigger_before_date(s): 1 if some ISO date on the line has a trigger word somewhere before it (order-sensitive)
function trigger_before_date(s,   line, consumed, ms, ml, head) {
    line = s; consumed = 0
    while (match(line, /[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]/)) {
        ms = RSTART; ml = RLENGTH
        head = substr(s, 1, consumed + ms - 1)
        line = substr(line, ms + ml); consumed = consumed + ms + ml - 1
        if (last_trigger(head) > 0) return 1
    }
    return 0
}
# label(s): the line label, lowercased; "" if the line is not labelled. A bold-led line (`- **Label:** …`) is
# labelled by its bold span, never by a sentence after it: a later colon in prose would otherwise take over as the
# current disposition and silence the real one. A colon inside the bold span ends the label. A plain line has a short
# colon-terminated label (<= 40 chars, no asterisks). The list bullet is optional in both branches, because some
# trackers keep their labels at column 0.
function label(s,   l) {
    l = tolower(s)
    if (match(l, /^ *([-*] +)?\*\*[^*]+\*\*/)) { l = substr(l, RSTART, RLENGTH); gsub(/\*/, "", l); sub(/^ *([-*] +)?/, "", l); sub(/:.*/, "", l); return l }
    if (l ~ /^ *([-*] +)?[^:*]{1,40}:/) { sub(/^ *([-*] +)?/, "", l); sub(/:.*/, "", l); return l }
    return ""
}
# A disposition label STARTS with the word, or carries one plain qualifier before it ("superseded disposition").
# A label merely containing it ("Housekeeping reading (not a disposition change)", "No `Disposition:` line") is not
# a disposition and must not hijack the current one.
function is_dispo(s)   { return label(s) ~ /^([a-z-]+ )?disposition([^a-z-]|$)/ && label(s) !~ /^no / }
# The LABEL describes the line; the BODY carries the disposition. Governed dates are read from the body only; a
# trigger + date inside the label of a non-closed entry is reported STRAY (move it into the body), never DUE.
function strip_label(s,   l) {
    if (match(s, /^ *([-*] +)?\*\*[^*]+\*\*/)) return substr(s, RSTART + RLENGTH)
    if (match(s, /^ *([-*] +)?[^:*]{1,40}:/)) return substr(s, RSTART + RLENGTH)
    return s
}
# History is read from the LABEL, never the prose: a live disposition saying "replaced by the sweep" is still live.
function is_history(s) { return label(s) ~ /superseded|retained as history|replaced|moot|historical/ }
# a continuation line is neither a new bullet, nor a new bold-led label line, nor blank, nor a heading
function is_cont(s)    { return s !~ /^ *[-*] / && s !~ /^ *\*\*[^*]+\*\*/ && s !~ /^ *$/ && s !~ /^#/ }
function flush(   i, cur, cend, txt, n, k) {
    if (id == "") return
    cur = 0
    for (i = 1; i <= nl; i++) if (is_dispo(L[i]) && !is_history(L[i])) cur = i
    txt = ""; cend = cur
    if (cur) { txt = L[cur]; for (i = cur + 1; i <= nl && is_cont(L[i]); i++) { txt = txt " " L[i]; cend = i } }
    # No current disposition, but a label that names it without leading with it ("PARKED … — Disposition: …"):
    # reported, so the entry never vanishes from the output.
    if (!cur && !closed) for (i = 1; i <= nl; i++) {
        if (label(L[i]) ~ /disposition/ && label(L[i]) !~ /^no / && !is_history(L[i])) { print "STRAY\t" id "\t\t" substr(L[i], 1, 160); break }
    }
    if (cur && !closed && trigger_before_date(substr(L[cur], 1, length(L[cur]) - length(strip_label(L[cur])))))
        print "STRAY\t" id "\t\t" substr(L[cur], 1, 160)
    n = governed_dates(cur ? strip_label(txt) : txt)
    for (k = 1; k <= n; k++) if (gd[k] <= today) print "DUE\t" id "\t" gd[k] "\t" substr(txt, 1, 160)
    if (cur && n == 0 && !closed && tolower(txt) ~ /re-check|re-ask|trigger:/) print "TRIGGER\t" id "\t\t" substr(txt, 1, 160)
    if (!closed) for (i = 1; i <= nl; i++) {
        if (cur && i >= cur && i <= cend) continue
        if (is_history(L[i])) continue
        if (trigger_before_date(L[i])) print "STRAY\t" id "\t\t" substr(L[i], 1, 160)
    }
}
/^## /   { flush(); id = ""; nl = 0; closed = (tolower($0) ~ /^## +closed/) ? 1 : 0; next }
/^### /  { flush(); id = $0; sub(/^### +/, "", id); sub(/ .*/, "", id); nl = 0; if (id !~ /[0-9]/) id = ""; next }
{ if (id != "") L[++nl] = $0 }
END { flush() }
' "$ISSUES"
