# Firejail/Sailjail profile for harbour-mygame
# Godot game using GLES/EGL via libhybris — needs access to Android HAL libraries.

# Un-blacklist hybris GPU paths before globals.profile applies its restrictions.
# These are needed by libhybris to load the Qualcomm (or other vendor) GPU driver.
noblacklist /usr/libexec/droid-hybris
noblacklist /system
noblacklist /vendor
noblacklist /odm

include /etc/firejail/harbour-mygame.local
include /etc/firejail/globals.profile
