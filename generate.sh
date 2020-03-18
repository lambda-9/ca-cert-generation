#!/bin/sh
# Copyright (c) 2020 Benjamin Howell
# SPDX-License-Identifier: MIT

ROOT_CA_CSR_CONF=root-ca-csr.json
SIGNING_CA_CSR_CONF=signing-ca-csr.json
CONFIG=config.json
SIGNING_CONFIG_PROFILE=signing-ca

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


cfssl gencert -initca $ROOT_CA_CSR_CONF | cfssljson -bare root-ca
cfssl genkey -initca $SIGNING_CA_CSR_CONF | cfssljson -bare signing-ca
cfssl sign -ca root-ca.pem -ca-key root-ca-key.pem \
  --config $CONFIG --profile $SIGNING_CONFIG_PROFILE signing-ca.csr \
  | cfssljson -bare signing-ca

echo "--\n>> Preparing to encrypt the ROOT CA private key"
openssl ec -aes256 -in root-ca-key.pem -out root-ca-key-enc.pem
rm -f root-ca-key.pem

echo "--\n>> Preparing to encrypt the Signing CA private key"
openssl ec -aes256 -in signing-ca-key.pem -out signing-ca-key-enc.pem
rm -f signing-ca-key.pem

