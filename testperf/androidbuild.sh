#!/bin/bash
###############################################################################
#
#
TEST_NAME="OpenH264 Android Performance Test"
###############################################################################

echo "###################################################################"
echo "##Checking parameters"

if [ $# -ne 2 ]; then
	echo "*please use command $0 sim/dev release/debug"
	echo "*sim/dev       - test on simulator or on device"
	echo "*release/debug - debug or release version "
	exit 2
fi

# $1 sim or dev
if [ -n "$1" ]; then
	if [ "sim" == "$1" ]; then
		OPENH264_PERFTEST_ANDROID_PLATFORM="simulator"
	elif [ "dev" == "$1" ]; then
		OPENH264_PERFTEST_ANDROID_PLATFORM="device"
	else
		echo "$1" is unvalid, try sim or dev for simulator or device
		exit 2
	fi
else
	echo "You not set parameter 1, use default:simulator"
	OPENH264_PERFTEST_ANDROID_PLATFORM="simulator"
fi


# $2 debug or release
if [ -n "$2" ]; then
	if [ "release" == "$2" ]; then
		OPENH264_PERFTEST_ANDROID_DEBUG_RELEASE="release"
	elif [ "debug" == "$2" ]; then
		OPENH264_PERFTEST_ANDROID_DEBUG_RELEASE="debug"
	else
		echo "$2" is unvalid, try debug or release
		exit 2
	fi
else
	echo "You not set parameter 2, use default:release"
	OPENH264_PERFTEST_ANDROID_DEBUG_RELEASE="release"
fi

echo "Performance Test will run on ${OPENH264_PERFTEST_ANDROID_PLATFORM} with ${OPENH264_PERFTEST_ANDROID_DEBUG_RELEASE}"
BASE_PATH=$(cd `dirname $0`; pwd)

PLATFORM="android"
###############################################################################
#generate test case

echo "###################################################################"
echo "##Generate test case"

cd ${BASE_PATH}
GENERATECASE_FILE_NAME="GenerateCase.py"
CASE_FILE_NAME="case.cfg"
CASELIST_ENC_FILE_NAME="enc_caselist.cfg"
CASELIST_DEC_FILE_NAME="dec_caselist.cfg"

if [ -f ${CASELIST_ENC_FILE_NAME} ] ; then
	rm ${CASELIST_ENC_FILE_NAME}
fi
if [ -f ${CASELIST_DEC_FILE_NAME} ] ; then
	rm ${CASELIST_DEC_FILE_NAME}
fi

python ${GENERATECASE_FILE_NAME} ${PLATFORM} ${CASE_FILE_NAME} ${CASELIST_ENC_FILE_NAME} ${CASELIST_DEC_FILE_NAME}
if [ ! -f ${CASELIST_ENC_FILE_NAME} ] ; then
	echo "Generate encoder test case failed"
	exit 1
fi
if [ ! -f ${CASELIST_DEC_FILE_NAME} ] ; then
	echo "Generate decoder test case failed"
	exit 1
fi

###############################################################################
#Update code

echo "###################################################################"
echo "##Update code"
if ! which git ; then
	echo "git is not found, please install it"
	exit 1
else
	echo "Find git tool"
fi

git checkout android-test
git pull upstream master

###############################################################################
echo "###################################################################"
echo "##Building libraries and test app"

OPENH264_PERFTEST_ROOT_PATH=${BASE_PATH}/..
OPENH264_PERFTEST_ANDROID_ENC_PROJECT_PATH=${BASE_PATH}/../codec/build/android/encPerfTestApp
OPENH264_PERFTEST_ANDROID_DEC_PROJECT_PATH=${BASE_PATH}/../codec/build/android/decPerfTestApp
OPENH264_PERFTEST_ANDROID_ENC_APP_PATH=${OPENH264_PERFTEST_ANDROID_ENC_PROJECT_PATH}/bin
OPENH264_PERFTEST_ANDROID_DEC_APP_PATH=${OPENH264_PERFTEST_ANDROID_DEC_PROJECT_PATH}/bin
OPENH264_PERFTEST_ANDROID_STD_OUT_ERR=/dev/null

function buildProject()
{
	cd jni
	echo "build welsencdemo lib"
	ndk-build -B
	
	cd ..
	echo "package the app"
	android update project -n $1 -t $2 -p . > ${OPENH264_PERFTEST_ANDROID_STD_OUT_ERR} 2>&1
	$3 debug > ${OPENH264_PERFTEST_ANDROID_STD_OUT_ERR} 2>&1
}

function InstallAndLaunchApp()
{
	echo "Install apk $1 on device"
	adb install -r $1 #> ${OPENH264_PERFTEST_ANDROID_STD_OUT_ERR} 2>&1
	echo "Launching the app $2"
	adb shell am start -n $2/.MainActivity #> ${OPENH264_PERFTEST_ANDROID_STD_OUT_ERR} 2>&1
}

function MountAppDocuments()
{
	RET_VALUE=""
	
	while [[ ${RET_VALUE} != "flag" ]]
	do
		sleep 10
		echo "wait for testing $2"
		RET_VALUE=`adb shell cat $1/$2`
	done
	echo "Test in $2 successfully"

	adb shell ls $1
}

###############################################################################

###############################################################################
cd ${OPENH264_PERFTEST_ROOT_PATH}

ANDROID_TARGET=android-19
ANDROID_PACKAGE_TOOL=ant

if [ ! ${ANDROID_NDK_HOME} ] ; then
	echo "ANDROID_NDK_HOME is not set, please set the environment variable first"
	exit 1
fi
if [ ! ${ANDROID_HOME} ] ; then
	echo "ANDROID_HOME is not set, please set the environment variable first"
	exit 1
fi
if ! which ${ANDROID_PACKAGE_TOOL} ; then
	echo "${ANDROID_PACKAGE_TOOL} is not installed, please install it"
fi
echo "build libraries ..."
make clean > ${OPENH264_PERFTEST_ANDROID_STD_OUT_ERR} 2>&1
make OS=android NDKROOT=${ANDROID_NDK_HOME} TARGET=${ANDROID_TARGET} > ${OPENH264_PERFTEST_ANDROID_STD_OUT_ERR} 2>&1

###############################################################################
cd ${OPENH264_PERFTEST_ANDROID_ENC_PROJECT_PATH}
ENC_PROJECT_NAME=encPerfTestApp

echo "build ${ENC_PROJECT_NAME} and package"
buildProject ${ENC_PROJECT_NAME} ${ANDROID_TARGET} ${ANDROID_PACKAGE_TOOL}

###############################################################################
cd ${OPENH264_PERFTEST_ANDROID_DEC_PROJECT_PATH}
DEC_PROJECT_NAME=decPerfTestApp

echo "build ${DEC_PROJECT_NAME} and package"
buildProject ${DEC_PROJECT_NAME} ${ANDROID_TARGET} ${ANDROID_PACKAGE_TOOL}

###############################################################################
#Detect and prepare test environment

echo "###################################################################"
echo "##Detect test environment"

OPENH264_PERFTEST_ANDROID_CONSOLE="/tmp/wme_encTest.log"
OPENH264_PERFTEST_ANDROID_ENC_APP=${OPENH264_PERFTEST_ANDROID_ENC_APP_PATH}/${ENC_PROJECT_NAME}-debug-unaligned.apk
OPENH264_PERFTEST_ANDROID_DEC_APP=${OPENH264_PERFTEST_ANDROID_DEC_APP_PATH}/${DEC_PROJECT_NAME}-debug-unaligned.apk

OPENH264_PERFTEST_SEQUENCE_PATH="${BASE_PATH}/../../TestVideo"
OPENH264_PERFTET_WORKPATH_ON_DEVICE="/sdcard"
OPENH264_PERFTEST_ENCODER_WORKPATH_ON_DEVICE="/sdcard/encTest"
OPENH264_PERFTEST_DECODER_WORKPATH_ON_DEVICE="/sdcard/decTest"

cd ${BASE_PATH}

if [ ${OPENH264_PERFTEST_ANDROID_PLATFORM} == simulator ]; then
	echo "Install package on simulator and start test"
	exit 1;
	
elif [ ${OPENH264_PERFTEST_ANDROID_PLATFORM} == device ]; then
	# for real device
	echo "Install test sequences and related resources"

	if [ ! `adb shell ls ${OPENH264_PERFTET_WORKPATH_ON_DEVICE} | grep encTest` ] ; then
		echo "make directory ${OPENH264_PERFTEST_ENCODER_WORKPATH_ON_DEVICE}"
		adb shell mkdir ${OPENH264_PERFTEST_ENCODER_WORKPATH_ON_DEVICE}
	fi
	for i in $( ls ${OPENH264_PERFTEST_SEQUENCE_PATH} | grep .yuv )
	do
		if [ ! `adb shell ls ${OPENH264_PERFTEST_ENCODER_WORKPATH_ON_DEVICE} | grep $i` ] ; then
			adb push ${OPENH264_PERFTEST_SEQUENCE_PATH}/$i ${OPENH264_PERFTEST_ENCODER_WORKPATH_ON_DEVICE}
		fi
	done
	adb push ${BASE_PATH}/../testbin/welsenc_android.cfg ${OPENH264_PERFTEST_ENCODER_WORKPATH_ON_DEVICE}
	adb push ${BASE_PATH}/../testbin/layer2.cfg ${OPENH264_PERFTEST_ENCODER_WORKPATH_ON_DEVICE}
	adb push ${BASE_PATH}/${CASELIST_ENC_FILE_NAME} ${OPENH264_PERFTEST_ENCODER_WORKPATH_ON_DEVICE}
	
	if [ ! `adb shell ls ${OPENH264_PERFTET_WORKPATH_ON_DEVICE} | grep decTest` ] ; then
		echo "make directory ${OPENH264_PERFTEST_DECODER_WORKPATH_ON_DEVICE}"
		adb shell mkdir ${OPENH264_PERFTEST_DECODER_WORKPATH_ON_DEVICE}
	fi
	adb push ${BASE_PATH}/${CASELIST_DEC_FILE_NAME} ${OPENH264_PERFTEST_DECODER_WORKPATH_ON_DEVICE}
	
else
	echo "parameters for platform is wrong : ${OPENH264_PERFTEST_ANDROID_PLATFORM}"
fi

###############################################################################
#Run the test and analyze the result

echo "###################################################################"
echo "##Run the test and analyze the result"

cd ${BASE_PATH}

if [ ${OPENH264_PERFTEST_ANDROID_PLATFORM} == simulator ] ; then
	echo "Complete encoder performance test on simulator!"
	exit 1

elif [ ${OPENH264_PERFTEST_ANDROID_PLATFORM} == device ] ; then
	PERF_TEST_ENC_APP_ID="com.wels.encPerfTestApp"
	PERF_TEST_ENC_PATH="enc_result"
	ENC_RESULT_SCRIPT_NAME="ExtractEncTestResult.py"
	ENC_LOG_FILE_NAME="EncPerfTest.log"
	ENC_RESULT_FILE_NAME="EncPerformance.csv"
	END_FLAG_FILE_NAME="enc_progress.log"
	
	echo "Install and launch encoder performance test app"
	adb logcat -c
	adb shell rm ${OPENH264_PERFTEST_ENCODER_WORKPATH_ON_DEVICE}/${ENC_LOG_FILE_NAME}
	InstallAndLaunchApp ${OPENH264_PERFTEST_ANDROID_ENC_APP} ${PERF_TEST_ENC_APP_ID}

	MountAppDocuments ${OPENH264_PERFTEST_ENCODER_WORKPATH_ON_DEVICE} ${END_FLAG_FILE_NAME}
	adb logcat -d -f ${OPENH264_PERFTEST_ENCODER_WORKPATH_ON_DEVICE}/${ENC_LOG_FILE_NAME} -s welsenc
	
	echo "copy 264 bs files to decoder performance test workspace"
	adb shell cp ${OPENH264_PERFTEST_ENCODER_WORKPATH_ON_DEVICE}/*.264 ${OPENH264_PERFTEST_DECODER_WORKPATH_ON_DEVICE}
	
	PERF_TEST_DEC_APP_ID="com.wels.decPerfTestApp"
	PERF_TEST_DEC_PATH="dec_result"
	DEC_RESULT_SCRIPT_NAME="ExtractDecTestResult.py"
	DEC_LOG_FILE_NAME="DecPerfTest.log"
	DEC_RESULT_FILE_NAME="DecPerformance.csv"
	END_FLAG_FILE_NAME="dec_progress.log"
	
	echo "Install and launch decoder performance test app"
	adb logcat -c
	adb shell rm ${OPENH264_PERFTEST_DECODER_WORKPATH_ON_DEVICE}/${ENC_LOG_FILE_NAME}
	InstallAndLaunchApp ${OPENH264_PERFTEST_ANDROID_DEC_APP} ${PERF_TEST_DEC_APP_ID}
	
	MountAppDocuments ${OPENH264_PERFTEST_DECODER_WORKPATH_ON_DEVICE} ${END_FLAG_FILE_NAME}
	adb logcat -d -f ${OPENH264_PERFTEST_DECODER_WORKPATH_ON_DEVICE}/${DEC_LOG_FILE_NAME} -s welsdec

	echo "Start extract result from encoder log"
	if [ -f ${ENC_RESULT_FILE_NAME} ] ; then
		rm ${ENC_RESULT_FILE_NAME}
	fi
	if [ -f ${ENC_LOG_FILE_NAME} ] ; then
		rm ${ENC_LOG_FILE_NAME}
	fi
	adb pull ${OPENH264_PERFTEST_ENCODER_WORKPATH_ON_DEVICE}/${ENC_LOG_FILE_NAME} ${BASE_PATH}
	
	python ${ENC_RESULT_SCRIPT_NAME} ${PLATFORM} ${ENC_LOG_FILE_NAME} ${ENC_RESULT_FILE_NAME}
	if [ ! -f ${ENC_RESULT_FILE_NAME} ] ; then
		echo "Extract result failed"
		exit 1
	fi
	
	echo "Start extract result from decoder log"
	if [ -f ${DEC_RESULT_FILE_NAME} ] ; then
		rm ${DEC_RESULT_FILE_NAME}
	fi
	if [ -f ${DEC_LOG_FILE_NAME} ] ; then
		rm ${DEC_LOG_FILE_NAME}
	fi
	adb pull ${OPENH264_PERFTEST_DECODER_WORKPATH_ON_DEVICE}/${DEC_LOG_FILE_NAME} ${BASE_PATH}

	python ${DEC_RESULT_SCRIPT_NAME} ${PLATFORM} ${DEC_LOG_FILE_NAME} ${DEC_RESULT_FILE_NAME}
	if [ ! -f ${DEC_RESULT_FILE_NAME} ] ; then
		echo "Extract result failed"
		exit 1
	fi

	adb shell rm ${OPENH264_PERFTEST_ENCODER_WORKPATH_ON_DEVICE}/*.264 ${OPENH264_PERFTEST_ENCODER_WORKPATH_ON_DEVICE}/*.log
	adb shell rm ${OPENH264_PERFTEST_DECODER_WORKPATH_ON_DEVICE}/*.yuv ${OPENH264_PERFTEST_DECODER_WORKPATH_ON_DEVICE}/*.264 ${OPENH264_PERFTEST_DECODER_WORKPATH_ON_DEVICE}/*.log

	echo "Complete Extract Test Result"
	
	echo "Start Generate Report"
	GENERATE_REPORT_SCRIPT_NAME="GenerateReport.py"
	REPORT_FILE_NAME="Report.csv"
	
	if [ -f ${REPORT_FILE_NAME} ] ; then
		rm ${REPORT_FILE_NAME}
	fi
	
	python ${GENERATE_REPORT_SCRIPT_NAME} ${ENC_RESULT_FILE_NAME} ${DEC_RESULT_FILE_NAME} ${REPORT_FILE_NAME}
	if [ ! -f ${REPORT_FILE_NAME} ] ; then
		echo "Generate report failed"
		exit 1
	fi
	echo "complete Generate Report"
fi

