package com.wels.encPerfTestApp;

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
                    EncTestThread test = new EncTestThread(uiHandler);
                    cpu.EnableUsage(3);
                    StartTimer();
                    test.start();
                    mTvStatus.setText("Encoder Test In Process...");
                    break;
                }
            }
        };

        uiHandler = new Handler() {
            @Override
            public void handleMessage(Message msg) {
                switch (msg.what) {
                    case Messages.MSG_TEST_COMPLETED:
                        mTvStatus.setText("Encoder Test Completed");
                        //cpu.DisableUsage();
                        StopTimer();
                        break;
                }
            }
        };

        cpu = new CpuHelper();

        mBtnStart.setOnClickListener(OnClickEvent);

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

    private  static final String TAG = "MainActivity";
    static {
        try {
            System.loadLibrary("wels");
            System.loadLibrary("stlport_shared");
            System.loadLibrary("welsencdemo");
            Log.v(TAG,"Load libwelsencdemo.so successfully");
        }
        catch (Exception e) {
            Log.e(TAG, "Failed to load welsenc"+e.getMessage());
        }
    }
}

class EncTestThread extends Thread {
    Handler uiHandle;

    final String mWorkPath = "/sdcard/encTest/";
    final String mCaselistName = "enc_caselist.cfg";
    Vector<String> mCfgList = new Vector<String>();

    public native void DoEncTest(int argc, String[] cmd);

    EncTestThread (Handler handler) {
        uiHandle = handler;
    }

    public void run() {
        String caselistPath = mWorkPath + mCaselistName;
        LoadCaseList(caselistPath,mCfgList);

        try {
            for (int i=0; i<mCfgList.size(); i++) {
                String cmd = mCfgList.get(i);
                String argv[] = cmd.split(" ");
                argv[1] = mWorkPath+argv[1];
                argv[3] = mWorkPath+argv[3];
                argv[5] = mWorkPath+argv[5];
                argv[8] = mWorkPath+argv[8];
                Log.i(TAG,argv[3]);
                DoEncTest(argv.length, argv);
            }
        } catch (Exception e) {
            Log.e(TAG, e.getMessage());
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
            Log.e(TAG, e.getMessage());
        }
    }

    private  static final String TAG = "welsenc";
}

class Messages {
    public static final int MSG_TEST_COMPLETED = 0x1;
}