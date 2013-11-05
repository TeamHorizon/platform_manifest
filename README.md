	INITIALIZING XenonHD REPOSITORY	
=======================================

For initializing repo use:

    $ repo init -u https://github.com/TeamHorizon/platform_manifest.git -b kitkat

Init core trees without any device/kernel/vendor:

    $ repo init -u https://github.com/TeamHorizon/platform_manifest.git -b kitkat	

Init repo with all devices, kernels and vendors supported by TeamHorizon:

    $ repo init -u https://github.com/TeamHorizon/platform_manifest.git -b kitkat -g all,kernel,device,vendor
or 	

Init repo only for a particular device:

    $ repo init -u https://github.com/TeamHorizon/platform_manifest.git -b kitkat -g all,-notdefault,<devicename>,<vendorname>

for example, to init only trees needed to build i9300:

    $ repo init -u https://github.com/TeamHorizon/platform_manifest.git -b kitkat -g all,-notdefault,i9300,samsung

sync repo:

    $ repo sync -j2 | -j4 |-j8 | -j32 (# of CPUs x2)
