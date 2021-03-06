#!/bin/bash
#
# This script backs up FreeLCS configuration and creates a restoration script.
# The backup can be restored to any computer running Ubuntu and no X is required.
#

if [ "$UID" != "0" ] ; then
	echo
	echo "This script must be run as root"
	echo
	exit
fi

REAL_USER_NAME=`logname 2> /dev/null`

if [ "$REAL_USER_NAME" == ""  ] ; then
        REAL_USER_NAME="$1"
fi

if [ "$REAL_USER_NAME" == ""  ] ; then
        echo
        echo "ERROR: Can not find out your login username."
	echo "Please give your login name as the first argument for the script."
	echo
	echo "Example: 00-backup_freelcs_configuration.sh   john"
	echo
	echo "The username is used to make the copied configuration files"
	echo "readable and writable to this user."
        echo
        exit
fi

echo
#### "123456789 123456789 123456789 123456789 123456789 123456789 123456789 123456789 "
echo "This program will make a backup of your current FreeLCS installation,"
echo "that can be restored to any computer running Ubuntu."
echo "The restoration program is a shell script that doesn't require a graphical"
echo "GUI so restoration can be automated or done through a ssh - connection."
echo
echo "The reason this backup / restoration functionality exists is to make"
echo "cloning FreeLCS installation to several machines quick and painless :)"
echo
echo "A directory will be created to the current dir and backup files copied to it."
echo
echo "Press ctrl + c now to cancel ...."
echo
read -p "or the [Enter] key to start making the backup ..."
echo

# Create dir for backup files.
BACKUP_DIR_NAME="freelcs_backup"

mkdir -p "$BACKUP_DIR_NAME"

if [ ! -e "$BACKUP_DIR_NAME" ] ; then
	echo
	echo "ERROR: Can not create directory for backup files."
	echo
	exit
fi

cd "$BACKUP_DIR_NAME"

# Define paths to files to back up.
INIT_SCRIPT_PATH="/etc/init.d/loudnesscorrection_init_script"
LOUDNESSCORRECTION_PATH="/usr/bin/LoudnessCorrection.py"
HEARTBEAT_CHECKER_PATH="/usr/bin/HeartBeat_Checker.py"
SETTINGS_FILE_PATH="/etc/Loudness_Correction_Settings.pickle"
SAMBA_CONF_PATH="/etc/samba/smb.conf"

# Check if user has Samba installed
SAMBA_PATH=`which smbd`

# Check that all files we wan't to copy exist.
if [ ! -e "$INIT_SCRIPT_PATH" ] ; then
        echo
        echo "ERROR: Can not find FreeLCS file: "$INIT_SCRIPT_PATH", can not continue."
        echo
        exit
fi

if [ ! -e "$LOUDNESSCORRECTION_PATH" ] ; then
        echo
        echo "ERROR: Can not find FreeLCS file: "$LOUDNESSCORRECTION_PATH", can not continue."
        echo
        exit
fi

if [ ! -e "$HEARTBEAT_CHECKER_PATH" ] ; then
        echo
        echo "ERROR: Can not find FreeLCS file: "$HEARTBEAT_CHECKER_PATH", can not continue."
        echo
        exit
fi

if [ ! -e "$SETTINGS_FILE_PATH" ] ; then
        echo
        echo "ERROR: Can not find FreeLCS file: "$SETTINGS_FILE_PATH", can not continue."
        echo
        exit
fi

# Only search for samba conf - file if Samba is installed.
if [ "$SAMBA_PATH" != "" ] ; then

	if [ ! -e "$SAMBA_CONF_PATH" ] ; then
		echo
		echo "ERROR: Can not find FreeLCS file: "$SAMBA_CONF_PATH", can not continue."
		echo
		exit
	fi
fi

# Copy FreeLCS files to backup dir.

echo
echo "Copying installed FreeLCS files to backup dir ..."
echo "--------------------------------------------------"
echo

cp $INIT_SCRIPT_PATH .

if [ "$?" -ne "0"  ] ; then
	echo
	echo "Error, could not copy: "$INIT_SCRIPT_PATH
	echo
	exit
fi

cp $LOUDNESSCORRECTION_PATH .

if [ "$?" -ne "0"  ] ; then
	echo
	echo "Error, could not copy: "$LOUDNESSCORRECTION_PATH
	echo
	exit
fi

cp $HEARTBEAT_CHECKER_PATH .

if [ "$?" -ne "0"  ] ; then
	echo
	echo "Error, could not copy: "$HEARTBEAT_CHECKER_PATH
	echo
	exit
fi

cp $SETTINGS_FILE_PATH .

if [ "$?" -ne "0"  ] ; then
	echo
	echo "Error, could not copy: "$SETTINGS_FILE_PATH
	echo
	exit
fi

# Only copy samba conf - file if Samba is installed.
if [ "$SAMBA_PATH" != "" ] ; then

	cp $SAMBA_CONF_PATH .

	if [ "$?" -ne "0"  ] ; then
		echo
		echo "Error, could not copy: "$SAMBA_CONF_PATH
		echo
		exit
	fi
fi

echo "Writing restoration script to backup dir ..."
echo "---------------------------------------------"
echo

cat > "00-restore_freelcs_configuration.sh" << 'END_OF_FILE'
#!/bin/bash

if [ "$UID" != "0" ] ; then
	echo
	echo "This script must be run as root"
	echo
	exit
fi

# Define names for files we are about to copy back to system.
INIT_SCRIPT_NAME="loudnesscorrection_init_script"
LOUDNESSCORRECTION_NAME="LoudnessCorrection.py"
HEARTBEAT_CHECKER_NAME="HeartBeat_Checker.py"
SETTINGS_FILE_NAME="Loudness_Correction_Settings.pickle"
SAMBA_CONF_NAME="smb.conf"

# Define paths for copy targets.
INIT_SCRIPT_PATH="/etc/init.d/loudnesscorrection_init_script"
INIT_SCRIPT_LINK_PATH="/etc/rc2.d/S99loudnesscorrection_init_script"
LOUDNESSCORRECTION_PATH="/usr/bin/LoudnessCorrection.py"
HEARTBEAT_CHECKER_PATH="/usr/bin/HeartBeat_Checker.py"
SETTINGS_FILE_PATH="/etc/Loudness_Correction_Settings.pickle"
SAMBA_CONF_PATH="/etc/samba/smb.conf"

# Check that all files we wan't to copy exist.
if [ ! -e "$INIT_SCRIPT_NAME" ] ; then
        echo
        echo "ERROR: Can not find FreeLCS file: "$INIT_SCRIPT_NAME", can not continue."
        echo
        exit
fi

if [ ! -e "$LOUDNESSCORRECTION_NAME" ] ; then
        echo
        echo "ERROR: Can not find FreeLCS file: "$LOUDNESSCORRECTION_NAME", can not continue."
        echo
        exit
fi

if [ ! -e "$HEARTBEAT_CHECKER_NAME" ] ; then
        echo
        echo "ERROR: Can not find FreeLCS file: "$HEARTBEAT_CHECKER_NAME", can not continue."
        echo
        exit
fi

if [ ! -e "$SETTINGS_FILE_NAME" ] ; then
        echo
        echo "ERROR: Can not find FreeLCS file: "$SETTINGS_FILE_NAME", can not continue."
        echo
        exit
fi

SAMBA_INSTALLATION_COMMAND=""

# Check if Samba samba configuration must be restored.
if [ -e "$SAMBA_CONF_NAME" ] ; then
	SAMBA_INSTALLATION_COMMAND="samba"
fi

##############################################################################
# If temporary installation directories still exist in /tmp then delete them #
##############################################################################

if [ -e "/tmp/libebur128" ] ; then

	rm -rf "/tmp/libebur128"

	if [ "$?" -ne "0"  ] ; then
		echo
		echo "Error, could not delete temporary dir /tmp/libebur128"
		echo
		exit
	fi
fi

if [ -e "/tmp/libebur128_fork_for_freelcs_2.4" ] ; then

	rm -rf "/tmp/libebur128_fork_for_freelcs_2.4"

	if [ "$?" -ne "0"  ] ; then
		echo
		echo "Error, could not delete temporary dir /tmp/libebur128_fork_for_freelcs_2.4"
		echo
		exit
	fi
fi

if [ -e "/tmp/sox_personal_fork" ] ; then

	rm -rf "/tmp/sox_personal_fork"
	
	if [ "$?" -ne "0"  ] ; then
		echo
		echo "Error, could not delete temporary dir /tmp/sox_personal_fork"
		echo
		exit
	fi
fi

echo
echo "##############################"
echo "# Installing FreeLCS scripts #"
echo "##############################"
echo

cp -f "$INIT_SCRIPT_NAME" "$INIT_SCRIPT_PATH"

if [ "$?" -ne "0"  ] ; then
	echo
	echo "Error, could not create: "$INIT_SCRIPT_PATH
	echo
	exit
fi

chown root:root "$INIT_SCRIPT_PATH"
chmod  755 "$INIT_SCRIPT_PATH"


cp -f "$LOUDNESSCORRECTION_NAME" "$LOUDNESSCORRECTION_PATH"

if [ "$?" -ne "0"  ] ; then
	echo
	echo "Error, could not create: "$LOUDNESSCORRECTION_PATH
	echo
	exit
fi

chown root:root "$LOUDNESSCORRECTION_PATH"
chmod  755 "$LOUDNESSCORRECTION_PATH"


cp -f "$HEARTBEAT_CHECKER_NAME" "$HEARTBEAT_CHECKER_PATH"

if [ "$?" -ne "0"  ] ; then
	echo
	echo "Error, could not create: "$HEARTBEAT_CHECKER_PATH
	echo
	exit
fi

chown root:root "$HEARTBEAT_CHECKER_PATH"
chmod  755 "$HEARTBEAT_CHECKER_PATH"


cp -f "$SETTINGS_FILE_NAME" "$SETTINGS_FILE_PATH"

if [ "$?" -ne "0"  ] ; then
	echo
	echo "Error, could not create: "$SETTINGS_FILE_PATH
	echo
	exit
fi

chown root:root "$SETTINGS_FILE_PATH"
chmod  644 "$SETTINGS_FILE_PATH"


if [ -e "$SAMBA_CONF_NAME" ] ; then

	mkdir -p /etc/samba
	cp -f "$SAMBA_CONF_NAME" "$SAMBA_CONF_PATH"

	if [ "$?" -ne "0"  ] ; then
		echo
		echo "Error, could not create: "$SAMBA_CONF_PATH
		echo
		exit
	fi

	chown root:root "$SAMBA_CONF_PATH"
	chmod  644 "$SAMBA_CONF_PATH"
fi

ln -s -f "$INIT_SCRIPT_PATH" "$INIT_SCRIPT_LINK_PATH"

if [ "$?" -ne "0"  ] ; then
	echo
	echo "Error, could not create: "$INIT_SCRIPT_LINK_PATH
	echo
	exit
fi

# Add here all additional packages that you want apt-get to install. Separate names with a space. Example:   ADDITIONAL_PACKAGE_INSTALLATION_COMMANDS="ffmpeg audacity vlc".
# ADDITIONAL_PACKAGE_INSTALLATION_COMMANDS="ffmpeg" 

echo
echo "#############################################"
echo "# Installing required packages with apt-get #"
echo "#############################################"
echo

# If sox is installed as a apt - package, then remove it, because we are going to install it from source.
apt-get remove -y sox

apt-get -q=2 -y --reinstall install python3 idle3 automake autoconf libtool gnuplot mediainfo build-essential git cmake libsndfile-dev libmpg123-dev libmpcdec-dev libglib2.0-dev libfreetype6-dev librsvg2-dev libspeexdsp-dev libavcodec-dev libavformat-dev libtag1-dev libxml2-dev libgstreamer0.10-dev libgstreamer-plugins-base0.10-dev libqt4-dev $SAMBA_INSTALLATION_COMMAND $ADDITIONAL_PACKAGE_INSTALLATION_COMMANDS 

if [ "$?" -ne "0"  ] ; then
	echo
	echo "Error installing packages with apt-get, can not continue."
	echo
	exit
fi

echo
echo "##########################"
echo "# Downloading libebur128 #"
echo "##########################"
echo

cd /tmp
git clone http://github.com/mhartzel/libebur128_fork_for_freelcs_2.4.git
mv libebur128_fork_for_freelcs_2.4 libebur128
cd libebur128

# Get the git commit number of current version of libebur128
echo
LIBEBUR128_REQUIRED_GIT_COMMIT_VERSION="18d1b743b27b810ebf04e012c34105a71c1620b1"
LIBEBUR128_CURRENT_COMMIT=`git rev-parse HEAD`

# If libebur128 commit number does not match, check out the correct version from git
if [ "$LIBEBUR128_CURRENT_COMMIT" == "$LIBEBUR128_REQUIRED_GIT_COMMIT_VERSION" ] ; then
	echo "libebur128 already at the required version $LIBEBUR128_REQUIRED_GIT_COMMIT_VERSION"
else
	echo "Checking out required version of libebur128 from git project"
	echo
	git checkout --force $LIBEBUR128_REQUIRED_GIT_COMMIT_VERSION
	
	# Check that we have the correct version after checkout
	LIBEBUR128_CURRENT_COMMIT=`git rev-parse HEAD`
	if [ "$LIBEBUR128_CURRENT_COMMIT" == "$LIBEBUR128_REQUIRED_GIT_COMMIT_VERSION" ] ; then
		echo "Checkout was successful"
		echo
	else
		echo "There was an error when trying to check out the correct libebur128 version from the local git repository !!!!!!!"
		echo
		exit
	fi
fi

echo
echo "########################################################################################################"
echo "# Writing libebur128 4.0 and 5.0 - channel patch to a separate file for patching the libebur128 source #"
echo "########################################################################################################"
echo

FULL_PATH_TO_SELF="/tmp/libebur128_download_commands.sh"
FULL_PATH_TO_PATCH="/tmp/libebur128/libebur128_scanner_4.0_and_5.0_channel_mapping_hack.diff"

cat > "$FULL_PATH_TO_PATCH" << 'END_OF_PATCH'
diff --git a/ebur128/ebur128.c b/ebur128/ebur128.c
index 320a6b5..f194d83 100644
--- a/ebur128/ebur128.c
+++ b/ebur128/ebur128.c
@@ -166,6 +166,17 @@ static int ebur128_init_channel_map(ebur128_state* st) {
       default: st->d->channel_map[i] = EBUR128_UNUSED;         break;
     }
   }
+  
+  if (st->channels == 4) {
+	st->d->channel_map[2] = EBUR128_LEFT_SURROUND;
+	st->d->channel_map[3] = EBUR128_RIGHT_SURROUND;
+	}
+
+  if (st->channels == 5) {
+	st->d->channel_map[3] = EBUR128_LEFT_SURROUND;
+	st->d->channel_map[4] = EBUR128_RIGHT_SURROUND;
+	}
+
   return EBUR128_SUCCESS;
 }
 
diff --git a/scanner/inputaudio/ffmpeg/input_ffmpeg.c b/scanner/inputaudio/ffmpeg/input_ffmpeg.c
index f41d0c9..f3600f8 100644
--- a/scanner/inputaudio/ffmpeg/input_ffmpeg.c
+++ b/scanner/inputaudio/ffmpeg/input_ffmpeg.c
@@ -177,6 +177,7 @@ close_file:
 }
 
 static int ffmpeg_set_channel_map(struct input_handle* ih, int* st) {
+  return 1;
   if (ih->codec_context->channel_layout) {
     unsigned int channel_map_index = 0;
     int bit_counter = 0;
diff --git a/scanner/inputaudio/gstreamer/input_gstreamer.c b/scanner/inputaudio/gstreamer/input_gstreamer.c
index 6f28822..9f3663e 100644
--- a/scanner/inputaudio/gstreamer/input_gstreamer.c
+++ b/scanner/inputaudio/gstreamer/input_gstreamer.c
@@ -256,6 +256,7 @@ static int gstreamer_open_file(struct input_handle* ih, const char* filename) {
 }

 static int gstreamer_set_channel_map(struct input_handle* ih, int* st) {
+  return 0;
   gint j;
   for (j = 0; j < ih->n_channels; ++j) {
     switch (ih->channel_positions[j]) {
diff --git a/scanner/inputaudio/sndfile/input_sndfile.c b/scanner/inputaudio/sndfile/input_sndfile.c
index aee098b..79e0f04 100644
--- a/scanner/inputaudio/sndfile/input_sndfile.c
+++ b/scanner/inputaudio/sndfile/input_sndfile.c
@@ -60,6 +60,7 @@ static int sndfile_open_file(struct input_handle* ih, const char* filename) {
 }

 static int sndfile_set_channel_map(struct input_handle* ih, int* st) {
+  return 1;
   int result;
   int* channel_map = (int*) calloc((size_t) ih->file_info.channels, sizeof(int));
   if (!channel_map) return 1;
diff --git a/scanner/scanner.c b/scanner/scanner.c
index d952f80..fdceff0 100644
--- a/scanner/scanner.c
+++ b/scanner/scanner.c
@@ -90,6 +90,9 @@ static void print_help(void) {
     printf("  -m, --momentary=INTERVAL   print momentary loudness every INTERVAL seconds\n");
     printf("  -s, --shortterm=INTERVAL   print shortterm loudness every INTERVAL seconds\n");
     printf("  -i, --integrated=INTERVAL  print integrated loudness every INTERVAL seconds\n");
+    printf("\n");
+    printf("  Patched to support 4.0 (L, R, LS, RS) and 5.0 (L, R, C, LS, RS) files.\n");
+    printf("\n");
 }
 
 static gboolean recursive = FALSE;

END_OF_PATCH


echo
echo "########################################################################"
echo "# Applying libebur128 4.0 and 5.0 - channel patch to libebur128 source #"
echo "########################################################################"
echo

OUTPUT_FROM_PATCHING=`git apply --whitespace=nowarn "$FULL_PATH_TO_PATCH" 2>&1`

# Check if applying patch produced an error

case "$OUTPUT_FROM_PATCHING" in
	*error*) echo "There was an error when applying patch to libebur128 !!!!!!!"  ; exit ;;
	*cannot*) echo "There was an error when applying patch to libebur128 !!!!!!!"  ; exit ;;
	*fatal*) echo "There was an error when applying patch to libebur128 !!!!!!!"  ; exit ;;
	*) echo "libebur128 patched successfully :)" ;;
esac
echo

echo
echo "###############################################"
echo "# Preparing libebur128 source for compilation #"
echo "###############################################"
echo

cd /tmp/libebur128
mkdir build
cd build
cmake -Wno-dev -DCMAKE_INSTALL_PREFIX:PATH=/usr ..

echo
echo "#######################################"
echo "# Compiling and installing libebur128 #"
echo "#######################################"
echo

cd /tmp/libebur128/build
make -s -j 4
make install

echo
echo "#############################################"
echo "# Downloading, compiling and installing sox #"
echo "#############################################"
echo

# Download sox source
cd /tmp

git clone http://github.com/mhartzel/sox_personal_fork.git

cd sox_personal_fork

echo
echo "Checking out required version of sox from git project"
echo

SOX_REQUIRED_GIT_COMMIT_VERSION="6dff9411961cc8686aa75337a78b7df334606820"
git checkout --force $SOX_REQUIRED_GIT_COMMIT_VERSION

# Check that we have the correct version after checkout
SOX_CURRENT_COMMIT=`git rev-parse HEAD`

if [ "$SOX_CURRENT_COMMIT" == "$SOX_REQUIRED_GIT_COMMIT_VERSION" ] ; then
	echo
        echo "Checkout was successful"
        echo
else
        echo "There was an error when trying to check out the correct sox version from the local git repository !!!!!!!"
        echo
        exit
fi

# Build and install sox from source
autoreconf -i
./configure --prefix=/usr
make -s -j 4
make install

echo
echo "############"
echo "# Ready :) #"
echo "############"
echo
echo "Reboot the computer to start FreeLCS or give the following command:"
echo
echo "sudo -b /etc/init.d/loudnesscorrection_init_script restart"
echo

END_OF_FILE


chmod 755 "00-restore_freelcs_configuration.sh"

if [ "$?" -ne "0"  ] ; then
	echo
	echo "Error making 'restore_freelcs_configuration' script executable."
	echo
	exit
fi

cd - > /dev/null

# Make backed up files readable and writable by the normal user running this script with sudo.
chown -R $REAL_USER_NAME:$REAL_USER_NAME "freelcs_backup"

echo
echo "############"
echo "# Ready :) #"
echo "############"
echo
echo "FreeLCS configuration has been saved to directory 'freelcs_backup'."
echo
echo "Please note that the restoration script '00-restore_freelcs_configuration.sh'"
echo "will not ask for confirmation but starts restoration right away when you start the script."
echo
echo "NOTE !!!!!!! It is very important that you restore FreeLCS onto the same Linux distro"
echo "and version that it was originally installed on. There are some differences between"
echo "Linux versions and FreeLCS adjusts the installation according to these differences."
echo "FreeLCS might not work correctly if restored onto a wrong distro or version."
echo

exit

