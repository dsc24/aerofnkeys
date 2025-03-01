# aerofnkeys
Custom HID Quirks Driver that fixes function keys not working in the Gigabyte Aero 15 SB/D Series and the 16 XE5 laptops.

Works by intercepting non-HID compliant usages raw and emulating the correct keycode presses because Gigabyte decided to be different.

## Notes

- ~~Compatible with the Chu Yuen Keyboard for the Gigabyte Aero 15 SB (Vendor ID: ID 1044, Product ID: 7A3B) and the Aero 15 D series (Chu Yuen 1044:7A3D).~~
- Brightness up/down is standard across aero models, seemingly. This may mean all keys are the same across all models. However, the additional keys added here have not been tested on any device other than the Chu Yuen 1044:7a3a keyboard from the Gigabyte Aero 16 XE5 currently.
- To check compatibility run `lsusb`, find your keyboard and compare the Vendor and Product IDs with the ones above. Or go experiment.
- To capture HID data from the device, one can use
  
  ``` sudo usbhid-dump --model=1044:7a3a --interface=2 --stream-feedback --entity=stream --stream-timeout=5000 ```
  
  While changing "7a3a" for your particular Product ID (or removing it entirely and risk a slight bit of noise from the trackpad)

  One can also remove --interface=2 if there are difficulties capturing data. It should limit capture to just the "FN + Key" HID data*, but the wrong number would prevent capture of any data.

~~- At the moment I've managed to get only the brightness keys to work on my system *(Fedora 34; Kernel 5.13.12; Gnome 40.4)*. I am investigating why the wifi and touchpad toggle keys are not working.~~
- At the moment, keys confirmed to work with the correct functions are:
  - *(Fedora 34; Kernel 5.13.12; Gnome 40.4)*
    - Brightness Up/Down (**F3/F4**), Volume Mute/Down/Up (**F7/F8/F9**)
  - *(EndeavourOS; Kernel 6.4.3; Plasma 5.27.6 + KWin)*
    - Sleep (**F1**), Brightness Up/Down (**F3/F4**), Display Mode (**F5**), Screen Lock (**F6**), Volume Mute/Down/Up (**F7/F8/F9**), Airplane Mode/RFKILL (**F11**) and Keyboard Backlight (**Space**)
      
- (Function + ) Keys that have do not work as intended but have been rebound to a different function are:
  - **ESC**/Fan Control
    - F13
  - **F2**/Wifi
    - F14
  - **F12**/Aero AI Mode
    - F24
      
- Sleep (**F1**), Display Mode (**F5**), Volume Mute/Down/Up changes(**F7/F8/F9**), and RFKILL/Airplane Mode (**F11**) are all working by default, and would require a different method to rebind.

- Wifi (**F2**) is correctly recognized, but the key I attempt to bind it to (KEY_WWAN) does not seem to work for me. I am unsure why and since RFKILL (**F11**) does work, I am not overly concerned with figuring this out.

- **F10** is special (and not working). It sends data over multiple interfaces. All other FN + Key combinations send data only over interface 002, but from what I can see F10 sends over 002 and 000 (the normal key interface for keys like 's' or '['). This data includes both malformed and correct data, over both interfaces. It also causes data to be sent on key release. Currently I have not figured out how to make this work in any way.

- Make sure you have the kernel headers installed for the kernel version your PC is running. To see if already installed on Arch/Manjaro run `pacman -Q linux-headers`.

_*See notes on F10/Touchpad Toggle_


# How to Install

## Recommended DKMS Method (with signing)
1. `git clone https://github.com/dsc24/aerofnkeys.git`
2. `cd aerofnkeys`
3. `make`
4. `make config`
5. `sudo make config-root`
6. `sudo make dkms-install`
7. Reboot & test out your function keys. Enjoy!


## Manual method (no signing)
1. `git clone https://github.com/dsc24/aerofnkeys.git`
2. `cd aerofnkeys`
3. `make`
4. `make install`
5. `sudo modprobe aero_fn_keys`
- You will have to repeat the 5th command after every reboot, and you will have to run the last 3 every time your kernel version changes.

# Troubleshooting


Inspect the module by running `modinfo` or `file` about the specific kernel's build of aerofnkeys.


If you get an error message when running `modprobe aero_fn_keys` which says something along the lines of "exec format error", try clearing out the DKMS built module by running:
1. `dkms remove aerofnkeys/1.0 -k $(uname -r)`
2. `dkms install aerofnkeys/1.0 -k $(uname -r)`
3. `modprobe -v aero_fn_keys`


If you have done everything as instructed and seen no errors, yet it still will not work, you can try applying a usbhid.quirks setting.
This is done by changing your boot parameters. This will differ depending on which bootloader you are using.

For systemd:
- Find your boot partition/directory. This is usually /boot or /efi (for some dual boot systems). In my case it is /efi, and the rest of the directory structure should be the same.
1. `cd /efi/loader/entries`
- Now choose which entry file to modify. In most cases you will have something like `6.4.3-arch1-2-fallback.conf` alongside `6.4.3-arch1-2.conf`.
- You will want to modify the one that does not mention "fallback" or "backup" or anything like that. In the future if you fail to boot after changing something, the fallback entry will allow you to boot and fix the issue.
2. Open the desired .conf file and locate the line that begins with `options`
3. Add `usbhid.quirks=0x1044:0x7a3a:0x0000` at beginning/end of the line, make sure to replace `0x7a3a` with your particular Product ID
- This should then look something like 

`options   usbhid.quirks=0x1044:0x7a3a:0x0000 ...(the rest of your default parameters)`
- What this does is ensure the keyboard is not grabbed by the incorrect generic driver which does not support the function keys. If something were to go wrong, you may be left without use of your laptop keyboard (until this line is removed). In this case, a seperate USB keyboard/mouse should continue to work.
