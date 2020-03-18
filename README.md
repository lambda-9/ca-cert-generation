# ca-cert-generation

## Overview

This repository supports the creation of a private certificate authority (CA).
It generates private root CA and a private signing CA (also known as an
intermediate or subordinate CA). Many corporate environments use private
CAs to support client authentication and internal server trust.

The root CA certificate is distributed to clients as a trust anchor, but
everything else related to the root CA is kept offline in cold storage.

The signing CA key pair (both the public key and private key) must be kept
online in a secured and trusted environment in order to sign client or server
certificates.

## Prerequisites:

- cfssl
- openssl

## Quick start:

1. Edit root-ca-csr.json and signing-ca-csr.json
2. `./generate.sh`

Record the private key passphrases somewhere extremely safe. Store
root-ca-key-enc.pem (the root CA private key) somewhere extremely safe. It
should not be needed for a long time.

The files root-ca.pem and signing-ca.pem are public keys and safe to
expose. root-ca.pem will need to be distributed as a trust anchor. The file
signing-ca-key-enc.pem will be needed to sign x.509 certificates from a safe
and trusted environment.

## FAQ

> Why are both openssl and cfssl required?

cfssl is easier to configure, but doesn't handle symmetric encryption of the
private key. openssl handles the key file encryption.

> Can I get a description of the generated files?

Certificate Signing Requests (CSRs):
- signing-ca.csr
- root-ca.csr

Certificates (public keys):
- signing-ca.pem
- root-ca.pem

Private Keys:
- signing-ca-key-enc.pem
- root-ca-key-enc.pem

> Which files do I need to protect?

Although the private keys are encrypted as best practice with a passphrase,
you should not expose the the private keys. The private keys are:

- signing-ca-key-enc.pem
- root-ca-key-enc.pem

> What do you recommend for storing the private key passphrases?

A secure password management utility such as 1password, KeePass(X),
Hashicorp Vault, or cloud services such as AWS KMS, AWS Secrets Manager, or
Azure KeyVault if appropriately locked down.

> How can I customize for my own needs?

Edit the *.json files. These are standard cfssl files.
