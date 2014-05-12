#include <string.h>
#include <stdlib.h>
#include <jni.h>
#include <android/log.h>

#define LOG_TAG "welsdec"
#define LOGI(...) __android_log_print(ANDROID_LOG_DEBUG, LOG_TAG, __VA_ARGS__)

extern int DecMain (int argc, char* argv[]);

extern "C"
JNIEXPORT void JNICALL Java_com_wels_decPerfTestApp_DecTestThread_DoDecTest
(JNIEnv* env, jobject thiz, jstring jsFileNameIn, jstring jsFileNameOut) {
  char* argv[3];
  int  argc = 3;
  argv[0] = (char*) ("decConsole.exe");
  argv[1] = (char*) ((*env).GetStringUTFChars (jsFileNameIn, NULL));
  argv[2] = (char*) ((*env).GetStringUTFChars (jsFileNameOut, NULL));

  DecMain (argc, argv);
}



