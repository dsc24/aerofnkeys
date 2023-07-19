MODULE_NAME = aero_fn_keys
KVER = $(shell uname -r)
MODDESTDIR = /lib/modules/$(KVER)/kernel/drivers/hid/

obj-m += $(MODULE_NAME).o

# ccflags-y := $(ccflags-y) -xc -E -v

all:
	make -C /lib/modules/$(shell uname -r)/build M=$(PWD) modules

clean:
	make -C /lib/modules/$(shell uname -r)/build M=$(PWD) clean

install:
	xz -9 fn_keys_mod.ko
	install -p -m 644 $(MODULE_NAME).ko.xz  $(MODDESTDIR)
	/sbin/depmod -a ${KVER}

uninstall:
	rm -f $(MODDESTDIR)/$(MODULE_NAME).ko.xz
	/sbin/depmod -a ${KVER}
