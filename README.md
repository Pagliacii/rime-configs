# Rime configs

我的跨平台 Rime 配置，主方案为 [雾凇拼音](https://github.com/iDvel/rime-ice) 的小鹤双拼。

## 自动安装

需要 Git；Windows 还需要 Git Bash。

Windows（小狼毫）：

```powershell
git clone https://github.com/Pagliacii/rime-configs.git
cd rime-configs
.\install.ps1
```

自定义用户目录：

```powershell
.\install.ps1 -Target 'D:\RimeUser'
```

macOS（鼠须管）或 Linux（Fcitx5/IBus）：

```sh
git clone https://github.com/Pagliacii/rime-configs.git
cd rime-configs
./install.sh
```

可用 `./install.sh --target /path/to/rime` 指定用户目录。脚本通过 Plum 安装 `rime-ice.version` 固定的雾凇版本，再覆盖通用配置；Windows 额外安装 `weasel/` 中的皮肤。以后重复运行同一脚本即可更新或恢复配置。

## 目录

- `common/`：跨平台补丁。
- `weasel/`：Windows 小狼毫皮肤与应用设置。
- `legacy/`：保留的朙月简拼、Emoji 和粤拼方案。
- `install.ps1`、`install.sh`：安装雾凇及上述配置。

## 隐私

仓库不保存用户词库、同步数据、构建产物、安装标识、个人短语或本地缓存。安装时若已有 `custom_phrase.txt`，脚本会临时备份并在 Plum 结束后原样恢复。
