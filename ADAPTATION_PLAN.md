# Foxus Quest1 适配完整修改方案

## 项目概述
将原面向 Oculus Quest 2 的 Foxus USB 摄像头彩色透视应用适配到 Oculus Quest 1，并支持大疆 Action 2 运动相机。

## 一、硬件与系统适配

### 1.1 Android SDK/NDK 版本适配
**目标设备：** Oculus Quest 1（Android 10, API 29）

#### 修改文件：`foxus/export_presets.cfg`
```ini
custom_build/min_sdk="29"
custom_build/target_sdk="29"
version/code=2
version/name="1.1"
package/unique_name="com.foxus.quest1"
package/name="Foxus Quest1"
```

#### 修改文件：`foxus/android/plugins/EiffelCamera/eiffelcamera/build.gradle`
```gradle
android {
    compileSdk 29
    defaultConfig {
        minSdk 29
        targetSdk 29
        versionCode 2
        versionName "1.1"
    }
}
```

#### 修改文件：`gd_eiffelcam/SConstruct`
```python
# Validate API level - Quest 1 uses Android 10 (API 29)
api_level='29'
```

### 1.2 权限配置适配
**修改文件：** `foxus/android/plugins/EiffelCamera/eiffelcamera/src/main/AndroidManifest.xml`

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.voxels.eiffelcamera">

    <uses-feature android:name="android.hardware.usb.host" />
    <uses-feature android:name="android.hardware.camera" />

    <uses-permission android:name="android.permission.CAMERA" />
    <uses-permission android:name="android.permission.USB_PERMISSION" />
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />

    <application>
        <meta-data
            android:name="org.godotengine.plugin.v1.EiffelCamera"
            android:value="com.voxels.eiffelcamera.GodotEiffelCamera" />
    </application>
</manifest>
```

## 二、摄像头驱动适配

### 2.1 大疆 Action 2 摄像头配置
**目标设备：** 大疆 Action 2 运动相机（USB 网络摄像头模式）
**硬件 ID：** USB\VID_2CA3&PID_0021
**视频规格：** 1920x1080 @ 30fps

#### 修改文件：`gd_eiffelcam/src/gd_eiffelcam.cpp`
```cpp
void GDEiffelCam::_init() {
    // USB Vendor ID and Product ID for DJI Action 2 Camera.
    vid=0x2CA3;
    pid=0x0021;
    // Stream characteristics we will attempt to use (1080P @ 30fps)
    streamWidth=1920;
    streamHeight=1080;
    streamFps=30;

    frame_array_size = 6;  // Reduced from 10 to 6 for Quest 1 performance optimization

    singleton = this;

    setenv("JSIMD_FORCENEON", "1", 1);

    cv::setUseOptimized(true);
    cv::setNumThreads(4);  // Limit threads for Snapdragon 835 (4 big cores)

    Godot::print(cv::getBuildInformation().c_str());

    if (!cv::useOptimized()) {
        Godot::print("MASSIVE PROBLEM: OPENCV IS NOT USING OPTIMISED SIMD CODE");
    }

    if (!cv::checkHardwareSupport(CV_CPU_NEON)) {
        Godot::print("MASSIVE PROBLEM: OPENCV DOES NOT SUPPORT NEON");
    }
}
```

### 2.2 UVC 驱动兼容性验证
- ✅ libuvc 库已包含在 prebuilts 中
- ✅ USB Host 模式已启用
- ✅ 标准UVC协议支持（大疆 Action 2 使用标准 UVC）
- ⚠️ 需要在实际设备上验证摄像头连接和视频流

## 三、性能优化（针对骁龙 835）

### 3.1 视频流处理优化
**修改文件：** `gd_eiffelcam/src/gd_eiffelcam.cpp`

#### JPEG 解码优化
```cpp
void ImageProcessor::create_decompressor()  {
    jpeg_create_decompress(&cinfo);

    cinfo.dct_method = JDCT_FASTEST;
    cinfo.two_pass_quantize = FALSE;
    cinfo.dither_mode = JDITHER_NONE;
    cinfo.desired_number_of_colors = 512;  // Reduced from 1024 for performance
    cinfo.do_fancy_upsampling = FALSE;
    cinfo.out_color_space = JCS_RGB;

    cinfo.err = jpeg_std_error(&jerr);
    cinfo.err->trace_level = 0;
    jerr.error_exit = jpegErrorExit;
}
```

#### OpenCV 处理优化
```cpp
// Use INTER_NEAREST for better performance on Quest 1
cv::remap(decodedImage, targetFrame, *mapX, *mapY, cv::INTER_NEAREST, cv::BORDER_CONSTANT, cv::Scalar(0, 0, 0));
```

### 3.2 GPU 渲染优化
**修改文件：** `foxus/project.godot`

```ini
[rendering]
quality/filters/msaa=0
quality/depth/hdr=false
environment/default_environment="res://default_env.tres"
```

### 3.3 性能优化总结
| 优化项 | 原值 | 新值 | 说明 |
|--------|------|------|------|
| frame_array_size | 10 | 6 | 减少内存占用 |
| OpenCV 线程数 | 默认 | 4 | 适配骁龙835 4大核 |
| JPEG 颜色数 | 1024 | 512 | 降低解码复杂度 |
| MSAA | 1 | 0 | 关闭多重采样抗锯齿 |
| HDR | 启用 | 禁用 | 降低GPU负载 |
| remap 插值 | INTER_LINEAR | INTER_NEAREST | 提升处理速度 |

## 四、中文语言支持

### 4.1 翻译文件结构
```
foxus/
└── locales/
    ├── en.json      # 英文翻译
    └── zh_CN.json   # 中文翻译
```

#### 英文翻译文件：`locales/en.json`
```json
{
  "locale_name": "English",
  "locale_code": "en",
  "ui": {
    "status": {
      "not_connected": "Not connected",
      "attached": "Attached",
      "connected": "Connected"
    },
    "buttons": {
      "ask_for_permission": "Ask for Permission",
      "calibrate": "Calibrate",
      "save": "Save",
      "cancel": "Cancel",
      "accept": "Accept"
    },
    "tabs": {
      "status": "Status",
      "options": "Options",
      "calibration": "Calibration"
    }
  }
}
```

#### 中文翻译文件：`locales/zh_CN.json`
```json
{
  "locale_name": "简体中文",
  "locale_code": "zh_CN",
  "ui": {
    "status": {
      "not_connected": "未连接",
      "attached": "已连接",
      "connected": "已就绪"
    },
    "buttons": {
      "ask_for_permission": "请求权限",
      "calibrate": "校准",
      "save": "保存",
      "cancel": "取消",
      "accept": "接受"
    },
    "tabs": {
      "status": "状态",
      "options": "选项",
      "calibration": "校准"
    }
  }
}
```

### 4.2 语言管理器
**新建文件：** `foxus/scenes/LanguageManager.gd`

功能：
- 加载所有翻译文件
- 提供语言切换功能
- 保存用户语言偏好
- 提供翻译接口 `tr(key_path)`

### 4.3 语言切换器
**新建文件：** `foxus/scenes/LanguageSelector.gd`

功能：
- 显示支持的语言列表
- 高亮当前选择的语言
- 切换语言并更新UI

### 4.4 UI 文本更新
**修改文件：** `foxus/scenes/Status.gd`

- 集成 LanguageManager 单例
- 使用翻译函数替换硬编码文本
- 监听语言变更事件
- 动态更新UI文本

### 4.5 项目配置
**修改文件：** `foxus/project.godot`

```ini
[gdnative]
singletons=[ "res://addons/godot_ovrmobile/godot_ovrmobile.gdnlib", "res://scenes/LanguageManager.gd" ]
```

## 五、修改文件清单

### 5.1 核心配置文件
1. `foxus/export_presets.cfg` - Android 导出配置
2. `foxus/project.godot` - Godot 项目配置
3. `foxus/android/plugins/EiffelCamera/eiffelcamera/build.gradle` - Gradle 构建配置
4. `foxus/android/plugins/EiffelCamera/eiffelcamera/src/main/AndroidManifest.xml` - Android 清单
5. `gd_eiffelcam/SConstruct` - SCons 构建脚本

### 5.2 摄像头驱动文件
1. `gd_eiffelcam/src/gd_eiffelcam.cpp` - 摄像头核心实现

### 5.3 国际化文件（新建）
1. `foxus/locales/en.json` - 英文翻译
2. `foxus/locales/zh_CN.json` - 中文翻译
3. `foxus/scenes/LanguageManager.gd` - 语言管理器
4. `foxus/scenes/LanguageSelector.gd` - 语言切换器

### 5.4 UI 文件（修改）
1. `foxus/scenes/Status.gd` - 状态显示UI

## 六、关键修改点总结

### 6.1 硬件适配
- ✅ Android SDK/NDK 版本：API 29（Android 10）
- ✅ 架构支持：ARM64-v8a
- ✅ 权限声明：USB Host、Camera、存储权限

### 6.2 摄像头适配
- ✅ VID/PID：0x2CA3/0x0021（大疆 Action 2）
- ✅ 视频规格：1920x1080 @ 30fps
- ✅ UVC 协议支持

### 6.3 性能优化
- ✅ 内存优化：减少帧缓冲区数量
- ✅ CPU 优化：限制 OpenCV 线程数
- ✅ GPU 优化：关闭 MSAA 和 HDR
- ✅ 算法优化：使用快速插值方法

### 6.4 国际化支持
- ✅ 翻译系统：支持英文和中文
- ✅ 语言切换：动态切换界面语言
- ✅ 用户偏好：保存语言选择

## 七、注意事项

### 7.1 兼容性验证
- ⚠️ 需要在实际 Quest 1 设备上测试
- ⚠️ 需要验证大疆 Action 2 的 USB OTG 连接
- ⚠️ 需要测试 1080P@30fps 的实时性能

### 7.2 性能监控
- 建议使用 Perfetto 进行性能分析
- 监控帧率和延迟
- 检查内存使用情况

### 7.3 权限处理
- 首次启动需要用户授权 USB 访问权限
- 需要处理权限拒绝的情况
- 提供重新请求权限的界面

## 八、后续优化建议

### 8.1 性能进一步优化
- 考虑使用 Vulkan 渲染管线
- 优化着色器代码
- 实现动态分辨率调整

### 8.2 功能增强
- 添加更多语言支持
- 实现相机参数调节界面
- 添加录制功能

### 8.3 用户体验
- 优化启动速度
- 添加使用教程
- 改进错误提示

## 九、技术支持

如遇到问题，请检查：
1. Android SDK/NDK 版本是否正确
2. USB 设备权限是否已授予
3. 摄像头是否正确连接
4. 日志输出中的错误信息

---

**适配完成日期：** 2026-04-05
**适配版本：** Foxus Quest1 v1.1
**目标设备：** Oculus Quest 1 + 大疆 Action 2