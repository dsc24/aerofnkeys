MODULE_NAME = aero_fn_keys
KVER = $(shell uname -r)
MODDESTDIR = /lib/modules/$(KVER)/kernel/drivers/hid/
USER = $(shell whoami)
HOSTNAME = $(shell uname -n)
MODULE_VERSION = 1.0
KEY_DIR = /root/aero_keys

obj-m += $(MODULE_NAME).o

# ccflags-y := $(ccflags-y) -xc -E -v

all build:
	@echo Building Modules...
	$(MAKE) -C /lib/modules/$(KVER)/build M=$(PWD) modules
	@# Remove the debugging symbols and shrink this module down:
	@echo Stripping debug symbols...
	@# strip --strip-debug $(MODULE_NAME).ko
	@# Here we sign the module to allow loading in a system with kernel_lockdown enabled (e.g. anything Ubuntu including and beyond 20.04 LTS)
	@# /usr/src/linux-headers-${KVER}/scripts/sign-file sha512 /var/lib/shim-signed/mok/MOK.priv /var/lib/shim-signed/mok/MOK.der $(MODULE_NAME).ko

clean:
	@echo Cleaning Modules...
	$(MAKE) -C /lib/modules/${KVER}/build M=$(PWD) clean

install: build
	@echo Installing Modules...
	@echo Compressing module...
	xz -9 $(MODULE_NAME).ko
	@echo Moving module to $(MODDESTDIR)...
	install -p -m 644 $(MODULE_NAME).ko.xz  $(MODDESTDIR)
	# install -p -m 644 $(MODULE_NAME).ko  $(MODDESTDIR)
	@echo Running depmod...
	/sbin/depmod -a ${KVER}
	@echo Install complete.

uninstall: clean
	@echo Uninstalling Modules...
	@echo Removing module from $(MODDESTDIR)...
	rm -f $(MODDESTDIR)/$(MODULE_NAME).ko.xz
	@echo Running depmod...
	/sbin/depmod -a ${KVER}
	@echo Uninstall complete.

config:
	@echo Configuring openssl...
	@echo "---"
	cp dkms-module-util/openssl.cnf.template openssl.cnf
	sed -i 's/((USER))/$(USER)/g' openssl.cnf
	sed -i 's/((HOSTNAME))/$(HOSTNAME)/g' openssl.cnf
	@echo "---"
	@echo openssl config complete.
	@echo Generating key...
	@echo "---"
	openssl req -x509 -new -nodes -utf8 -sha256 -days 36500 \
	-batch -config openssl.cnf -outform DER -out MOK.der -keyout MOK.priv
	@echo "---"
	@echo Key generation complete.
	@echo Removing generated openssl config...
	rm -f openssl.cnf
	@echo Please run "sudo make root-config" to configure the key and module for DKMS and signing

config-root:
	@echo ---
	@echo Configuring Key directory...
	@echo "---"
	echo "KEY_DIR=$(KEY_DIR)" >> /root/.config/dkms-sign.conf
	@echo "---"
	@echo Moving key to $(KEY_DIR)/...
	@echo ---
	mkdir -p $(KEY_DIR)
	mv MOK.der $(KEY_DIR)/
	mv MOK.priv $(KEY_DIR)/
	@echo ---
	@echo Copying module to /usr/src/$(MODULE_NAME)-$(MODULE_VERSION)...
	@echo ---
	mkdir -p /usr/src/$(MODULE_NAME)-$(MODULE_VERSION)
	cp -r ./* /usr/src/$(MODULE_NAME)-$(MODULE_VERSION)
	@echo ---
	@echo Enrolling key...
	@echo Make sure to remember the password you set for the key!
	@echo ---
	mokutil --import $(KEY_DIR)/MOK.der
	@echo ---
	@echo Enroll complete.
	@echo You will need to reboot to complete enrollment of the MOK key, and you will need your newly set password.

dkms-install:
	@echo Installing module with DKMS and signing...
	sudo dkms add $(MODULE_NAME)/$(MODULE_VERSION)
	dkms install $(MODULE_NAME)/$(MODULE_VERSION)
	@echo Install complete.
	@echo Loading module...
	touch /etc/modules-load.d/$(MODULE_NAME).conf
	echo $(MODULE_NAME) > /etc/modules-load.d/$(MODULE_NAME).conf

dkms-uninstall:
	@echo Uninstalling module with DKMS...
	dkms uninstall $(MODULE_NAME)/$(MODULE_VERSION) 
	dkms remove $(MODULE_NAME)/$(MODULE_VERSION) 
	@echo Uninstall complete.
	@echo Unloading module...
	rm -f /etc/modules-load.d/$(MODULE_NAME).conf

dkms-clean: dkms-uninstall
	@echo Cleaning /usr/src
	rm -rf /usr/src/$(MODULE_NAME)-$(MODULE_VERSION) 
	@echo Cleaning generated keys...
	@sleep 5
	rm -f $(KEY_DIR)/MOK.der
	rm -f $(KEY_DIR)/MOK.priv
	@echo DKMS clean complete.
