package com.wels.decPerfTestApp;

import android.app.Activity;
import android.os.Bundle;
import android.os.Handler;
import android.os.Message;
import android.util.Log;

import android.view.View;
import android.view.View.OnClickListener;

import android.widget.Button;
import android.widget.TextView;
import java.io.*;
import java.util.Vector;
import java.util.Timer;
import java.util.TimerTask;

public class MainActivity extends Activity {
    private OnClickListener OnClickEvent;
    private Handler uiHandler;
    private Timer mTimer = null;
    private TimerTask mTask = null;
    private CpuHelper cpu;

    private Button mBtnStart;
    private TextView mTvStatus;

    private File mEndFile;
    final String mEndFilePath = "/sdcard/decTest/";
    final String mEndFileName = "dec_progress.log";

    /**
     * Called when the activity is first created.
     */
    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.main);

        mBtnStart = (Button)findViewById(R.id.buttonstart);
        mTvStatus = (TextView)findViewById(R.id.textviewstatus);

        OnClickEvent = new OnClickListener() {
            @Override
            public void onClick(View view) {
                switch (view.getId()) {
                case R.id.buttonstart:
                    DecTestThread test = new DecTestThread(uiHandler);
                    StartTimer();
                    test.start();
                    mTvStatus.setText("Decoder Test In Process...");
                    break;
                }
            }
        };

        uiHandler = new Handler() {
            @Override
            public void handleMessage(Message msg) {
                switch (msg.what) {
                    case Messages.MSG_TEST_COMPLETED:
                        mTvStatus.setText("Decoder Test Completed");
                        //cpu.DisableUsage();
                        StopTimer();
                        OutputProgress();
                        break;
                }
            }
        };

        mEndFile = new File(mEndFilePath+mEndFileName);
        if (mEndFile.isFile() && mEndFile.exists()) {
            mEndFile.delete();
        }

        cpu = new CpuHelper();
        cpu.EnableUsage(3);

        mBtnStart.setOnClickListener(OnClickEvent);

    }

    private void OutputProgress() {
        try {
            if (! mEndFile.exists()) {
                mEndFile.createNewFile();
            }
            BufferedWriter writer = new BufferedWriter(new FileWriter(mEndFile));
            writer.write("flag");
            writer.close();
        } catch (Exception e) {
            Log.e(TAG,"Write progress file failed"+e.getMessage());
        }
    }

    private void StartTimer() {
        if (mTimer == null) {
            mTimer = new Timer();
        }

        if (mTask == null) {
            mTask = new TimerTask() {
                @Override
                public void run() {
                    Log.i(TAG,"CPU Usage: "+cpu.usage);
                }
            };
        }

        if (mTimer != null && mTask != null)
            mTimer.schedule(mTask, 100, 1000);
    }

    private void StopTimer() {
        if (mTimer != null) {
            mTimer.cancel();
            mTimer = null;
        }
        if (mTask != null) {
            mTask.cancel();
            mTask = null;
        }
    }

    private  static final String TAG = "welsdec";
    static {
        try {
            System.loadLibrary("openh264");
            System.loadLibrary("stlport_shared");
            System.loadLibrary("welsdecdemo");
            Log.v(TAG,"Load libwelsdecdemo.so successfully");
        }
        catch (Exception e) {
            Log.e(TAG, "Failed to load welsdec"+e.getMessage());
        }
    }
}

class DecTestThread extends Thread {
    Handler uiHandle;

    final String mWorkPath = "/sdcard/decTest/";
    final String mCaselistName = "dec_caselist.cfg";
    Vector<String> mCfgList = new Vector<String>();

    public native void DoDecTest(String filenamein, String filenameout);

    DecTestThread (Handler handler) {
        uiHandle = handler;
    }

    public void run() {
        String caselistPath = mWorkPath + mCaselistName;
        LoadCaseList(caselistPath,mCfgList);

        try {
            for (int i=0; i<mCfgList.size(); i++) {
                String cmd = mCfgList.get(i);
                String argv[] = cmd.split(" ");
                Log.i(TAG,"######Decoder Test "+i+" Start########");
                Log.i(TAG,"Test file: "+argv[1]);
                Log.i(TAG,"YUV file: "+argv[2]);
                argv[1] = mWorkPath+argv[1];
                argv[2] = mWorkPath+argv[2];
                DoDecTest(argv[1], argv[2]);
                Log.i(TAG,"######Decoder Test "+i+" Completed########");
            }
        } catch (Exception e) {
            Log.e(TAG, "DoDecTest failed"+e.getMessage());
        }
        mCfgList.clear();
        uiHandle.sendEmptyMessage(Messages.MSG_TEST_COMPLETED);
    }

    private void LoadCaseList(String filePath, Vector<String> list)
    {
        try {
            InputStream iStream = new FileInputStream(filePath);
            BufferedReader reader = new BufferedReader(new InputStreamReader(iStream));
            String line;
            while ((line = reader.readLine()) != null) {
                list.add(line);
            }
            reader.close();
        } catch (IOException e) {
            Log.e(TAG, "Read case list file failed"+e.getMessage());
        }
    }

    private  static final String TAG = "welsdec";
}

class Messages {
    public static final int MSG_TEST_COMPLETED = 0x1;
}