# Seite bauen, lokal testen und per SFTP auf IONOS veröffentlichen.
# Zugangsdaten in .deploy.env (Vorlage: .deploy.env.example), Passwort im macOS-Schlüsselbund.

-include .deploy.env

KEYCHAIN_SERVICE ?= sven.bauhan.name-deploy
LFTP_FLAGS       := --reverse --delete --verbose

.PHONY: help build test test-deploy deploy clean keychain-set

help:
	@echo "make build        Seite bauen (output/)"
	@echo "make test         bauen und lokal ausliefern (http://localhost:8820)"
	@echo "make test-deploy  bauen und zeigen, was hochgeladen/gelöscht würde (ändert nichts)"
	@echo "make deploy       bauen und auf den Server hochladen"
	@echo "make keychain-set Passwort im macOS-Schlüsselbund hinterlegen"
	@echo "make clean        output/ löschen"

build: clean
	jbake -b

test: build
	jbake -s

test-deploy: build
	$(call upload,--dry-run)

deploy: build
	$(call upload,)

clean:
	$(RM) -r output

keychain-set:
	@test -n "$(DEPLOY_USER)" || { echo "DEPLOY_USER fehlt in .deploy.env" >&2; exit 1; }
	security add-generic-password -U -a "$(DEPLOY_USER)" -s "$(KEYCHAIN_SERVICE)" -w

# $(1) = zusätzliche lftp-mirror-Optionen
define upload
@test -n "$(DEPLOY_HOST)" -a -n "$(DEPLOY_USER)" -a -n "$(DEPLOY_PATH)" \
  || { echo "DEPLOY_HOST, DEPLOY_USER, DEPLOY_PATH fehlen in .deploy.env" >&2; exit 1; }
@command -v lftp >/dev/null || { echo "lftp fehlt: brew install lftp" >&2; exit 1; }
@PW=$$(security find-generic-password -a "$(DEPLOY_USER)" -s "$(KEYCHAIN_SERVICE)" -w 2>/dev/null); \
if [ -n "$$PW" ]; then \
  export LFTP_PASSWORD="$$PW"; \
  OPEN="open --user '$(DEPLOY_USER)' --env-password 'sftp://$(DEPLOY_HOST)'"; \
else \
  echo "Kein Passwort im Schlüsselbund (make keychain-set), lftp fragt danach."; \
  OPEN="open --user '$(DEPLOY_USER)' 'sftp://$(DEPLOY_HOST)'"; \
fi; \
lftp -e "set sftp:auto-confirm yes; $$OPEN; mirror $(LFTP_FLAGS) $(1) output '$(DEPLOY_PATH)'; bye"
endef
