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

#command on real device is still in developing, so disable it now
#if [ ${OPENH264_PERFTEST_IOS_PLATFORM} == "iphoneos"  ]; then
#    echo "Command on real device is still in developing, so disable it now"
#    exit 2
#fi

echo "Performance Test will run on ${OPENH264_PERFTEST_IOS_PLATFORM} with ${OPENH264_PERFTEST_IOS_DEBUG_RELEASE}"
BASE_PATH=$(cd `dirname $0`; pwd)

###############################################################################
#generate test case

echo "###################################################################"
echo "##Generate test case"

cd ${BASE_PATH}
GENERATECASE_FILE_NAME="GenerateCase.py"
CASE_FILE_NAME="case.cfg"
CASELIST_FILE_NAME="caselist.cfg"
if [-f ${CASELIST_FILE_NAME}] ; then
rm ${CASELIST_FILE_NAME}
fi
python ${GENERATECASE_FILE_NAME} ${CASE_FILE_NAME} ${CASELIST_FILE_NAME}
if [ ! -f ${CASELIST_FILE_NAME} ] ; then
echo "Generate test case failed"
exit 1
fi


###############################################################################
echo "###################################################################"
echo "##Building libcommon, libprocessing, libwelsenc, libwelsdec and test app"

OPENH264_PERFTEST_IOS_COMMON_PATH=${BASE_PATH}/../codec/build/iOS/common
OPENH264_PERFTEST_IOS_PROCESSING_PATH=${BASE_PATH}/../codec/processing/build/iOS
OPENH264_PERFTEST_IOS_ENCODER_PATH=${BASE_PATH}/../codec/build/iOS/enc/welsenc
OPENH264_PERFTEST_IOS_DECODER_PATH=${BASE_PATH}/../codec/build/iOS/dec/welsdec
OPENH264_PERFTEST_IOS_PROJECT_PATH=${BASE_PATH}/../codec/build/iOS/enc/encPerfTestApp
OPENH264_PERFTEST_IOS_APP_PATH=${OPENH264_PERFTEST_IOS_PROJECT_PATH}/build
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
cd ${OPENH264_PERFTEST_IOS_PROJECT_PATH}
PROJECT_FILE_NAME="encPerfTestApp"
TARGET_NAME=${PROJECT_FILE_NAME}

buildProject ${PROJECT_FILE_NAME} ${TARGET_NAME} ${OPENH264_PERFTEST_IOS_DEBUG_RELEASE} ${OPENH264_PERFTEST_IOS_PLATFORM}
if [ $? != 0 ]; then
echo "Build ${PROJECT_FILE_NAME} failed, exit now"
exit 1
fi


###############################################################################
#begin to run perf test app

echo "###################################################################"
echo "##Install and launch performance test app"

OPENH264_PERFTEST_IOS_CONSOLE="/tmp/wme_encTest.log"
OPENH264_PERFTEST_IOS_APP_FOR_SIMULATOR=${OPENH264_PERFTEST_IOS_APP_PATH}/${OPENH264_PERFTEST_IOS_DEBUG_RELEASE}-iphonesimulator/encPerfTestApp.app
OPENH264_PERFTEST_IOS_APP_FOR_DEVICE=${OPENH264_PERFTEST_IOS_APP_PATH}/${OPENH264_PERFTEST_IOS_DEBUG_RELEASE}-iphoneos/encPerfTestApp.app

OPENH264_PERFTEST_IOS_TOOL_LAUNCH_ON_SIMULATOR="ios-sim"
OPENH264_PERFTEST_IOS_TOOL_INSTALL_ON_DEVICE="./fruitstrap"

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
fi

echo "Cleaning old test app"
pkill -9 'iPhone Simulator'
rm -rf /tmp/wme_encTest.log

echo "Begin to launching $TEST_NAME"

${OPENH264_PERFTEST_IOS_TOOL_LAUNCH_ON_SIMULATOR} launch ${OPENH264_PERFTEST_IOS_APP_FOR_SIMULATOR}  --exit --stderr ${OPENH264_PERFTEST_IOS_CONSOLE} --stdout ${OPENH264_PERFTEST_IOS_CONSOLE} > ${OPENH264_PERFTEST_IOS_STD_OUT_ERR} 2>&1

elif [ ${OPENH264_PERFTEST_IOS_PLATFORM} == iphoneos ]; then
# for real device
#if ! which ${OPENH264_PERFTEST_IOS_TOOL_INSTALL_ON_DEVICE} ; then
#echo "${OPENH264_PERFTEST_IOS_TOOL_INSTALL_ON_DEVICE} is not found, please install ${OPENH264_PERFTEST_IOS_TOOL_INSTALL_ON_DEVICE}"
if [ ! -f ${OPENH264_PERFTEST_IOS_TOOL_INSTALL_ON_DEVICE} ] ; then
echo "${OPENH264_PERFTEST_IOS_TOOL_INSTALL_ON_DEVICE} is not found, please make sure the file exists"
exit 1
else
echo "Find ${OPENH264_PERFTEST_IOS_TOOL_INSTALL_ON_DEVICE}"
fi

if [ ! -d ${OPENH264_PERFTEST_IOS_APP_FOR_DEVICE} ] ; then
echo "${OPENH264_PERFTEST_IOS_APP_FOR_DEVICE} is not found"
exit 1
else
echo "Find app ${OPENH264_PERFTEST_IOS_APP_FOR_DEVICE}"
fi

echo "Begin to launching $TEST_NAME"

touch /tmp/test.js

GREP_RESULT=`system_profiler SPUSBDataType | sed -n -e '/iPad/,/Serial/p' -e '/iPhone/,/Serial/p' | grep "Serial Number:" | awk -F ": " '{print $2}'`

for DEVICE_ID in ${GREP_RESULT}
do
echo "Try to run on device:${DEVICE_ID}"

${OPENH264_PERFTEST_IOS_TOOL_INSTALL_ON_DEVICE} -b ${OPENH264_PERFTEST_IOS_APP_FOR_DEVICE} -i ${DEVICE_ID} > ${OPENH264_PERFTEST_IOS_STD_OUT_ERR} 2>&1

instruments -w ${DEVICE_ID}  -t /Applications/Xcode.app/Contents/Applications/Instruments.app/Contents/PlugIns/AutomationInstrument.bundle/Contents/Resources/Automation.tracetemplate ${OPENH264_PERFTEST_IOS_APP_FOR_DEVICE} -e UIASCRIPT /tmp/test.js -e UIARRESULTPATH /tmp/ > ${OPENH264_PERFTEST_IOS_STD_OUT_ERR} 2>&1

done
else
echo "parameters for platform is wrong : ${OPENH264_PERFTEST_IOS_PLATFORM}"
fi

###############################################################################
#Begin to analyse test result

echo "###################################################################"
echo "##Begin to analyse test result"

cd ${BASE_PATH}

if [ ${OPENH264_PERFTEST_IOS_PLATFORM} == iphonesimulator ] ; then
echo "Complete test on simulator!"
exit 1

elif [ ${OPENH264_PERFTEST_IOS_PLATFORM} == iphoneos ] ; then

echo "mount device"
OPENH264_PERFTEST_IOS_TOOL_MOUNT_DEVICE="ifuse"
if ! which ${OPENH264_PERFTEST_IOS_TOOL_MOUNT_DEVICE} ; then
echo "${OPENH264_PERFTEST_IOS_TOOL_MOUNT_DEVICE} is not found, please install ifuse"
exit 1
else
echo "Find ${OPENH264_PERFTEST_IOS_TOOL_MOUNT_DEVICE}"
fi

PERF_TEST_APP_ID="cisco.encPerfTestApp"
PERF_TEST_RESULT_PATH="result"
if [ ! -d ${PERF_TEST_RESULT_PATH} ] ; then
mkdir ${PERF_TEST_RESULT_PATH}
fi

echo "${OPENH264_PERFTEST_IOS_TOOL_MOUNT_DEVICE} --documents ${PERF_TEST_APP_ID} ${PERF_TEST_RESULT_PATH}"
${OPENH264_PERFTEST_IOS_TOOL_MOUNT_DEVICE} --documents ${PERF_TEST_APP_ID} result
EXTRACTRESULT_FILE_NAME="ExtractTestResult.py"
LOG_FILE_NAME="PerfTest.log"
RESULT_FILE_NAME="Performance.csv"
while [ ! -f "${PERF_TEST_RESULT_PATH}/${LOG_FILE_NAME}" ] 
do
sleep 5
echo "wait for mounting"
done
echo "mount successfully"

ls ${PERF_TEST_RESULT_PATH}

if [ -f ${RESULT_FILE_NAME} ] ; then
rm ${RESULT_FILE_NAME}
fi
if [ -f ${LOG_FILE_NAME} ] ; then
rm ${LOG_FILE_NAME}
fi
cp ${PERF_TEST_RESULT_PATH}/${LOG_FILE_NAME} ${BASE_PATH}
python ${EXTRACTRESULT_FILE_NAME} ${LOG_FILE_NAME} ${RESULT_FILE_NAME}
if [ ! -f ${RESULT_FILE_NAME} ] ; then
echo "Extract result failed"
umount ${PERF_TEST_RESULT_PATH}
exit 1
fi

rm -r *.trace

cat ${RESULT_FILE_NAME}

umount ${PERF_TEST_RESULT_PATH}

echo "Complete Extract Test Result"
fi

