#!/bin/sh
# Signiert das Manifest des gluon-domain-changer.
#
#   sign-manifest.sh <secret> <manifest>        SERIAL erhoehen, alte Signaturen verwerfen, signieren
#   sign-manifest.sh --add <secret> <manifest>  weitere Signatur anhaengen, ohne das Manifest zu aendern
#
# Das Format der Signatur entspricht contrib/sign.sh aus Gluon (Autoupdater-Manifest).

set -e

MAX_SIZE=1048576

usage() {
	cat <<EOHELP
Usage: $0 [--add] <secret> <manifest>

Without --add the SERIAL of the manifest is set to the current Unix timestamp
(at least the old SERIAL + 1), all existing signatures are removed and the
manifest is signed with <secret>. Use this after every change of the manifest.

With --add the manifest is left unchanged and another signature is appended,
e.g. by a second administrator when good_signatures > 1.

The entries are validated before signing. The manifest is replaced atomically.
EOHELP
	exit 1
}

die() {
	echo "Error: $*" >&2
	exit 1
}

ADD=0
if [ "$1" = "--add" ]; then
	ADD=1
	shift
fi

if [ $# -ne 2 ] || [ ! -r "$1" ] || [ ! -r "$2" ]; then
	usage
fi

SECRET="$1"
MANIFEST="$2"

for cmd in ecdsasign ecdsaverify ecdsakeygen; do
	command -v "$cmd" >/dev/null || die "$cmd not found, please install ecdsautils"
done

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT
upper="$tmpdir/upper"
lower="$tmpdir/lower"

if grep -q "$(printf '\r')" "$MANIFEST"; then
	die "$MANIFEST contains Windows line endings (CRLF)"
fi

# Signierten Teil (oberhalb von ---) und Signaturen trennen, wie contrib/sign.sh
awk -v upper="$upper" -v lower="$lower" '
	BEGIN { sep = 0; printf "" > upper; printf "" > lower }
	/^---$/ { sep = 1; next }
	{ if (sep == 0) print > upper; else print > lower }
' "$MANIFEST"

if [ "$ADD" -eq 0 ]; then
	old_serial="$(sed -n 's/^SERIAL=//p' "$upper" | head -n 1)"
	new_serial="$(date +%s)"
	case "$old_serial" in
		''|*[!0-9]*) ;;
		*) [ "$new_serial" -gt "$old_serial" ] || new_serial=$((old_serial + 1)) ;;
	esac

	if grep -q '^SERIAL=' "$upper"; then
		awk -v serial="$new_serial" '
			/^SERIAL=/ && !done { print "SERIAL=" serial; done = 1; next }
			{ print }
		' "$upper" > "$tmpdir/upper.new"
	else
		{ echo "SERIAL=$new_serial"; echo; cat "$upper"; } > "$tmpdir/upper.new"
	fi
	mv "$tmpdir/upper.new" "$upper"

	# Alte Signaturen passen nicht mehr zum geaenderten Inhalt
	: > "$lower"
fi

# Einträge so pruefen, wie der Knoten sie liest
awk -F';' '
	function err(msg) { printf "Error: line %d: %s\n", NR, msg > "/dev/stderr"; failed = 1 }
	function trim(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
	function number(s) { return s ~ /^-?[0-9]+(\.[0-9]+)?$/ }

	/^SERIAL=/ {
		if (serial) err("SERIAL set twice")
		if ($0 !~ /^SERIAL=[0-9]+$/) err("invalid SERIAL")
		serial = 1
		next
	}
	/^[A-Z_]+=/ { next }
	/^[ \t]*(#|$)/ { next }
	{
		entries++
		if (!serial) err("entry before SERIAL")
		if (NF != 5) { err("expected 5 fields (node-id;location_lat;location_lng;location_enabled;target_domain), got " NF); next }

		id = tolower(trim($1)); gsub(/:/, "", id)
		lat = trim($2); lng = trim($3); enabled = trim($4); domain = trim($5)

		if (length(id) != 12 || id !~ /^[0-9a-f]+$/) err("invalid node-id \"" trim($1) "\"")
		else if (id in seen) err("node-id " id " already used in line " seen[id])
		else seen[id] = NR

		if (lat != "" && (!number(lat) || lat + 0 < -90 || lat + 0 > 90)) err("invalid location_lat \"" lat "\"")
		if (lng != "" && (!number(lng) || lng + 0 < -180 || lng + 0 > 180)) err("invalid location_lng \"" lng "\"")
		if (enabled !~ /^(|0|1|true|false)$/) err("invalid location_enabled \"" enabled "\"")
		if (domain !~ /^[A-Za-z0-9_-]*$/) err("invalid target_domain \"" domain "\"")
	}
	END {
		if (!serial) err("SERIAL missing")
		if (failed) exit 1
		printf "%d entries ok\n", entries
	}
' "$upper" || die "validation of $MANIFEST failed, nothing was signed"

size="$(wc -c < "$upper")"
[ "$size" -le "$MAX_SIZE" ] || die "manifest is $size bytes, nodes accept at most $MAX_SIZE bytes"

pubkey="$(ecdsakeygen -p < "$SECRET")"

# ECDSA-Signaturen unterscheiden sich bei jedem Signieren, daher gegen den Public Key pruefen
while read -r sig; do
	if [ -n "$sig" ] && ecdsaverify -s "$sig" -p "$pubkey" "$upper" 2>/dev/null; then
		die "manifest is already signed with this key"
	fi
done < "$lower"

signature="$(ecdsasign "$upper" < "$SECRET")"
ecdsaverify -s "$signature" -p "$pubkey" "$upper" || die "verification of the new signature failed"
echo "$signature" >> "$lower"

# Atomar ersetzen, damit der Webserver nie eine halb geschriebene Datei ausliefert
out="$(dirname "$MANIFEST")/.$(basename "$MANIFEST").tmp.$$"
{
	cat "$upper"
	echo ---
	cat "$lower"
} > "$out"
chmod 644 "$out"
mv "$out" "$MANIFEST"

echo "Signed $MANIFEST with key $pubkey"
echo "SERIAL=$(sed -n 's/^SERIAL=//p' "$upper" | head -n 1), $(wc -l < "$lower" | tr -d ' ') signature(s)"
