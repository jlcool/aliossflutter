package com.jlcool.aliossflutter;



import android.util.Log;

import com.alibaba.sdk.android.oss.common.auth.OSSAuthCredentialsProvider;

import org.json.JSONException;
import org.json.JSONObject;

import io.flutter.plugin.common.MethodChannel;

public class AliDecoder implements OSSAuthCredentialsProvider.AuthDecoder {
    private   String key;
    MethodChannel.Result _result;
    AliDecoder(String key,MethodChannel.Result result){
        _result=result;
        this.key=key;
    }
    @Override
    public String decode(String data) {
        JSONObject jsonObj = null;
        try {
            jsonObj = new JSONObject(data);
            String dec = jsonObj.getString("Data");
            SecretUtils.PASSWORD_CRYPT_KEY=this.key;
            return new String(SecretUtils.decryptMode(dec));
        } catch (JSONException e) {
            e.printStackTrace();
        }
        return null;
    }
}
