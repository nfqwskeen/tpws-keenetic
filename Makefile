SHELL := /bin/bash
VERSION := $(shell cat VERSION)
ROOT_DIR := /opt

.DEFAULT_GOAL := packages

_clean:
	rm -rf out/$(BUILD_DIR)
	mkdir -p out/$(BUILD_DIR)/control
	mkdir -p out/$(BUILD_DIR)/data

_download_bins: TARGET_URL=$(shell curl -s 'https://api.github.com/repos/bol-van/zapret/releases/latest' | grep 'browser_download_url' | grep 'embedded.tar.gz' | cut -d '"' -f 4)
_download_bins:
	rm -f out/zapret.tar.gz
	rm -rf out/zapret
	mkdir -p out/zapret
	curl -sSL $(TARGET_URL) -o out/zapret.tar.gz
	tar -C out/zapret -xzf "out/zapret.tar.gz"
	cd out/zapret/*/; mv binaries/ ../; cd ..

_conffiles:
	echo "$(ROOT_DIR)/etc/tpws/tpws.conf" > out/$(BUILD_DIR)/control/conffiles
	echo "$(ROOT_DIR)/etc/tpws/user.list" >> out/$(BUILD_DIR)/control/conffiles
	echo "$(ROOT_DIR)/etc/tpws/auto.list" >> out/$(BUILD_DIR)/control/conffiles
	echo "$(ROOT_DIR)/etc/tpws/exclude.list" >> out/$(BUILD_DIR)/control/conffiles

_control:
	echo "Package: tpws-keenetic" > out/$(BUILD_DIR)/control/control
	echo "Version: $(VERSION)" >> out/$(BUILD_DIR)/control/control

	@if [[ "$(BUILD_DIR)" == "openwrt" ]]; then \
		echo "Depends: iptables, iptables-mod-extra, ip6tables, ip6tables-extra" >> out/$(BUILD_DIR)/control/control; \
	else \
		echo "Depends: iptables, busybox" >> out/$(BUILD_DIR)/control/control; \
	fi

	echo "Conflicts: nfqws-keenetic" >> out/$(BUILD_DIR)/control/control
	echo "License: MIT" >> out/$(BUILD_DIR)/control/control
	echo "Section: net" >> out/$(BUILD_DIR)/control/control
	echo "URL: https://github.com/Anonym-tsk/tpws-keenetic" >> out/$(BUILD_DIR)/control/control
	echo "Architecture: $(ARCH)" >> out/$(BUILD_DIR)/control/control
	echo "Description:  TPWS service" >> out/$(BUILD_DIR)/control/control
	echo "" >> out/$(BUILD_DIR)/control/control

_scripts:
	cp common/ipk/common out/$(BUILD_DIR)/control/common
	cp common/ipk/preinst out/$(BUILD_DIR)/control/preinst
	cp common/ipk/postrm out/$(BUILD_DIR)/control/postrm

	@if [[ "$(BUILD_DIR)" == "all" ]]; then \
		cp common/ipk/postinst-multi out/$(BUILD_DIR)/control/postinst; \
	elif [[ "$(BUILD_DIR)" == "openwrt" ]]; then \
	  cp common/ipk/postinst-openwrt out/$(BUILD_DIR)/control/postinst; \
	else \
		cp common/ipk/postinst out/$(BUILD_DIR)/control/postinst; \
	fi

	@if [[ "$(BUILD_DIR)" == "openwrt" ]]; then \
		cp common/ipk/prerm-openwrt out/$(BUILD_DIR)/control/prerm; \
		cp common/ipk/env-openwrt out/$(BUILD_DIR)/control/env; \
	else \
		cp common/ipk/prerm out/$(BUILD_DIR)/control/prerm; \
		cp common/ipk/env out/$(BUILD_DIR)/control/env; \
	fi

_binary:
	mkdir -p out/$(BUILD_DIR)/data$(ROOT_DIR)/usr/bin
	cp out/zapret/binaries/$(BIN)/tpws out/$(BUILD_DIR)/data$(ROOT_DIR)/usr/bin/tpws
	chmod +x out/$(BUILD_DIR)/data$(ROOT_DIR)/usr/bin/tpws

_binary-multi:
	mkdir -p out/$(BUILD_DIR)/data$(ROOT_DIR)/usr/bin
	mkdir -p out/$(BUILD_DIR)/data$(ROOT_DIR)/tmp/tpws_binary

	cp out/zapret/binaries/mips32r1-lsb/tpws out/$(BUILD_DIR)/data$(ROOT_DIR)/tmp/tpws_binary/tpws-mipsel
	cp out/zapret/binaries/mips32r1-msb/tpws out/$(BUILD_DIR)/data$(ROOT_DIR)/tmp/tpws_binary/tpws-mips
	cp out/zapret/binaries/aarch64/tpws out/$(BUILD_DIR)/data$(ROOT_DIR)/tmp/tpws_binary/tpws-aarch64
	cp out/zapret/binaries/arm/tpws out/$(BUILD_DIR)/data$(ROOT_DIR)/tmp/tpws_binary/tpws-armv7
	cp out/zapret/binaries/x86/tpws out/$(BUILD_DIR)/data$(ROOT_DIR)/tmp/tpws_binary/tpws-x86
	cp out/zapret/binaries/x86_64/tpws out/$(BUILD_DIR)/data$(ROOT_DIR)/tmp/tpws_binary/tpws-x86_64

	chmod +x out/$(BUILD_DIR)/data$(ROOT_DIR)/tmp/tpws_binary/tpws-mipsel
	chmod +x out/$(BUILD_DIR)/data$(ROOT_DIR)/tmp/tpws_binary/tpws-mips
	chmod +x out/$(BUILD_DIR)/data$(ROOT_DIR)/tmp/tpws_binary/tpws-aarch64
	chmod +x out/$(BUILD_DIR)/data$(ROOT_DIR)/tmp/tpws_binary/tpws-armv7
	chmod +x out/$(BUILD_DIR)/data$(ROOT_DIR)/tmp/tpws_binary/tpws-x86
	chmod +x out/$(BUILD_DIR)/data$(ROOT_DIR)/tmp/tpws_binary/tpws-x86_64

_startup:
	@if [[ "$(BUILD_DIR)" == "openwrt" ]]; then \
  		cat etc/init.d/openwrt-start etc/init.d/common etc/init.d/openwrt-end > out/$(BUILD_DIR)/data$(ROOT_DIR)/etc/init.d/tpws-keenetic; \
  		chmod +x out/$(BUILD_DIR)/data$(ROOT_DIR)/etc/init.d/tpws-keenetic; \
	else \
	  	cat etc/init.d/entware-start etc/init.d/common etc/init.d/entware-end > out/$(BUILD_DIR)/data$(ROOT_DIR)/etc/init.d/S51tpws; \
	  	chmod +x out/$(BUILD_DIR)/data$(ROOT_DIR)/etc/init.d/S51tpws; \
	fi

_ipk:
	make _clean

	# control.tar.gz
	make _conffiles
	make _control
	make _scripts
	cd out/$(BUILD_DIR)/control; tar czvf ../control.tar.gz .; cd ../../..

	# data.tar.gz
	mkdir -p out/$(BUILD_DIR)/data$(ROOT_DIR)/var/log
	mkdir -p out/$(BUILD_DIR)/data$(ROOT_DIR)/var/run
	mkdir -p out/$(BUILD_DIR)/data$(ROOT_DIR)/etc/init.d


	cp -r etc/tpws out/$(BUILD_DIR)/data$(ROOT_DIR)/etc/tpws
	make _startup

	@if [[ "$(BUILD_DIR)" != "openwrt" ]]; then \
		cp -r etc/ndm out/$(BUILD_DIR)/data$(ROOT_DIR)/etc/ndm; \
	fi

	@if [[ "$(BUILD_DIR)" == "all" ]] || [[ "$(BUILD_DIR)" == "openwrt" ]]; then \
		make _binary-multi; \
	else \
		make _binary; \
	fi

	cd out/$(BUILD_DIR)/data; tar czvf ../data.tar.gz .; cd ../../..

	# ipk
	echo 2.0 > out/$(BUILD_DIR)/debian-binary
	cd out/$(BUILD_DIR); \
	tar czvf ../$(FILENAME) control.tar.gz data.tar.gz debian-binary; \
	cd ../..

mipsel: _download_bins
	@make \
		BUILD_DIR=mipsel \
		ARCH=mipsel-3.4 \
		FILENAME=tpws-keenetic_$(VERSION)_mipsel-3.4.ipk \
		BIN=mips32r1-lsb \
		_ipk

mips: _download_bins
	@make \
		BUILD_DIR=mips \
		ARCH=mips-3.4 \
		FILENAME=tpws-keenetic_$(VERSION)_mips-3.4.ipk \
		BIN=mips32r1-msb \
		_ipk

aarch64: _download_bins
	@make \
		BUILD_DIR=aarch64 \
		ARCH=aarch64-3.10 \
		FILENAME=tpws-keenetic_$(VERSION)_aarch64-3.10.ipk \
		BIN=aarch64 \
		_ipk

multi: _download_bins
	@make \
		BUILD_DIR=all \
		ARCH=all \
		FILENAME=tpws-keenetic_$(VERSION)_all_entware.ipk \
		_ipk

openwrt: _download_bins
	@make \
		BUILD_DIR=openwrt \
		ARCH=all \
		FILENAME=tpws-keenetic_$(VERSION)_all_openwrt.ipk \
		ROOT_DIR= \
		_ipk

packages: mipsel mips aarch64 multi openwrt

_repo-clean:
	rm -rf out/_pages/$(BUILD_DIR)
	mkdir -p out/_pages/$(BUILD_DIR)

_repo-html:
	echo '<html><head><title>tpws-keenetic opkg repository</title></head><body>' > out/_pages/$(BUILD_DIR)/index.html
	echo '<h1>Index of /$(BUILD_DIR)/</h1><hr>' >> out/_pages/$(BUILD_DIR)/index.html
	echo '<pre>' >> out/_pages/$(BUILD_DIR)/index.html
	echo '<a href="../">../</a>' >> out/_pages/$(BUILD_DIR)/index.html
	echo '<a href="Packages">Packages</a>' >> out/_pages/$(BUILD_DIR)/index.html
	echo '<a href="Packages.gz">Packages.gz</a>' >> out/_pages/$(BUILD_DIR)/index.html

	@if [[ "$(BUILD_DIR)" == "openwrt" ]]; then \
  		echo '<a href="Packages.sig">Packages.sig</a>' >> out/_pages/$(BUILD_DIR)/index.html; \
  		echo '<a href="tpws-keenetic.pub">tpws-keenetic.pub</a>' >> out/_pages/$(BUILD_DIR)/index.html; \
  	fi

	echo '<a href="$(FILENAME)">$(FILENAME)</a>' >> out/_pages/$(BUILD_DIR)/index.html
	echo '</pre>' >> out/_pages/$(BUILD_DIR)/index.html
	echo '<hr></body></html>' >> out/_pages/$(BUILD_DIR)/index.html

_repo-index:
	echo '<html><head><title>tpws-keenetic opkg repository</title></head><body>' > out/_pages/index.html
	echo '<h1>Index of /</h1><hr>' >> out/_pages/index.html
	echo '<pre>' >> out/_pages/index.html
	echo '<a href="all/">all/</a>' >> out/_pages/index.html
	echo '<a href="aarch64/">aarch64/</a>' >> out/_pages/index.html
	echo '<a href="mips/">mips/</a>' >> out/_pages/index.html
	echo '<a href="mipsel/">mipsel/</a>' >> out/_pages/index.html
	echo '<a href="openwrt/">openwrt/</a>' >> out/_pages/index.html
	echo '</pre>' >> out/_pages/index.html
	echo '<hr></body></html>' >> out/_pages/index.html

_repository:
	make _repo-clean

	cp "out/$(FILENAME)" "out/_pages/$(BUILD_DIR)/"

	echo "Package: tpws-keenetic" > out/_pages/$(BUILD_DIR)/Packages
	echo "Version: $(VERSION)" >> out/_pages/$(BUILD_DIR)/Packages

	@if [[ "$(BUILD_DIR)" == "openwrt" ]]; then \
		echo "Depends: iptables, iptables-mod-extra, iptables-mod-nfqueue, iptables-mod-filter, iptables-mod-ipopt, iptables-mod-conntrack-extra, ip6tables, ip6tables-mod-nat, ip6tables-extra" >> out/_pages/$(BUILD_DIR)/Packages; \
	else \
		echo "Depends: iptables, busybox" >> out/_pages/$(BUILD_DIR)/Packages; \
	fi

	echo "Conflicts: nfqws-keenetic" >> out/_pages/$(BUILD_DIR)/Packages
	echo "Section: net" >> out/_pages/$(BUILD_DIR)/Packages
	echo "Architecture: $(ARCH)" >> out/_pages/$(BUILD_DIR)/Packages
	echo "Filename: $(FILENAME)" >> out/_pages/$(BUILD_DIR)/Packages
	echo "Size: $(shell wc -c out/$(FILENAME) | awk '{print $$1}')" >> out/_pages/$(BUILD_DIR)/Packages
	echo "SHA256sum: $(shell sha256sum out/$(FILENAME) | awk '{print $$1}')" >> out/_pages/$(BUILD_DIR)/Packages
	echo "Description:  TPWS service" >> out/_pages/$(BUILD_DIR)/Packages
	echo "" >> out/_pages/$(BUILD_DIR)/Packages

	gzip -k out/_pages/$(BUILD_DIR)/Packages

	@make _repo-html

repo-mipsel:
	@make \
		BUILD_DIR=mipsel \
		ARCH=mipsel-3.4 \
		FILENAME=tpws-keenetic_$(VERSION)_mipsel-3.4.ipk \
		_repository

repo-mips:
	@make \
		BUILD_DIR=mips \
		ARCH=mips-3.4 \
		FILENAME=tpws-keenetic_$(VERSION)_mips-3.4.ipk \
		_repository

repo-aarch64:
	@make \
		BUILD_DIR=aarch64 \
		ARCH=aarch64-3.10 \
		FILENAME=tpws-keenetic_$(VERSION)_aarch64-3.10.ipk \
		_repository

repo-multi:
	@make \
		BUILD_DIR=all \
		ARCH=all \
		FILENAME=tpws-keenetic_$(VERSION)_all_entware.ipk \
		_repository

repo-openwrt:
	@make \
		BUILD_DIR=openwrt \
		ARCH=all \
		FILENAME=tpws-keenetic_$(VERSION)_all_openwrt.ipk \
		_repository

repository: repo-mipsel repo-mips repo-aarch64 repo-multi repo-openwrt _repo-index

clean:
	rm -rf out/mipsel
	rm -rf out/mips
	rm -rf out/aarch64
	rm -rf out/all
	rm -rf out/openwrt
	rm -rf out/zapret
	rm -rf out/zapret.tar.gz
