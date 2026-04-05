# GitHub Actions 构建说明

## 使用 GitHub Actions 构建 APK

本项目已配置 GitHub Actions 自动构建流程，可以自动生成适配 Quest 1 的 APK 文件。

### 触发构建

构建会在以下情况下自动触发：

1. **推送到主分支**
   ```bash
   git add .
   git commit -m "提交适配修改"
   git push origin main
   ```

2. **创建 Pull Request**
   - 向 `main` 或 `master` 分支创建 PR 时会自动构建

3. **手动触发**
   - 访问 GitHub 仓库的 Actions 页面
   - 选择 "Build Foxus Quest1 APK" 工作流
   - 点击 "Run workflow" 按钮

### 构建步骤

GitHub Actions 会自动执行以下步骤：

1. **环境准备**
   - 设置 Python 3.10
   - 安装 SCons 4.10.1
   - 设置 Java 17
   - 安装 Android SDK 和 NDK 23.2.8568313
   - 安装系统依赖

2. **编译 Godot 引擎**
   - 使用 SCons 编译 Android 版本

3. **编译 Foxus 原生模块**
   - 编译 EiffelCam 摄像头驱动
   - 生成 ARM64-v8a 架构的 .so 文件

4. **构建 Android 插件**
   - 使用 Gradle 编译 EiffelCamera 插件

5. **导出 APK**
   - 生成最终的 APK 文件

6. **上传构建产物**
   - APK 文件会作为构建产物上传
   - 保留 30 天供下载

### 下载 APK

构建完成后，可以通过以下方式下载 APK：

1. **GitHub Actions 页面**
   - 访问仓库的 Actions 页面
   - 找到成功的构建记录
   - 在 "Artifacts" 部分下载 `foxus-quest1-apk`

2. **命令行下载**
   ```bash
   # 使用 gh CLI 工具
   gh run download <run-id>
   ```

### 构建产物

构建成功后会生成以下文件：

- `foxus-quest1-apk.zip` - 包含 APK 文件的压缩包
- `build-logs` (仅构建失败时) - 构建日志

### APK 特性

生成的 APK 包含以下特性：

- ✅ 适配 Oculus Quest 1 (Android 10)
- ✅ 支持大疆 Action 2 摄像头 (VID:0x2CA3, PID:0x0021)
- ✅ 1920x1080 @ 30fps 视频流
- ✅ 针对骁龙 835 性能优化
- ✅ 中英文语言支持
- ✅ 低延迟彩色透视功能

### 构建时间

- 首次构建：约 30-45 分钟
- 缓存命中：约 10-15 分钟

### 故障排查

如果构建失败，请检查：

1. **查看构建日志**
   - 在 Actions 页面点击失败的构建记录
   - 查看详细的错误信息

2. **常见问题**
   - 依赖安装失败：检查网络连接
   - 编译错误：检查代码修改是否正确
   - 内存不足：GitHub Actions 有内存限制

3. **本地测试**
   - 在本地环境测试构建脚本
   - 参考 `BUILD_GUIDE.md` 中的步骤

### 自定义构建

如需自定义构建参数，可以修改 `.github/workflows/build-apk.yml` 文件：

```yaml
# 修改构建模式
scons -j4 platform=android target=release_debug

# 修改 NDK 版本
sdkmanager "ndk;23.2.8568313"

# 修改并行编译数
scons -j8
```

### 许可证

构建过程需要接受 Android SDK 许可证，已在工作流中自动处理。

---

**注意：** 首次构建可能需要较长时间，后续构建会使用缓存加速。