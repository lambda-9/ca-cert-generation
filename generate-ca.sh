#!/bin/sh
# Copyright (c) 2020 Benjamin Howell
# SPDX-License-Identifier: MIT

ROOT_CA_CSR_CONF=root-ca-csr.json
SIGNING_CA_CSR_CONF=signing-ca-csr.json
CONFIG=config.json
SIGNING_CONFIG_PROFILE=signing-ca
OUTPUT_DIR=output

print_usage() {
  echo "USAGE:  $0 <csr-dir>"
  echo ""
  echo "<csr-dir>:  directory container CSR JSON config files named:"
  echo "            ${ROOT_CA_CSR_CONF}"
  echo "            ${SIGNING_CA_CSR_CONF}"
  echo ""
  echo "output will be placed in ${OUTPUT_DIR}/"
}

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

if ! command_exists cfssl ; then
  echo >&2 'cfssl is not in PATH'
  exit 1
fi

if ! command_exists openssl ; then
  echo >&2 'openssl is not in PATH'
  exit 1
fi

if [[ "$1" = "" ]]; then
  print_usage
  exit 1
fi

if [[ ! -d "$1" ]]; then
  echo "'$1' is not a directory"
  echo ''
  print_usage
  exit 1
fi

if [[ -r "${OUTPUT_DIR}/root-ca.pem" ]] || [[ -r "${OUTPUT_DIR}/root-ca-key.pem" ]] || \
   [[ -r "${OUTPUT_DIR}/signing-ca.pem" ]] || [[ -r "${OUTPUT_DIR}/signing-ca-key.pem" ]]; then
  echo "WARNING: move files from ${OUTPUT_DIR}/ before running. Files will be overwritten."
  exit 1
fi

if [[ ! -r "${1}/${ROOT_CA_CSR_CONF}" ]] || [[ ! -r "${1}/${SIGNING_CA_CSR_CONF}" ]]; then
  echo "The files '${ROOT_CA_CSR_CONF}' and '${SIGNING_CA_CSR_CONF}' must be present in $1"
  echo ''
  print_usage
  exit 1
fi

cfssl gencert -initca ${1}/${ROOT_CA_CSR_CONF} | cfssljson -bare ${OUTPUT_DIR}/root-ca
cfssl genkey -initca ${1}/${SIGNING_CA_CSR_CONF} | cfssljson -bare ${OUTPUT_DIR}/signing-ca
cfssl sign -ca ${OUTPUT_DIR}/root-ca.pem -ca-key ${OUTPUT_DIR}/root-ca-key.pem \
  --config $CONFIG --profile $SIGNING_CONFIG_PROFILE ${OUTPUT_DIR}/signing-ca.csr \
  | cfssljson -bare ${OUTPUT_DIR}/signing-ca

echo "--\n>> Preparing to encrypt the ROOT CA private key"
openssl ec -aes256 -in ${OUTPUT_DIR}/root-ca-key.pem -out ${OUTPUT_DIR}/root-ca-key-enc.pem
rm -f ${OUTPUT_DIR}/root-ca-key.pem

echo "--\n>> Preparing to encrypt the Signing CA private key"
openssl ec -aes256 -in ${OUTPUT_DIR}/signing-ca-key.pem -out ${OUTPUT_DIR}/signing-ca-key-enc.pem
rm -f ${OUTPUT_DIR}/signing-ca-key.pem

echo "--\n>> Verifying the signing CA was correctly signed by the root CA"
openssl verify -CAfile ${OUTPUT_DIR}/root-ca.pem ${OUTPUT_DIR}/signing-ca.pem
