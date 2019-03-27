#! /bin/bash -v

set -x

#pycbc_config_file=${1}
#pycbc_output_file=${2}

#echo "Using ${pycbc_config_file} as configuration file"
#echo "Writing output to ${pycbc_output_file}"

# data
FRAMES="H1:/home/soumi.de/projects/cbc/inference_for_events/GW150914/losc_data/events/H-H1_LOSC_16_V2-1126257414-4096.gwf"
CHANNELS="H1:LOSC-STRAIN"

# trigger parameters
TRIGGER_TIME=1126259462.42

# data to use
# the longest waveform covered by the prior must fit in these times
SEARCH_BEFORE=6
SEARCH_AFTER=2

# use an extra number of seconds of data in addition to the data specified
PAD_DATA=8

# get coalescence time as an integer
TRIGGER_TIME_INT=${TRIGGER_TIME%.*}

# PSD estimation options
PSD_ESTIMATION="H1:median"
PSD_INVLEN=4
PSD_SEG_LEN=8
PSD_STRIDE=4
PSD_DATA_LEN=1024
PSD_GATE="H1:1126259462.0:2.0:0.5"

# start and end time of data to read in
GPS_START_TIME=$((${TRIGGER_TIME_INT} - ${SEARCH_BEFORE} - ${PSD_INVLEN}))
GPS_END_TIME=$((${TRIGGER_TIME_INT} + ${SEARCH_AFTER} + ${PSD_INVLEN}))
echo $GPS_START_TIME
echo $GPS_END_TIME

# start and end time of data to read in for PSD estimation
PSD_START_TIME=$((${TRIGGER_TIME_INT} - ${PSD_DATA_LEN}/2))
PSD_END_TIME=$((${TRIGGER_TIME_INT} + ${PSD_DATA_LEN}/2))
echo ${PSD_START_TIME}
echo ${PSD_END_TIME}


# sampler parameters
CONFIG_PATH=${1}
OUTPUT_PATH=${2}
IFOS="H1"
SAMPLE_RATE=2048
F_HIGHPASS=15
F_MIN=20
PROCESSING_SCHEME=mkl

# the following sets the number of cores to use; adjust as needed to
# your computer's capabilities
N_PROCS=4

SEED=12

export PYTHON_EGG_CACHE=${PWD}/.cache/${RANDOM}/Python-Eggs

XDG_CACHE_HOME=`pwd`/$(mktemp -p . -d)/xdg-cache
export XDG_CACHE_HOME
mkdir -p ${XDG_CACHE_HOME}/astropy
tar -C ${XDG_CACHE_HOME}/astropy -zxvf astropy.tar.gz &>/dev/null
echo "XDG_CACHE_HOME set to ${XDG_CACHE_HOME} which contains" `ls ${XDG_CACHE_HOME}`

astropy_cache=`python -c 'import astropy; print astropy.config.get_cache_dir()'`
echo "Astropy is using ${astropy_cache} which contains" `ls ${astropy_cache}`

#echo "Using $(( $_CONDOR_NPROCS * $_CONDOR_REQUEST_CPUS )) processors"


pycbc_inference --verbose \
    --seed ${SEED} \
    --instruments ${IFOS} \
    --gps-start-time ${GPS_START_TIME} \
    --gps-end-time ${GPS_END_TIME} \
    --frame-files ${FRAMES} \
    --channel-name ${CHANNELS} \
    --strain-high-pass ${F_HIGHPASS} \
    --pad-data ${PAD_DATA} \
    --psd-estimation ${PSD_ESTIMATION} \
    --psd-segment-length ${PSD_SEG_LEN} \
    --psd-gate ${PSD_GATE} \
    --psd-segment-stride ${PSD_STRIDE} \
    --psd-inverse-length ${PSD_INVLEN} \
    --sample-rate ${SAMPLE_RATE} \
    --low-frequency-cutoff ${F_MIN} \
    --config-file ${CONFIG_PATH} \
    --output-file ${OUTPUT_PATH} \
    --processing-scheme ${PROCESSING_SCHEME} \
    --nprocesses ${N_PROCS} \
    --force

exit_code=${?}
echo "exit code was ${exit_code}"

if [ ${exit_code} -eq 140 ] ; then
kill -USR2 $$
fi

exit ${exit_code}
