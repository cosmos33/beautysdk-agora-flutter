package com.cosmos.mm;

import android.content.Context;

import com.core.glcore.cv.MMCVInfo;
import com.cosmos.beauty.CosmosBeautySDK;
import com.cosmos.beauty.inter.OnAuthenticationStateListener;
import com.cosmos.beauty.inter.OnBeautyResourcePreparedListener;
import com.cosmos.beauty.model.AuthResult;
import com.cosmos.beauty.model.BeautySDKInitConfig;
import com.cosmos.beauty.module.IMMRenderModuleManager;
import com.cosmos.beauty.module.beauty.IBeautyModule;
import com.cosmos.beauty.module.beauty.SimpleBeautyType;
import com.cosmos.beauty.module.lookup.ILookupModule;
import com.cosmos.beauty.module.makeup.IMakeupBeautyModule;
import com.cosmos.beauty.module.sticker.DetectRect;
import com.cosmos.beauty.module.sticker.IStickerModule;
import com.cosmos.beauty.module.sticker.MaskLoadCallback;
import com.cosmos.beautyutils.BuildConfig;
import com.cosmos.beautyutils.Empty2Filter;
import com.cosmos.beautyutils.FaceInfoCreatorPBOFilter;
import com.immomo.resdownloader.utils.MainThreadExecutor;
import com.mm.mmutil.toast.Toaster;
import com.momo.mcamera.mask.MaskModel;

import org.jetbrains.annotations.NotNull;
import org.jetbrains.annotations.Nullable;

import java.io.File;

abstract public class BeautyManager implements IMMRenderModuleManager.CVModelStatusListener, IMMRenderModuleManager.IDetectFaceCallback, IMMRenderModuleManager.IDetectGestureCallback {
  protected static String cosmosAppid = "";// TODO mmbeauty 这里需要修改为cosmos后台注册的appid
  protected IMMRenderModuleManager renderModuleManager;
  protected boolean authSuccess = false;
  protected boolean filterResouceSuccess = false;
  protected boolean cvModelSuccess = false;
  protected boolean stickerSuccess;
  protected IMakeupBeautyModule iBeautyModule;
  protected ILookupModule iLookupModule;
  protected IStickerModule iStickerModule;
  protected boolean resourceReady = false;
  protected Context context;
  protected String appId;
  protected FaceInfoCreatorPBOFilter faceInfoCreatorPBOFilter;
  protected Empty2Filter emptyFilter;

  public BeautyManager(Context context, String appId) {
    this.context = context.getApplicationContext();
    this.appId = appId;
    initSDK();
  }

  public int renderWithOESTexture(int texture, int texWidth, int texHeight, boolean mFrontCamera, int cameraRotation) {
    return texture;
  }

  public int renderWithTexture(int texture, int texWidth, int texHeight, boolean mFrontCamera) {
    return texHeight;
  }

  public int renderWithBytesTexture(byte[] datas, int texture, int dataWidth, int dataHeight, int texWidth, int texHeight, boolean mFrontCamera) {
    return texture;
  }

  public int renderWithBytesTexture(byte[] datas, int texture, int dataWidth, int dataHeight, int texWidth, int texHeight, boolean mFrontCamera, int cameraRotaion) {
    return texture;
  }

  public int renderWithBytesAndOesTexture(byte[] bytes, int texture, int texWidth, int texHeight, boolean mFrontCamera, int rotation) {
    return texture;
  }

  public void textureDestoryed() {
    if (faceInfoCreatorPBOFilter != null) {
      faceInfoCreatorPBOFilter.destroy();
      faceInfoCreatorPBOFilter = null;
    }
    if (emptyFilter != null) {
      emptyFilter.destroy();
      emptyFilter = null;
    }
    if (renderModuleManager != null) {
      if (iBeautyModule != null) {
        renderModuleManager.unRegisterModule(iBeautyModule);
      }
      if (iLookupModule != null) {
        renderModuleManager.unRegisterModule(iLookupModule);
      }
      if (iStickerModule != null) {
        renderModuleManager.unRegisterModule(iStickerModule);
      }
      renderModuleManager.destroyModuleChain();
      renderModuleManager.release();
    }

  }

  private void initSDK() {
    BeautySDKInitConfig beautySDKInitConfig = new BeautySDKInitConfig.Builder(appId)
      .build();
    CosmosBeautySDK.INSTANCE.init(context, beautySDKInitConfig, new OnAuthenticationStateListener() {
      public void onResult(AuthResult result) {
        if (!result.isSucceed()) {
          Toaster.show(String.format("授权失败:%s", result.getMsg()));
        } else {
          MainThreadExecutor.post(new Runnable() {
            @Override
            public void run() {
              authSuccess = true;
              checkResouceReady();
            }
          });
        }
      }
    }, new OnBeautyResourcePreparedListener() {
      public void onResult(boolean isSucceed) {
        if (!isSucceed) {
          Toaster.show("resource false");
        }
      }
    });

    FilterUtils.INSTANCE.prepareFilterResource(context, new OnFilterResourcePrepareListener() {
      public void onFilterReady() {
        filterResouceSuccess = true;
        checkResouceReady();
      }
    });
    FilterUtils.INSTANCE.prepareStikcerResource(context, new OnStickerResourcePrepareListener() {
      public void onStickerReady(String rootPath) {
        stickerSuccess = true;
        checkResouceReady();
      }
    });
    renderModuleManager = CosmosBeautySDK.INSTANCE.createRenderModuleManager();
    renderModuleManager.prepare(true, this, this, this);
  }

  private void checkResouceReady() {
    if (cvModelSuccess && filterResouceSuccess && authSuccess && stickerSuccess) {
      MainThreadExecutor.post(new Runnable() {
        @Override
        public void run() {
          initRender();
          resourceReady = true;
        }
      });
    }
  }

  protected void initRender() {
    iBeautyModule = CosmosBeautySDK.INSTANCE.createMakeupBeautyModule();
    renderModuleManager.registerModule(iBeautyModule);

    iLookupModule = CosmosBeautySDK.INSTANCE.createLoopupModule();
    renderModuleManager.registerModule(iLookupModule);

    iStickerModule = CosmosBeautySDK.INSTANCE.createStickerModule();
    renderModuleManager.registerModule(iStickerModule);
  }

  @Override
  public void onCvModelDownloadStatus(boolean loadCvModelSuccess) {
    if (loadCvModelSuccess) {
      cvModelSuccess = true;
      checkResouceReady();
    }
  }

  @Override
  public void onCvModelLoadSatus(boolean b) {

  }

  @Override
  public void onDetectHead(@Nullable MMCVInfo info) {

  }

  @Override
  public void onDetectGesture(@NotNull String type, @NotNull DetectRect detect) {

  }

  @Override
  public void onGestureMiss() {

  }
}
