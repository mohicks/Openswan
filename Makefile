# Openswan master makefile
# Copyright (C) 1998-2002  Henry Spencer.
# Copyright (C) 2003-2014  Xelerance Corporation
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 2 of the License, or (at your
# option) any later version.  See <http://www.fsf.org/copyleft/gpl.txt>.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#

OPENSWANSRCDIR?=$(shell pwd)
export OPENSWANSRCDIR

TERMCAP=
export TERMCAP

include ${OPENSWANSRCDIR}/Makefile.inc
-include ${OPENSWANSRCDIR}/Makefile.vendor

srcdir?=$(shell pwd)

all: programs

include ${OPENSWANSRCDIR}/Makefile.top

# directories visited by all recursion

# declaration for make's benefit
.PHONY:	insert patches _patches _patches2.4 \
	programs install clean distclean \
	pcf ocf mcf xcf rcf nopromptgo \
	precheck verset confcheck \
	backup unpatch uninstall install_file_list \
	snapready relready ready buildready devready uml check taroldinstall \
	umluserland



# programs

ifeq ($(strip $(OBJDIR)),.) # If OBJDIR is OPENSWANSRCDIR (ie dot) then the simple case:
programs install clean::
	@for d in $(SUBDIRS) ; \
	do \
		(cd $$d && $(MAKE) srcdir=${OPENSWANSRCDIR}/$$d/ OPENSWANSRCDIR=${OPENSWANSRCDIR} $@ ) || exit 1; \
	done;
else
ABSOBJDIR:=$(shell mkdir -p ${OBJDIR}; cd ${OBJDIR} && pwd)
OBJDIRTOP=${ABSOBJDIR}
export OBJDIRTOP

programs install clean:: ${OBJDIR}/Makefile
	@echo OBJDIR: ${OBJDIR}
	(cd ${ABSOBJDIR} && OBJDIRTOP=${ABSOBJDIR} OBJDIR=${ABSOBJDIR} ${MAKE} $@ )

${OBJDIR}/Makefile: ${srcdir}/Makefile packaging/utils/makeshadowdir
	@echo Setting up for OBJDIR=${OBJDIR}
	@packaging/utils/makeshadowdir `(cd ${srcdir}; echo $$PWD)` ${OBJDIR} "${SUBDIRS}"

endif

checkprograms:: programs
	@for d in $(SUBDIRS) ; \
	do \
		(cd $$d && $(MAKE) srcdir=${OPENSWANSRCDIR}/$$d/ OPENSWANSRCDIR=${OPENSWANSRCDIR} $@ ) || exit 1; \
	done;

checkv199install:
	@if [ "${LIBDIR}" != "${LIBEXECDIR}" ] && [ -f ${LIBDIR}/pluto ]; \
	then \
		echo WARNING: Old version of FreeS/WAN Openswan 1.x installed. ;\
		echo WARNING: moving ${LIBDIR} to ${LIBDIR}.v1 ;\
		mv ${LIBDIR} ${LIBDIR}.v1 ;\
	fi

install:: checkv199install

install::
	mkdir -p ${LIBEXECDIR}
	if [ -n '${VENDOR}' ]; then echo '${VENDOR} ' >${LIBDIR}/vendor.txt; fi


clean::
	rm -rf $(RPMTMPDIR) $(RPMDEST)
	rm -f out.*build out.*install	# but leave out.kpatch

# proxies for major kernel make operations

# do-everything entries
KINSERT_PRE=verset insert
PRE=verset
POST=confcheck programs install
MPOST=confcheck programs install

Makefile: Makefile.ver

# at the moment there is no difference between snapshot and release build
snapready:	buildready
relready:	buildready
ready:		devready

# set up for build
buildready:
	rm -f dtrmakefile cvs.datemark
	# obsolete cd doc ; $(MAKE) -s

rpm:
	@echo To build an rpm, use: rpmbuild -ba packaging/XXX/openswan.spec
	@echo where XXX is your rpm based vendor
	rpmbuild -bs packaging/centos5/bluerose.spec

ipkg_strip:
	@echo "Minimizing size for ipkg binaries..."
	@cd $(DESTDIR)$(INC_USRLOCAL)/lib/ipsec && \
	for f in *; do (if file $$f | grep ARM > /dev/null; then ( $(STRIP) --strip-unneeded $$f); fi); done
	@rm -r $(DESTDIR)$(INC_USRLOCAL)/man
	@rm -f $(DESTDIR)$(INC_RCDEFAULT)/*.old
	@rm -f $(DESTDIR)$(INC_USRLOCAL)/lib/ipsec/*.old
	@rm -f $(DESTDIR)$(INC_USRLOCAL)/libexec/ipsec/*.old
	@rm -f $(DESTDIR)$(INC_USRLOCAL)/sbin/*.old
	@rm -f $(DESTDIR)$(INC_USRLOCAL)/share/doc/openswan/*


ipkg_clean:
	rm -rf $(OPENSWANSRCDIR)/packaging/ipkg/kernel-module/
	rm -rf $(OPENSWANSRCDIR)/packaging/ipkg/ipkg/
	rm -f $(OPENSWANSRCDIR)/packaging/ipkg/control-openswan
	rm -f $(OPENSWANSRCDIR)/packaging/ipkg/control-openswan-module


ipkg: programs install ipkg_strip
	@echo "Generating ipkg...";
	DESTDIR=${DESTDIR} OPENSWANSRCDIR=${OPENSWANSRCDIR} ARCH=${ARCH} IPSECVERSION=${IPSECVERSION} ./packaging/ipkg/generate-ipkg

tarpkg:
	@echo "Generating tar.gz package to install"
	@rm -rf /var/tmp/openswan-${USER}
	@make DESTDIR=/var/tmp/openswan-${USER} programs install
	@rm /var/tmp/openswan-${USER}/etc/ipsec.conf
	@(cd /var/tmp/openswan-${USER} && tar czf - . ) >openswan${VENDOR}-${IPSECVERSION}.tgz
	@ls -l openswan${VENDOR}-${IPSECVERSION}.tgz
	@rm -rf /var/tmp/openswan-${USER}


env:
	@env | sed -e "s/'/'\\\\''/g" -e "s/\([^=]*\)=\(.*\)/\1='\2'/"

#
#  A target that does nothing intesting is sometimes interesting...
war:
	@echo "Not Love?"


