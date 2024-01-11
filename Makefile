BINDIR=$(DESTDIR)/usr/bin
PERLLIBDIR=$(DESTDIR)/usr/share/perl5
MAN1DIR=$(DESTDIR)/usr/share/man/man1
BASHCOMPLDIR=$(DESTDIR)/usr/share/bash-completion/completions/
ZSHCOMPLDIR=$(DESTDIR)/usr/share/zsh/vendor-completions/

TOOL=pmxtask
VERSION=1.0.0

all: $(TOOL).1 $(TOOL).bash-completion $(TOOL).zsh-completion

$(TOOL).1: doc/$(TOOL).adoc $(TOOL).synopsis.adoc
	asciidoctor -b manpage doc/pmxtask.adoc -D . -a release-version=$(VERSION)

$(TOOL).synopsis.adoc: lib/PMX/CLI/$(TOOL).pm
	perl -Ilib -MPMX::CLI::$(TOOL) -e 'print PMX::CLI::$(TOOL)->generate_asciidoc_synopsis()' > $(TOOL).synopsis.adoc

$(TOOL).bash-completion: lib/PMX/CLI/$(TOOL).pm
	perl -Ilib -MPMX::CLI::$(TOOL) -e 'print PMX::CLI::$(TOOL)->generate_bash_completions()' > $(TOOL).bash-completion

$(TOOL).zsh-completion: lib/PMX/CLI/$(TOOL).pm
	perl -Ilib -MPMX::CLI::$(TOOL) -e 'print PMX::CLI::$(TOOL)->generate_zsh_completions()' > $(TOOL).zsh-completion

.PHONY: install
install: all
	install bin/$(TOOL) $(BINDIR)
	install -D -m655 lib/PMX/CLI/$(TOOL).pm $(PERLLIBDIR)/PMX/CLI/$(TOOL).pm
	install -m655 $(TOOL).1 $(MAN1DIR)
	install -m655 $(TOOL).bash-completion $(BASHCOMPLDIR)/$(TOOL)
	install -m655 $(TOOL).zsh-completion $(ZSHCOMPLDIR)/$(TOOL)

.PHONY: clean
clean:
	rm $(TOOL).zsh-completion $(TOOL).bash-completion $(TOOL).synopsis.adoc $(TOOL).1
	