#!/bin/bash
###############################################################################
#
#
TEST_NAME="OpenH264 iOS Performance Test"
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
		OPENH264_PERFTEST_IOS_PLATFORM="iphonesimulator"
	elif [ "dev" == "$1" ]; then
		OPENH264_PERFTEST_IOS_PLATFORM="iphoneos"
	else
		echo "$1" is unvalid, try sim or dev for simulator or device
		exit 2
	fi
else
	echo "You not set parameter 1, use default:iphonesimulator"
	OPENH264_PERFTEST_IOS_PLATFORM="iphonesimulator"
fi


# $2 debug or release
if [ -n "$2" ]; then
	if [ "release" == "$2" ]; then
		OPENH264_PERFTEST_IOS_DEBUG_RELEASE="Release"
	elif [ "debug" == "$2" ]; then
		OPENH264_PERFTEST_IOS_DEBUG_RELEASE="Debug"
	else
		echo "$2" is unvalid, try debug or release
		exit 2
	fi
else
	echo "You not set parameter 2, use default:release"
	OPENH264_PERFTEST_IOS_DEBUG_RELEASE="Release"
fi

echo "Performance Test will run on ${OPENH264_PERFTEST_IOS_PLATFORM} with ${OPENH264_PERFTEST_IOS_DEBUG_RELEASE}"
BASE_PATH=$(cd `dirname $0`; pwd)

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

python ${GENERATECASE_FILE_NAME} ${CASE_FILE_NAME} ${CASELIST_ENC_FILE_NAME} ${CASELIST_DEC_FILE_NAME}
if [ ! -f ${CASELIST_ENC_FILE_NAME} ] ; then
	echo "Generate encoder test case failed"
	exit 1
fi
if [ ! -f ${CASELIST_DEC_FILE_NAME} ] ; then
	echo "Generate decoder test case failed"
	exit 1
fi


###############################################################################
echo "###################################################################"
echo "##Building libcommon, libprocessing, libwelsenc, libwelsdec and test app"

OPENH264_PERFTEST_IOS_COMMON_PATH=${BASE_PATH}/../codec/build/iOS/common
OPENH264_PERFTEST_IOS_PROCESSING_PATH=${BASE_PATH}/../codec/processing/build/iOS
OPENH264_PERFTEST_IOS_ENCODER_PATH=${BASE_PATH}/../codec/build/iOS/enc/welsenc
OPENH264_PERFTEST_IOS_DECODER_PATH=${BASE_PATH}/../codec/build/iOS/dec/welsdec
OPENH264_PERFTEST_IOS_ENC_PROJECT_PATH=${BASE_PATH}/../codec/build/iOS/enc/encPerfTestApp
OPENH264_PERFTEST_IOS_DEC_PROJECT_PATH=${BASE_PATH}/../codec/build/iOS/dec/decPerfTestApp
OPENH264_PERFTEST_IOS_ENC_APP_PATH=${OPENH264_PERFTEST_IOS_ENC_PROJECT_PATH}/build
OPENH264_PERFTEST_IOS_DEC_APP_PATH=${OPENH264_PERFTEST_IOS_DEC_PROJECT_PATH}/build
OPENH264_PERFTEST_IOS_STD_OUT_ERR=/dev/null

function buildProject()
{
	xcodebuild -project $1.xcodeproj -target $2 -configuration $3 -sdk $4 clean build > ${OPENH264_PERFTEST_IOS_STD_OUT_ERR} 2>&1
	if [ $? == 0 ]; then
		echo "build $1 $3 $4 successfully"
		return 0;
	else
		echo "build $1 $3 $4 fail"
		return 1;
	fi
}

function InstallAndLaunchApp()
{
	echo "Begin to launching $TEST_NAME"

	touch /tmp/test.js

	GREP_RESULT=`system_profiler SPUSBDataType | sed -n -e '/iPad/,/Serial/p' -e '/iPhone/,/Serial/p' | grep "Serial Number:" | awk -F ": " '{print $2}'`

	for DEVICE_ID in ${GREP_RESULT}
	do
		echo "Try to run on device:${DEVICE_ID}"

		$1 -b $2 -i ${DEVICE_ID} > $3 2>&1

		instruments -w ${DEVICE_ID}  -t /Applications/Xcode.app/Contents/Applications/Instruments.app/Contents/PlugIns/AutomationInstrument.bundle/Contents/Resources/Automation.tracetemplate $2 -e UIASCRIPT /tmp/test.js -e UIARRESULTPATH /tmp/ > $3 2>&1

	done
}

function MountAppDocuments()
{
if [ ! -d $3 ] ; then
		mkdir $3
	fi

	echo "$1 --documents $2 $3"
	$1 --documents $2 $3
	
	while [ ! -f "$3/$4" ] 
	do
		sleep 5
		echo "wait for mounting and testing"
	done
	echo "mount $2 successfully"

	ls $3
}

###############################################################################

###############################################################################
cd ${OPENH264_PERFTEST_IOS_COMMON_PATH}

PROJECT_FILE_NAME="common"
TARGET_NAME=${PROJECT_FILE_NAME}

buildProject ${PROJECT_FILE_NAME} ${TARGET_NAME} ${OPENH264_PERFTEST_IOS_DEBUG_RELEASE} ${OPENH264_PERFTEST_IOS_PLATFORM}
if [ $? != 0 ]; then
	echo "Build ${PROJECT_FILE_NAME} failed, exit now"
	exit 1
fi

###############################################################################
cd ${OPENH264_PERFTEST_IOS_PROCESSING_PATH}

PROJECT_FILE_NAME="processing"
TARGET_NAME=${PROJECT_FILE_NAME}

buildProject ${PROJECT_FILE_NAME} ${TARGET_NAME} ${OPENH264_PERFTEST_IOS_DEBUG_RELEASE} ${OPENH264_PERFTEST_IOS_PLATFORM}
if [ $? != 0 ]; then
	echo "Build ${PROJECT_FILE_NAME} failed, exit now"
	exit 1
fi

###############################################################################
cd ${OPENH264_PERFTEST_IOS_ENCODER_PATH}

PROJECT_FILE_NAME="welsenc"
TARGET_NAME=${PROJECT_FILE_NAME}

buildProject ${PROJECT_FILE_NAME} ${TARGET_NAME} ${OPENH264_PERFTEST_IOS_DEBUG_RELEASE} ${OPENH264_PERFTEST_IOS_PLATFORM}
if [ $? != 0 ]; then
	echo "Build ${PROJECT_FILE_NAME} failed, exit now"
	exit 1
fi

###############################################################################
cd ${OPENH264_PERFTEST_IOS_DECODER_PATH}

PROJECT_FILE_NAME="welsdec"
TARGET_NAME=${PROJECT_FILE_NAME}

buildProject ${PROJECT_FILE_NAME} ${TARGET_NAME} ${OPENH264_PERFTEST_IOS_DEBUG_RELEASE} ${OPENH264_PERFTEST_IOS_PLATFORM}
if [ $? != 0 ]; then
	echo "Build ${PROJECT_FILE_NAME} failed, exit now"
	exit 1
fi

###############################################################################
cd ${OPENH264_PERFTEST_IOS_ENC_PROJECT_PATH}
PROJECT_FILE_NAME="encPerfTestApp"
TARGET_NAME=${PROJECT_FILE_NAME}

buildProject ${PROJECT_FILE_NAME} ${TARGET_NAME} ${OPENH264_PERFTEST_IOS_DEBUG_RELEASE} ${OPENH264_PERFTEST_IOS_PLATFORM}
if [ $? != 0 ]; then
	echo "Build ${PROJECT_FILE_NAME} failed, exit now"
	exit 1
fi

###############################################################################
cd ${OPENH264_PERFTEST_IOS_DEC_PROJECT_PATH}
PROJECT_FILE_NAME="decPerfTestApp"
TARGET_NAME=${PROJECT_FILE_NAME}

buildProject ${PROJECT_FILE_NAME} ${TARGET_NAME} ${OPENH264_PERFTEST_IOS_DEBUG_RELEASE} ${OPENH264_PERFTEST_IOS_PLATFORM}
if [ $? != 0 ]; then
	echo "Build ${PROJECT_FILE_NAME} failed, exit now"
	exit 1
fi


###############################################################################
#Detect test environment

echo "###################################################################"
echo "##Detect test environment"

OPENH264_PERFTEST_IOS_CONSOLE="/tmp/wme_encTest.log"
OPENH264_PERFTEST_IOS_ENC_APP_FOR_SIMULATOR=${OPENH264_PERFTEST_IOS_ENC_APP_PATH}/${OPENH264_PERFTEST_IOS_DEBUG_RELEASE}-iphonesimulator/encPerfTestApp.app
OPENH264_PERFTEST_IOS_ENC_APP_FOR_DEVICE=${OPENH264_PERFTEST_IOS_ENC_APP_PATH}/${OPENH264_PERFTEST_IOS_DEBUG_RELEASE}-iphoneos/encPerfTestApp.app
OPENH264_PERFTEST_IOS_DEC_APP_FOR_SIMULATOR=${OPENH264_PERFTEST_IOS_DEC_APP_PATH}/${OPENH264_PERFTEST_IOS_DEBUG_RELEASE}-iphonesimulator/decPerfTestApp.app
OPENH264_PERFTEST_IOS_DEC_APP_FOR_DEVICE=${OPENH264_PERFTEST_IOS_DEC_APP_PATH}/${OPENH264_PERFTEST_IOS_DEBUG_RELEASE}-iphoneos/decPerfTestApp.app

OPENH264_PERFTEST_IOS_TOOL_LAUNCH_ON_SIMULATOR="ios-sim"
OPENH264_PERFTEST_IOS_TOOL_INSTALL_ON_DEVICE="./fruitstrap"

OPENH264_PERFTEST_SEQUENCE_PATH=${BASE_PATH}/../res

cd ${BASE_PATH}

if [ ${OPENH264_PERFTEST_IOS_PLATFORM} == iphonesimulator ]; then

	echo "Checking tool and app"
	if ! which ${OPENH264_PERFTEST_IOS_TOOL_LAUNCH_ON_SIMULATOR} ; then
		echo "${OPENH264_PERFTEST_IOS_TOOL_LAUNCH_ON_SIMULATOR} is not found, please install it"
		exit 1
	else
		echo "Find ${OPENH264_PERFTEST_IOS_TOOL_LAUNCH_ON_SIMULATOR} tool"
	fi

	if [ ! -d ${OPENH264_PERFTEST_IOS_APP_FOR_SIMULATOR} ] ; then
		echo "${OPENH264_PERFTEST_IOS_APP_FOR_SIMULATOR} is not found"
		exit 1
	else
		echo "Find App ${OPENH264_PERFTEST_IOS_APP_FOR_SIMULATOR}"
		echo "cp ${OPENH264_PERFTEST_SEQUENCE_PATH}/*.yuv ${OPENH264_PERFTEST_IOS_APP_FOR_SIMULATOR}"
		cp ${OPENH264_PERFTEST_SEQUENCE_PATH}/*.yuv ${OPENH264_PERFTEST_IOS_ENC_APP_FOR_SIMULATOR}
	fi

	echo "Cleaning old test app"
	pkill -9 'iPhone Simulator'
	rm -rf /tmp/wme_encTest.log

	echo "Begin to launching $TEST_NAME"

	${OPENH264_PERFTEST_IOS_TOOL_LAUNCH_ON_SIMULATOR} launch ${OPENH264_PERFTEST_IOS_ENC_APP_FOR_SIMULATOR}  --exit --stderr ${OPENH264_PERFTEST_IOS_CONSOLE} --stdout ${OPENH264_PERFTEST_IOS_CONSOLE} > ${OPENH264_PERFTEST_IOS_STD_OUT_ERR} 2>&1

elif [ ${OPENH264_PERFTEST_IOS_PLATFORM} == iphoneos ]; then
	# for real device
	if [ ! -f ${OPENH264_PERFTEST_IOS_TOOL_INSTALL_ON_DEVICE} ] ; then
		echo "${OPENH264_PERFTEST_IOS_TOOL_INSTALL_ON_DEVICE} is not found, please make sure the file exists"
		exit 1
	else
		echo "Find ${OPENH264_PERFTEST_IOS_TOOL_INSTALL_ON_DEVICE}"
	fi

	if [ ! -d ${OPENH264_PERFTEST_IOS_ENC_APP_FOR_DEVICE} ] ; then
		echo "${OPENH264_PERFTEST_IOS_ENC_APP_FOR_DEVICE} is not found"
		exit 1
	else
		echo "Find app ${OPENH264_PERFTEST_IOS_ENC_APP_FOR_DEVICE}"
		cp ${OPENH264_PERFTEST_SEQUENCE_PATH}/*.yuv ${OPENH264_PERFTEST_IOS_ENC_APP_FOR_DEVICE}
	fi
else
	echo "parameters for platform is wrong : ${OPENH264_PERFTEST_IOS_PLATFORM}"
fi

###############################################################################
#Run the test and analyze the result

echo "###################################################################"
echo "##Run the test and analyze the result"

cd ${BASE_PATH}

if [ ${OPENH264_PERFTEST_IOS_PLATFORM} == iphonesimulator ] ; then
	echo "Complete encoder performance test on simulator!"
	exit 1

elif [ ${OPENH264_PERFTEST_IOS_PLATFORM} == iphoneos ] ; then
	echo "Install and launch encoder performance test app"
	InstallAndLaunchApp ${OPENH264_PERFTEST_IOS_TOOL_INSTALL_ON_DEVICE} ${OPENH264_PERFTEST_IOS_ENC_APP_FOR_DEVICE} ${OPENH264_PERFTEST_IOS_STD_OUT_ERR}

	echo "mount device"
	OPENH264_PERFTEST_IOS_TOOL_MOUNT_DEVICE="ifuse"
	if ! which ${OPENH264_PERFTEST_IOS_TOOL_MOUNT_DEVICE} ; then
		echo "${OPENH264_PERFTEST_IOS_TOOL_MOUNT_DEVICE} is not found, please install ifuse"
		exit 1
	else
		echo "Find ${OPENH264_PERFTEST_IOS_TOOL_MOUNT_DEVICE}"
	fi

	PERF_TEST_ENC_APP_ID="cisco.encPerfTestApp"
	PERF_TEST_ENC_PATH="enc_result"
	EXTRACTRESULT_FILE_NAME="ExtractTestResult.py"
	ENC_LOG_FILE_NAME="EncPerfTest.log"
	ENC_RESULT_FILE_NAME="EncPerformance.csv"
	MountAppDocuments ${OPENH264_PERFTEST_IOS_TOOL_MOUNT_DEVICE} ${PERF_TEST_ENC_APP_ID} ${PERF_TEST_ENC_PATH} ${ENC_LOG_FILE_NAME}
	
	echo "copy 264 bs files to decoder performance test workspace"
	cp ${PERF_TEST_ENC_PATH}/*.264 ${OPENH264_PERFTEST_IOS_DEC_APP_FOR_DEVICE}
	
	echo "Install and launch decoder performance test app"
	InstallAndLaunchApp ${OPENH264_PERFTEST_IOS_TOOL_INSTALL_ON_DEVICE} ${OPENH264_PERFTEST_IOS_DEC_APP_FOR_DEVICE} ${OPENH264_PERFTEST_IOS_STD_OUT_ERR}
	
	PERF_TEST_DEC_APP_ID="cisco.decPerfTestApp"
	PERF_TEST_DEC_PATH="dec_result"
	EXTRACTRESULT_FILE_NAME="ExtractTestResult.py"
	DEC_LOG_FILE_NAME="DecPerfTest.log"
	DEC_RESULT_FILE_NAME="DecPerformance.csv"
	MountAppDocuments ${OPENH264_PERFTEST_IOS_TOOL_MOUNT_DEVICE} ${PERF_TEST_DEC_APP_ID} ${PERF_TEST_DEC_PATH} ${DEC_LOG_FILE_NAME}

	echo "Start extract result from log"
	if [ -f ${ENC_RESULT_FILE_NAME} ] ; then
		rm ${ENC_RESULT_FILE_NAME}
	fi
	if [ -f ${ENC_LOG_FILE_NAME} ] ; then
		rm ${ENC_LOG_FILE_NAME}
	fi
	cp ${PERF_TEST_ENC_PATH}/${ENC_LOG_FILE_NAME} ${BASE_PATH}
	cp ${PERF_TEST_ENC_PATH}/*.264 ${BASE_PATH}
	python ${EXTRACTRESULT_FILE_NAME} ${ENC_LOG_FILE_NAME} ${ENC_RESULT_FILE_NAME}
	if [ ! -f ${ENC_RESULT_FILE_NAME} ] ; then
		echo "Extract result failed"
		umount ${PERF_TEST_ENC_PATH}
		exit 1
	fi

	rm -r *.trace

	cat ${ENC_RESULT_FILE_NAME}

	umount ${PERF_TEST_ENC_PATH}
	umount ${PERF_TEST_DEC_PATH}

	echo "Complete Extract Test Result"
fi

