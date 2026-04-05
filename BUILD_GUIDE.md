# Foxus Quest1 构建与部署指南

## 环境准备

### 1. 开发环境要求
- **操作系统：** Linux (Ubuntu 20.04+) 或 macOS (Intel芯片)
- **Java：** JDK 11 或更高版本
- **Python：** Python 3.6+
- **Git：** 最新版本

### 2. 依赖工具安装

#### 2.1 安装 SCons
```bash
pip install scons
```

#### 2.2 安装 Android SDK 和 NDK
```bash
# 下载 Android SDK
wget https://dl.google.com/android/repository/commandlinetools-linux-9477386_latest.zip
unzip commandlinetools-linux-9477386_latest.zip
mkdir -p ~/Android/sdk/cmdline-tools/latest
mv cmdline-tools/* ~/Android/sdk/cmdline-tools/latest/

# 设置环境变量
export ANDROID_SDK_ROOT=$HOME/Android/Sdk
export ANDROID_NDK_ROOT=$ANDROID_SDK_ROOT/ndk/23.2.8568313
export PATH=$PATH:$ANDROID_SDK_ROOT/cmdline-tools/latest/bin
```

#### 2.3 安装 Android NDK 23.2.x
```bash
# 使用 SDK Manager 安装 NDK
sdkmanager "ndk;23.2.8568313"

# 验证安装
ls -la $ANDROID_NDK_ROOT
```

### 3. Godot 引擎依赖
按照 [Godot 官方文档](https://docs.godotengine.org/en/stable/development/compiling/) 安装必要的构建依赖。

## 构建步骤

### 步骤 1: 构建 Godot 引擎
```bash
cd /home/admin/workspace/foxus

# 构建 Godot 引擎（包括编辑器和 Android 版本）
./build_godot.sh

# 可选：构建调试版本
./build_godot.sh --debug

# 可选：启用性能分析
./build_godot.sh --profiler
```

**预期输出：**
- Godot 编辑器可执行文件：`godot/bin/godot.x11.tools.x86_64`
- Android 模板：`godot/bin/android_source.zip`

### 步骤 2: 构建 Foxus 原生模块
```bash
cd /home/admin/workspace/foxus

# 构建 Foxus 原生模块和 Android 插件
./build.sh

# 可选：构建调试版本
./build.sh --debug

# 可选：启用性能分析
./build.sh --profiler
```

**预期输出：**
- Linux 库：`foxus/addons/gd_eiffelcam/linux/libgd_eiffelcam.so`
- Android 库：`foxus/android/plugins/EiffelCamera/libs/arm64-v8a/libgd_eiffelcam.so`
- Android AAR：`foxus/android/plugins/EiffelCamera/release/*.aar`

### 步骤 3: 导出 APK
```bash
cd /home/admin/workspace/foxus

# 使用 Godot 编辑器导出（推荐）
./run_editor.sh

# 或直接使用构建脚本导出
./build_apk.sh
```

**预期输出：**
- APK 文件：`foxus/Foxus Quest1.apk`

## 部署到 Oculus Quest 1

### 前置条件
1. 确保 Quest 1 已开启开发者模式
2. 启用 USB 调试
3. 安装 ADB 工具

### 方法 1: 通过 USB 连接
```bash
# 1. 通过 USB 连接 Quest 1
adb devices

# 2. 安装 APK
adb install "Foxus Quest1.apk"

# 3. 启动应用
adb shell am start -n com.foxus.quest1/com.godot.game.GodotApp
```

### 方法 2: 通过 ADB over WiFi
```bash
# 1. 获取 Quest 1 的 IP 地址（在设备设置中查看）
# 2. 连接到设备
adb connect <QUEST_IP>:5555

# 3. 安装 APK
adb install "Foxus Quest1.apk"

# 4. 断开 WiFi 连接（可选）
adb disconnect
```

### 方法 3: 侧载 APK
1. 将 APK 文件复制到 Quest 1 的存储中
2. 使用文件管理器打开 APK 文件
3. 按照提示安装

## 连接大疆 Action 2 摄像头

### 1. 准备大疆 Action 2
1. 确保 Action 2 已充满电
2. 进入设置，启用 USB 网络摄像头模式
3. 使用 USB-C 线连接 Action 2 和 Quest 1

### 2. 在 Quest 1 上授权
1. 启动 Foxus 应用
2. 应用会自动检测摄像头
3. 点击"请求权限"按钮
4. 在弹出的权限对话框中选择"允许"

### 3. 验证连接
- 如果连接成功，状态显示为"已就绪"（绿色）
- 如果连接失败，检查 USB 线和摄像头设置

## 调试与故障排除

### 1. 查看 Android 日志
```bash
# 实时查看日志
adb logcat | grep -E "Foxus|EiffelCamera|Godot"

# 保存日志到文件
adb logcat > foxus_debug.log
```

### 2. 常见问题

#### 问题 1: APK 安装失败
**症状：** `INSTALL_FAILED_UPDATE_INCOMPATIBLE`

**解决方案：**
```bash
# 卸载旧版本
adb uninstall com.foxus.quest

# 重新安装新版本
adb install "Foxus Quest1.apk"
```

#### 问题 2: 摄像头无法连接
**症状：** 状态显示"未连接"

**解决方案：**
1. 检查 USB 线是否支持 OTG
2. 确认 Action 2 已启用 USB 网络摄像头模式
3. 尝试重新插拔 USB 线
4. 重启 Quest 1 设备

#### 问题 3: 画面延迟过高
**症状：** 画面卡顿或延迟明显

**解决方案：**
1. 降低视频分辨率（修改 `gd_eiffelcam.cpp` 中的 `streamWidth` 和 `streamHeight`）
2. 减少帧率（修改 `streamFps`）
3. 关闭其他后台应用
4. 使用性能分析工具检查瓶颈

#### 问题 4: 构建失败
**症状：** 编译错误或链接错误

**解决方案：**
1. 检查 Android SDK/NDK 版本是否正确
2. 确保所有依赖已安装
3. 清理构建缓存：
```bash
cd /home/admin/workspace/foxus/gd_eiffelcam
scons -c
```

### 3. 性能分析

#### 使用 Perfetto 进行性能分析
```bash
# 1. 启用性能分析重新构建
./build_godot.sh --profiler
./build.sh --profiler

# 2. 导出性能分析版本的 APK
./run_editor.sh  # 在编辑器中导出 release 模式

# 3. 运行性能分析
cd /home/admin/workspace/foxus
python3 perfetto.py

# 4. 分析结果
# 使用 Perfetto UI 打开生成的 trace 文件
```

## 性能基准

### 目标性能指标
| 指标 | 目标值 | 说明 |
|------|--------|------|
| 帧率 | 30 FPS | 1080P 视频流 |
| 延迟 | < 100ms | 从采集到显示 |
| 内存 | < 2GB | 总内存占用 |
| CPU | < 80% | 平均 CPU 使用率 |
| GPU | < 70% | 平均 GPU 使用率 |

### 性能优化建议
1. 如果帧率低于目标，考虑降低分辨率
2. 如果延迟过高，检查 OpenCV 处理流程
3. 如果内存占用过高，减少 `frame_array_size`
4. 如果 CPU 使用率过高，进一步减少 OpenCV 线程数

## 版本信息

### 当前版本
- **版本号：** 1.1
- **包名：** com.foxus.quest1
- **目标设备：** Oculus Quest 1
- **目标摄像头：** 大疆 Action 2
- **Android 版本：** 10 (API 29)

### 版本历史
- v1.1 (2026-04-05): Quest1 适配版本
  - 适配大疆 Action 2 摄像头
  - 优化 Quest 1 性能
  - 添加中文语言支持
- v1.0: 原始 Quest 2 版本

## 维护与更新

### 代码更新
```bash
# 拉取最新代码
cd /home/admin/workspace/foxus
git pull

# 重新构建
./build_godot.sh
./build.sh

# 导出新的 APK
./build_apk.sh
```

### 语言文件更新
1. 编辑 `foxus/locales/` 下的 JSON 文件
2. 重启应用即可生效

### 摄像头参数调整
1. 编辑 `gd_eiffelcam/src/gd_eiffelcam.cpp`
2. 修改 `vid`、`pid`、`streamWidth`、`streamHeight`、`streamFps`
3. 重新构建：
```bash
cd /home/admin/workspace/foxus
./build.sh
./build_apk.sh
```

## 技术支持

### 获取帮助
- 查看项目 README：`/home/admin/workspace/foxus/README.md`
- 查看适配方案：`/home/admin/workspace/foxus/ADAPTATION_PLAN.md`
- 查看构建日志：`build.log`

### 联系方式
- 项目主页：https://foxus.com
- 技术支持：https://www.foxus.com/pages/contact

---

**文档版本：** 1.0
**最后更新：** 2026-04-05
**维护者：** Foxus 开发团队