#include <linux/module.h>
#include <linux/input.h>
#include <linux/hid.h>
#include "hid-ids.h"

#define SEND_KEY(c) send_key(((report->field)[0])->hidinput->input, (c));

static void send_key(struct input_dev *inputd, unsigned int keycode)
{ 
	// emulate keyboard single key press and release.
	input_report_key(inputd, keycode, 1);
	input_sync(inputd);
	input_report_key(inputd, keycode, 0);
	input_sync(inputd);
}

static int gigabyte_raw_event(struct hid_device *hdev,
	struct hid_report *report, u8 *data, int size)
{
	// printk(KERN_ALERT "Gigabyte: %x %x %x %x %x %x %x\n", report->id, size, data[0], data[1], data[2], data[3]);

	if (unlikely(report->id == 4 && size == 4))
	{
		// if report comes from vendor usage page
		switch (data[3])
		{
		/*
		 * All FN-keys (except vol_up, vol_down, vol_mute, projector key, and sleep key) send only key presses and no key releases.
		 * We simulate an instaneous key press and release at the cost of the ability to handle long-press of a key.
		 */
		/**
		 * esc :RW: rebind, working as f13
		 * f1  :NRW: no rebind, working as sleep
		 * f2  :RW: rebind, working as f14
		 * f3  :RW: rebind, working as brightness down
		 * f4  :RW: rebind, working as brightness up
		 * f5  :NRW: no rebind, working as projector key
		 * f6  :RW: rebind, working as screen lock
		 * f7  :NRW: no rebind, working as vol_mute
		 * f8  :NRW: no rebind, working as vol_down
		 * f9  :NRW: no rebind, working as vol_up
		 * f10 :NRNW: no rebind, not working (mangled key spam)
		 * f11 :NRW: no rebind, working as rfkill
		 * f12 :RW: rebind, working as f24
		 */
		case 0x7c:
			SEND_KEY(KEY_F14);
			break;
		case 0x7d:
			SEND_KEY(KEY_BRIGHTNESSDOWN);
			break;
		case 0x7e:
			SEND_KEY(KEY_BRIGHTNESSUP);
			break;
		case 0x80:
			SEND_KEY(KEY_SCREENLOCK);
			break;
		case 0x88:
			SEND_KEY(KEY_F24);
			break;
		case 0x84:
			SEND_KEY(KEY_F13);
			break;
			// case 0x81:
			// 	SEND_KEY(KEY_TOUCHPAD_TOGGLE);
			// 	break;
		}
	}
	// else if (unlikely(report->id == 7 && size == 2))
	// {
	// 	switch (data[1])
	// 	{
	// 	case 0x02:
	// 		SEND_KEY(KEY_SLEEP);
	// 		break;
	// 	case 0x01:
	// 		SEND_KEY(KEY_RFKILL);
	// 		break;
	// 	}
	// } else if (unlikely(report->id == 0 && size == 24)) {
	// 	switch(data[2]) {
	// 		case 0x13: //f5
	// 			SEND_KEY(KEY_D); //NOT WORKING
	// 			break;
	// 	}
	// }

	return 0;
}

static const struct hid_device_id gigabyte_devices[] = {
	// binding to HID_GROUP_GENERIC to let hid-multitouch.c handle the touchpad and trackpoint.
	{.bus = BUS_USB, .group = HID_GROUP_GENERIC, .vendor = USB_VENDOR_ID_CHUYEN, .product = USB_DEVICE_ID_CHUYEN_16_XE5},
	{.bus=BUS_USB, .group=HID_GROUP_GENERIC, .vendor=USB_VENDOR_ID_CHUYEN, .product=USB_DEVICE_ID_CHUYEN_7A3B},
	{.bus=BUS_USB, .group=HID_GROUP_GENERIC, .vendor=USB_VENDOR_ID_CHUYEN, .product=USB_DEVICE_ID_CHUYEN_7A3F}
};
// Array of Structs ; hid_device_id is a struct as well.

static struct hid_driver gigabyte_hid_driver = {
	.name = "gigabyte",
	.id_table = gigabyte_devices,
	.raw_event = gigabyte_raw_event,

};

module_hid_driver(gigabyte_hid_driver);

MODULE_AUTHOR("Github: Original code by jaytohe, with modifications/additional code by atomspring and dsch24");
MODULE_DESCRIPTION("Bare-bones support for certain Gigabyte Aero 15/16/17 model fn-keys");
MODULE_LICENSE("GPL");
