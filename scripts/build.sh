usage()
{
    echo -e ""
    echo -e ${txtbld}"Usage:"${txtrst}
    echo -e "  buildsh [options] device"
    echo -e ""
    echo -e ${txtbld}"  Options:"${txtrst}
    echo -e "    -c# Cleanin options before build:"
    echo -e "        1 - make clobber"
    echo -e "        2 - make installclean"
    echo -e "    -j# Set jobs"
    echo -e "    -s  Sync before build"
    echo -e "    -e  Electrify build"
    echo -e ""
    echo -e ${txtbld}"  Example:"${txtrst}
    echo -e "    bash build.sh -c1 -j18 hammerhead"
    echo -e ""
    exit 1
}

# Prepare output customization commands
red=$(tput setaf 1) # red
grn=$(tput setaf 2) # green
blu=$(tput setaf 4) # blue
cya=$(tput setaf 6) # cyan
txtbld=$(tput bold) # Bold
bldred=${txtbld}$(tput setaf 1) # red
bldgrn=${txtbld}$(tput setaf 2) # green
bldblu=${txtbld}$(tput setaf 4) # blue
bldcya=${txtbld}$(tput setaf 6) # cyan
txtrst=$(tput sgr0) # Reset

if [ ! -d ".repo" ]; then
    echo -e ${red}"No .repo directory found.  Is this an Android build tree?"${txtrst}
    exit 1
fi
if [ ! -d "vendor/xenonhd" ]; then
    echo -e ${red}"No vendor/xenonhd directory found.  Is this a Team Horizon build tree?"${txtrst}
    exit 1
fi

# figure out the output directories
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
thisDIR="${PWD##*/}"

findOUT() {
if [ -n "${OUT_DIR_COMMON_BASE+x}" ]; then
return 1; else
return 0
fi;}

findOUT
RES="$?"

if [ $RES = 1 ];then
    export OUTDIR=$OUT_DIR_COMMON_BASE/$thisDIR
    echo -e ""
    echo -e ${cya}"External out DIR is set ($OUTDIR)"${txtrst}
    echo -e ""
elif [ $RES = 0 ];then
    export OUTDIR=$DIR/out
    echo -e ""
    echo -e ${cya}"No external out, using default ($OUTDIR)"${txtrst}
    echo -e ""
else
    echo -e ""
    echo -e ${red}"NULL"${txtrst}
    echo -e ${red}"Error wrong results"${txtrst}
    echo -e ""
fi

# get OS (linux / Mac OS x)
IS_DARWIN=$(uname -a | grep Darwin)
if [ -n "$IS_DARWIN" ]; then
    CPUS=$(sysctl hw.ncpu | awk '{print $2}')
    DATE=gdate
else
    CPUS=$(grep "^processor" /proc/cpuinfo | wc -l)
    DATE=date
fi
export OPT_CPUS=$(bc <<< "($CPUS-1)*2")

export USE_CCACHE=1

opt_clean=0
opt_dex=0
opt_initlogo=0
opt_jobs="$OPT_CPUS"
opt_sync=0
opt_pipe=0
opt_verbose=0

while getopts "c:j:s:e" opt; do
    case "$opt" in
    c) opt_clean="$OPTARG" ;;
    j) opt_jobs="$OPTARG" ;;
    s) opt_sync=1 ;;
    e) electrify=1 ;;
    *) usage
    esac
done
shift $((OPTIND-1))
if [ "$#" -ne 1 ]; then
    usage
fi
device="$1"

echo -e ${cya}"Starting ${ppl}XenonHD..."${txtrst}

if [ "$opt_clean" -eq 1 ]; then
    make clean >/dev/null
    echo -e ""
    echo -e ${bldblu}"Out is clean"${txtrst}
    echo -e ""
elif [ "$opt_clean" -eq 2 ]; then
    make installclean >/dev/null
    echo -e ""
    echo -e ${bldblu}"Out is clean.. kinda?"${txtrst}
    echo -e ""
fi

# sync with latest sources
if [ "$opt_sync" -ne 0 ]; then
    echo -e ""
    echo -e ${bldblu}"Fetching latest sources"${txtrst}
    repo sync -j"$opt_jobs"
    echo -e ""
fi

rm -f $OUTDIR/target/product/$device/obj/KERNEL_OBJ/.version

# get time of startup
t1=$($DATE +%s)

# setup environment
echo -e ${bldblu}"Setting up environment"${txtrst}
. build/envsetup.sh

# Remove system folder (this will create a new build.prop with updated build time and date)
rm -f $OUTDIR/target/product/$device/system/build.prop
rm -f $OUTDIR/target/product/$device/system/app/*.odex
rm -f $OUTDIR/target/product/$device/system/framework/*.odex

echo -e ""
echo -e ${bldblu}"Starting Optimization"${txtrst}

if [ "$electrify" -eq 1 ]; then
    export ELECTRIFY=true >/dev/null
    echo -e ""
    echo -e ${bldblu}"Electrified!"${txtrst}
    echo -e ""
elif
    echo -e ""
    echo -e ${bldred}"WHY WON'T YOU ELECTRIFY?"${txtrst}
    echo -e ""
fi

# lunch device
echo -e ""
echo -e ${bldblu}"Compiling XenonHD ROM"${txtrst}
lunch "xenonhd_$device-user" && make bacon "-j$opt_jobs";


# finished? get elapsed time
t2=$($DATE +%s)

tmin=$(( (t2-t1)/60 ))
tsec=$(( (t2-t1)%60 ))

echo -e ${bldgrn}"Total time elapsed:${txtrst} ${grn}$tmin minutes $tsec seconds"${txtrst}
