
INSTALL := install
bindir := /usr/bin
mandir := /usr/share/man/man1

.PHONY: all install

all:

install:
	$(INSTALL) -p vm vm-*.sh -t $(DESTDIR)$(bindir)
	$(INSTALL) -p vm.1 -t $(DESTDIR)$(mandir)
	$(GZIP) $(DESTDIR)$(mandir)/vm.1
