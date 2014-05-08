#include <string.h>
#include <stdlib.h>
#include <jni.h>
#include <android/log.h>

#define LOG_TAG "welsdec"
#define LOGI(...) __android_log_print(ANDROID_LOG_DEBUG, LOG_TAG, __VA_ARGS__)

extern "C" int DecMain (int argc, char **argv);

extern "C"
JNIEXPORT void JNICALL Java_com_wels_decPerfTestApp_DecTestThread_DoDecTest
(JNIEnv *env, jobject thiz, jint argc, jobjectArray cmd) {
  char *argv[32];
  jstring str;

  for (int i=0; i<argc; i++)
  {
    str = (jstring)((*env).GetObjectArrayElement(cmd, i));
    argv[i] = (char*) ((*env).GetStringUTFChars (str, NULL));
  }

  DecMain (argc, argv);
}