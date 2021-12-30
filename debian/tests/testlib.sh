CERTDIR=/etc/ssl/certs
KEYDIR=/etc/ssl/private
BASENAME=ssl-cert-snakeoil
CERTFILE="$CERTDIR/$BASENAME.pem"
KEYFILE="$KEYDIR/$BASENAME.key"
RC=0

err() {
	echo "ERROR: $*" >&2
	RC=1
}

expect() {
	local want="$1"
	local have="$2"
	local msg="${3:-}"
	[ "$want" = "$have" ] || err "$msg: expected '$want' got '$have'"
}

check_key_perms() {
	local stat=$(stat -c "%U:%G:%a" "$KEYFILE")
	expect "root:ssl-cert:640" "$stat"
}

check_cert_perms() {
	local stat=$(stat -c "%U:%G:%a" "$CERTFILE")
	expect "root:root:644" "$stat"
}

verify_selfsigned() {
	openssl verify -CAfile "$CERTFILE" "$CERTFILE"
}

copy_to_tmp() {
	cp -a "$CERTFILE" "$KEYFILE" "$AUTOPKGTEST_TMP"
}

assert_unchanged() {
	local msg="$1"
	for f in "$CERTFILE" "$KEYFILE" ; do
		cmp -s "$f" "$AUTOPKGTEST_TMP/${f##*/}" || err "$msg: $f has changed"
	done
}

assert_changed() {
	local msg="$1"
	for f in "$CERTFILE" "$KEYFILE" ; do
		! cmp -s "$f" "$AUTOPKGTEST_TMP/${f##*/}" || err "$msg: $f has not changed"
	done
}

look_for_symlink() {
	local tgt
	for i in "$CERTDIR"/[0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f].[0-9] ; do
		[ -L "$i" ] || continue
		tgt=$(readlink $i)
		if [ "$tgt" = "$BASENAME.pem" ] ; then
			echo "$tgt"
			return 0
		fi
	done
	err "Could not find hash symlink in $CERTDIR"
	ls -l "$CERTDIR"
}

do_basic_tests() {
	check_key_perms
	check_cert_perms
	verify_selfsigned
	look_for_symlink
}
