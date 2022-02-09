#!/bin/bash

# COPIED/MODIFIED from the redis server gen-certs util
# https://github.com/redis/redis/blob/cc0091f0f9fe321948c544911b3ea71837cf86e3/utils/gen-test-certs.sh

# Generate some test certificates which are used by the regression test suite:
#
#   ${dirOut}/ca.{crt,key}          Self signed Certification Authority certificate.
#   ${dirOut}/redis.{crt,key}       A certificate with no key usage/policy restrictions.
#   ${dirOut}/client.{crt,key}      A certificate restricted for SSL client usage.
#   ${dirOut}/server.{crt,key}      A certificate restricted for SSL server usage.
#   ${dirOut}/redis.dh              Diffie-Hellman Params file.

# Generate X509V3 extensions file
gen_x509v3_extfile() {
	local dirOut="${1}"
	local fqdn="${2:-"example.com"}"

	local fileCfg="${dirOut}/openssl.cnf"

	echo "generating openssl config file in ${fileCfg}"

	cat > "${fileCfg}" <<CNF_EOL
	[ server_cert ]
	keyUsage = digitalSignature, keyEncipherment
	nsCertType = server

	[ client_cert ]
	keyUsage = digitalSignature, keyEncipherment
	nsCertType = client

	[ generic_cert ]
	subjectAltName = DNS:${fqdn}
CNF_EOL
}

# Certification Authority certificate
gen_ca() {
	local dirOut="${1}"
	local crtOrg="${2:-"Redis Test"}"
	local crtCommonName="${3:-"Certificate Authority"}"
	local fqdn="${4:-"example.com"}"

	local fpCAPK="${dirOut}/ca.key"
	local fpCACSR="${dirOut}/ca.crt"

	echo "generating ca certificate files in ${fpCAPK} & ${fpCACSR}"

	[ -f "${fpCAPK}" ] || openssl genrsa -out "${fpCAPK}" 4096
	openssl req \
		-x509 -new -nodes -sha256 \
		-key "${fpCAPK}" \
		-days 3650 \
		-subj "/O=${crtOrg}/CN=${crtCommonName}" \
		-addext "subjectAltName = DNS:${fqdn}" \
		-out "${fpCACSR}"
}

# Secure Sockets Layer certificate
gen_ssl() {
	local dirOut="${1}"
	local stem="${2}"
	local crtOrg="${3:-"Redis Test"}"
	local crtCommonName="${4:-"Certificate Authority"}"
	local x509Options=("${@:5}")

	local fpSSLPK="${dirOut}/${stem}.key"
	local fpSSLCSR="${dirOut}/${stem}.crt"
	local fpCAPK="${dirOut}/ca.key"
	local fpCACSR="${dirOut}/ca.crt"
	local fpCASerial="${dirOut}/ca.txt"

	echo "generating ${stem} ssl certificate files in ${fpSSLPK} & ${fpSSLCSR}"

	[ -f "${fpSSLPK}" ] || openssl genrsa -out "${fpSSLPK}" 2048
	openssl req \
		-new -sha256 \
		-subj "/O=${crtOrg}/CN=${crtCommonName}" \
		-key "${fpSSLPK}" | \
		openssl x509 \
			-req -sha256 \
			-CA "${fpCACSR}" \
			-CAkey "${fpCAPK}" \
			-CAserial "${fpCASerial}" \
			-CAcreateserial \
			-days 365 \
			-out "${fpSSLCSR}" \
			"${x509Options[@]}"
}

# Diffie-Hellman Parameters
gen_dhparams() {
	local dirOut="${1}"

	local fileDH="${dirOut}/redis.dh"

	echo "generating diffie-hellman parameters file in ${fileDH}"

	[ -f "${fileDH}" ] || openssl dhparam -out "${fileDH}" 2048
}

main() {
	# local dirRoot
	local dirOut
	local fqdn
	local crtOrg

	# dirRoot="$(realpath "$(dirname "${0}")/..")"
	dirOut="$(realpath "${1:-$(pwd)}")"
	fqdn="${2:-"fdb.agn"}"
	crtOrg="AgnostiCity Redis"

	mkdir -p "${dirOut}"

	gen_ca "${dirOut}" "${crtOrg}" "Certificate Authority" "${fqdn}"
	gen_x509v3_extfile "${dirOut}" "${fqdn}"
	gen_ssl "${dirOut}" server "${crtOrg}" "Server-only" -extfile "${dirOut}/openssl.cnf" -extensions server_cert
	gen_ssl "${dirOut}" client "${crtOrg}" "Client-only" -extfile "${dirOut}/openssl.cnf" -extensions client_cert
	gen_ssl "${dirOut}" redis "${crtOrg}" "Generic-cert" -extfile "${dirOut}/openssl.cnf" -extensions generic_cert
	gen_dhparams "${dirOut}"
}

main "$@"
