include Makefile.help
SHELL := /bin/bash
DIRS = certsdb certreqs crl private
CONFIG_FILE = openssl.cnf
DEFAULT_ARGS := -config ./openssl.cnf
CA_KEY_CSR = private/cakey.pem careq.pem
INSECURE_CA_KEY = private/cakey.key-insecure
CA_CRT = cacert.pem
SERVER_FILE = server.key server.csr server.crt
.PHONY: setup ca server
.DEFAULT_GOAL := help

setup: $(DIRS) $(CONFIG_FILE) ##@targets Creates the directory structure and needed files to manage the certificates.

ca: setup $(CA_CRT) ##@targets Creates a new certificate authority.

server: $(SERVER_FILE) ##@targets Creates a new server certificate.

$(DIRS) index.txt:
	mkdir -p $(DIRS)
	chmod 700 private
	touch index.txt

$(CONFIG_FILE):
	find /etc -name "openssl.cnf" -exec cp '{}' . \; &2>/dev/null
	sed -i -r "s/(dir\s*=\s*)(.*)([#.]*)/\1.\3/" openssl.cnf

$(CA_KEY_CSR):
	pwgen 32
	openssl req $(DEFAULT_ARGS) -new -newkey rsa:2048 -keyout private/cakey.pem -out careq.pem
	
$(INSECURE_CA_KEY): $(CA_KEY_CSR)
	openssl rsa -in private/cakey.pem -out private/cakey.key-insecure
	
$(CA_CRT): $(INSECURE_CA_KEY)
	openssl ca $(DEFAULT_ARGS) -create_serial -out cacert.pem -days 3650 -keyfile private/cakey.key-insecure -selfsign -extensions v3_ca_has_san -infiles careq.pem

$(SERVER_FILE):
	openssl req $(DEFAULT_ARGS) -nodes -new -extensions server \
	-keyout certs/server.key -out certs/server.csr
	openssl ca $(DEFAULT_ARGS) -extensions server \
	-out server.crt -in certs/server.csr
