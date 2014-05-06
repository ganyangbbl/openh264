#include <string.h>
#include <stdlib.h>
#include <jni.h>
#include <android/log.h>

#define LOG_TAG "welsenc"
#define LOGI(...) __android_log_print(ANDROID_LOG_DEBUG, LOG_TAG, __VA_ARGS__)

extern "C" int EncMain (int argc, char **argv);

extern "C"
JNIEXPORT void JNICALL Java_com_wels_encPerfTestApp_DoEncTest
(JNIEnv *env, jobject thiz) {
  char *argv[32];
  jstring str;


//  for (int i=0; i<count; i++)
  {
//    str = (jstring)((*env).GetObjectArrayElement(cmd, i));
//    argv[i] = (char*) ((*env).GetStringUTFChars (str, NULL));
  }

//  for (int i=0; i<count; i++)
  {
  //  LOGI("%s,",argv[i]);
  }

  //EncMain (argc, argv);
}