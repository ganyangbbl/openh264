package com.wels.encPerfTestApp;

import android.app.Activity;
import android.os.Bundle;
import android.util.Log;

import android.view.View;
import android.view.View.OnClickListener;

import android.widget.Button;
import android.widget.TextView;
import java.io.*;
import java.util.Vector;

public class MainActivity extends Activity {
    private OnClickListener OnClickEvent;
    private Button mBtnStart;
    private TextView mTvStatus;

    final String mWorkPath = "/sdcard/encTest/enc_caselist.cfg";
    Vector<String> mCfgList = new Vector<String>();

    public native void DoEncTest();
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
                switch (view.getId())
                {
                case R.id.buttonstart:
                    String caselistPath = mWorkPath;
                    LoadCaseList(caselistPath,mCfgList);
                    try {
                        for (int i=0; i<mCfgList.size(); i++) {
                            String cmd = mCfgList.get(i);
                            String argv[] = cmd.split(" ");
                            for (int j=0; j<argv.length; j++)
                                Log.v(TAG,argv[j]+" ");
                            Log.v(TAG,"\n");
                            DoEncTest();
                        }
                    } catch (Exception e) {
                        Log.e(TAG, e.getMessage());
                    }

                    break;
                }
            }
        };

        mBtnStart.setOnClickListener(OnClickEvent);
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

        } catch (IOException e) {
            Log.e(TAG, e.getMessage());
        }
    }

    private  static final String TAG = "welsenc";
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
