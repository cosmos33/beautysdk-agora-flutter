package com.cosmos.mm;

import android.content.Context;
import android.graphics.Bitmap;
import android.opengl.EGLSurface;

import com.core.glcore.util.ImageFrame;
import com.cosmos.beauty.model.MMRenderFrameParams;
import com.cosmos.beauty.model.datamode.CameraDataMode;
import com.cosmos.beauty.module.beauty.AutoBeautyType;
import com.cosmos.beauty.module.beauty.SimpleBeautyType;
import com.cosmos.beauty.module.sticker.MaskLoadCallback;
import com.cosmos.beautyutils.Empty2Filter;
import com.cosmos.beautyutils.RotateFilter;
import com.mm.mmutil.toast.Toaster;
import com.momo.mcamera.mask.MaskModel;

import org.jetbrains.annotations.NotNull;
import org.jetbrains.annotations.Nullable;

import java.io.File;
import java.nio.ByteBuffer;
import java.util.Locale;

import project.android.imageprocessing.input.NV21PreviewInput;
import project.android.imageprocessing.input.NewNV21PreviewInput;

/**
 * 声网接入美颜sdk管理类
 */
public class AgoraRawDataBeautyManager extends BeautyManager {
  private NV21PreviewInput yuvToTexture;
  private RotateFilter rotateFilter;
  private RotateFilter rotateFilter1;
  private RotateFilter rotateFilter2;

  public AgoraRawDataBeautyManager(Context context,String appid) {
    super(context, appid);
  }

  public ByteBuffer renderWithRawData(byte[] data, int width, int height, int rotation, boolean mFrontCamera) {
    if (!resourceReady) {
      return null;
    }
    if (!EGLHelper.Companion.getInstance().checkContext()) {
      EGLHelper.Companion.getInstance().init();
      EGLSurface eglSurface = EGLHelper.Companion.getInstance().genEglSurface(null);
      EGLHelper.Companion.getInstance().makeCurrent(eglSurface);
    }
    if (yuvToTexture == null) {
      yuvToTexture = new NewNV21PreviewInput();
      yuvToTexture.setRenderSize(width, height);
      faceInfoCreatorPBOFilter = new FaceInfoCreatorPBOSubFilter(width, height);
      emptyFilter = new Empty2Filter();
      emptyFilter.setRenderSize(width, height);
      rotateFilter = new RotateFilter(RotateFilter.ROTATE_HORIZONTAL);
      rotateFilter1 = new RotateFilter(RotateFilter.ROTATE_270);
      rotateFilter2 = new RotateFilter(RotateFilter.ROTATE_90);
    }
    yuvToTexture.updateYUVBuffer(data, width * height);
    yuvToTexture.onDrawFrame();
    int textOutID = yuvToTexture.getTextOutID();
    int rotateTexture = rotateFilter2.rotateTexture(textOutID, width, height);
    int texWidth = width;
    int texHeight = height;
    if (rotation / 90 == 1 || rotation / 90 == 3) {
      texWidth = height;
      texHeight = width;
    }
    CameraDataMode cameraDataMode = new CameraDataMode(mFrontCamera, 90);
    int beautyTexture = renderModuleManager.renderFrame(rotateTexture, new MMRenderFrameParams(
      cameraDataMode,
      data,
      width,
      height,
      texWidth,
      texHeight,
      ImageFrame.MMFormat.FMT_NV21
    ));
    int rotateTexId = rotateFilter.rotateTexture(beautyTexture, width, height);
    int rotateTexId1 = rotateFilter1.rotateTexture(rotateTexId, width, height);
    faceInfoCreatorPBOFilter.newTextureReady(rotateTexId1, emptyFilter, true);
    return faceInfoCreatorPBOFilter.byteBuffer;
  }

  @Override
  public void textureDestoryed() {
    super.textureDestoryed();
    if (yuvToTexture != null) {
      yuvToTexture.destroy();
      yuvToTexture = null;
    }
    if (rotateFilter != null) {
      rotateFilter.destory();
      rotateFilter = null;
    }
    if (rotateFilter1 != null) {
      rotateFilter1.destory();
      rotateFilter1 = null;
    }
    if (rotateFilter2 != null) {
      rotateFilter2.destory();
      rotateFilter2 = null;
    }
  }
}
