BINDIR=$(DESTDIR)/usr/bin
PERLLIBDIR=$(DESTDIR)/usr/share/perl5
MAN1DIR=$(DESTDIR)/usr/share/man/man1
BASHCOMPLDIR=$(DESTDIR)/usr/share/bash-completion/completions/
ZSHCOMPLDIR=$(DESTDIR)/usr/share/zsh/vendor-completions/

TOOL=pmxtask
VERSION=1.0.0

.PHONY: all
all: build/$(TOOL).1 build/$(TOOL).bash-completion build/$(TOOL).zsh-completion

build/$(TOOL).1: doc/$(TOOL).adoc build/$(TOOL).synopsis.adoc
	asciidoctor -b manpage doc/pmxtask.adoc -D build -a release-version=$(VERSION)

build/$(TOOL).synopsis.adoc: lib/PMX/CLI/$(TOOL).pm
	mkdir -p build
	perl -Ilib -MPMX::CLI::$(TOOL) -e 'print PMX::CLI::$(TOOL)->generate_asciidoc_synopsis()' > build/$(TOOL).synopsis.adoc

build/$(TOOL).bash-completion: lib/PMX/CLI/$(TOOL).pm
	mkdir -p build
	perl -Ilib -MPMX::CLI::$(TOOL) -e 'print PMX::CLI::$(TOOL)->generate_bash_completions()' > build/$(TOOL).bash-completion

build/$(TOOL).zsh-completion: lib/PMX/CLI/$(TOOL).pm
	mkdir -p build
	perl -Ilib -MPMX::CLI::$(TOOL) -e 'print PMX::CLI::$(TOOL)->generate_zsh_completions()' > build/$(TOOL).zsh-completion

.PHONY: install
install: all
	install bin/$(TOOL) $(BINDIR)
	install -D -m655 lib/PMX/CLI/$(TOOL).pm $(PERLLIBDIR)/PMX/CLI/$(TOOL).pm
	install -m655 build/$(TOOL).1 $(MAN1DIR)
	install -m655 build/$(TOOL).bash-completion $(BASHCOMPLDIR)/$(TOOL)
	install -m655 build/$(TOOL).zsh-completion $(ZSHCOMPLDIR)/$(TOOL)

.PHONY: clean
clean:
	rm -r build
	