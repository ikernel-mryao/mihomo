# Mihomo Linux 命令行代理仓库

这是一个面向 Linux 终端环境的 Mihomo 启动目录，适合放到服务器、虚拟机或本地开发机上直接使用。

仓库只保存脚本和说明，**不会上传你的个人订阅配置**。你需要自己下载明文 Clash/Mihomo YAML 配置，并保存为 `config/config.yaml`。

## 仓库内容

- `install-mihomo.sh`：下载 Mihomo 内核到 `run/`
- `start-mihomo.sh`：按当前架构选择可运行内核，生成运行时配置副本并后台启动
- `stop-mihomo.sh`：停止当前目录启动的 Mihomo 进程
- `restart-mihomo.sh`：重启 Mihomo
- `status-mihomo.sh`：查看当前运行状态
- `enable-proxy.sh`：为当前 shell 设置代理环境变量
- `disable-proxy.sh`：取消当前 shell 的代理环境变量
- `common.sh`：脚本共用函数

## 不会上传到 GitHub 的内容

`.gitignore` 已排除以下内容：

- `config/*.yaml`
- `config/*.dat`
- `config/*.mmdb`
- `downloads/`
- `run/`
- `nohup.out`

也就是说，**`config/config.yaml` 不会提交到 GitHub**。换机器时，请重新下载你自己的配置文件。

## 前提要求

目标机器需要：

1. Linux
2. `bash`
3. `curl`
4. `gzip`
5. 架构为 `x86_64/amd64` 或 `aarch64/arm64`

## 第一次使用

```bash
cd /path/to/mihomo
chmod +x *.sh
./install-mihomo.sh
mkdir -p config
# 把你自己下载的明文 Clash/Mihomo 配置保存为:
# config/config.yaml
./start-mihomo.sh
```

如果你想一次准备两种架构的内核，便于拷到别的 Linux 机器：

```bash
./install-mihomo.sh --all
```

## 配置文件要求

你必须自己从机场/订阅服务后台下载 **明文 YAML 配置**，保存为：

```bash
config/config.yaml
```

注意：

- 订阅链接返回的加密内容，不能直接给 Mihomo 使用
- 本仓库不会提供任何个人节点信息
- 配置文件由你自己保管，不要提交到公共仓库

## 启动、停止、重启

启动：

```bash
./start-mihomo.sh
```

启动成功后会输出：

- 进程 PID
- 监听端口
- 原始配置路径
- 运行时配置路径
- 日志路径

停止：

```bash
./stop-mihomo.sh
```

如果进程是其他用户或 root 启动的，可以用：

```bash
./stop-mihomo.sh --sudo
```

重启：

```bash
./restart-mihomo.sh
```

查看状态：

```bash
./status-mihomo.sh
```

查看日志：

```bash
tail -f run/mihomo.log
```

## 为当前终端启用或关闭代理

启用代理：

```bash
source ./enable-proxy.sh
```

说明：

- 这里必须用 `source`，这样代理环境变量才会留在当前 shell
- `enable-proxy.sh` 和 `disable-proxy.sh` 不会修改你当前 shell 的 `set -e` / `set -u` 行为，避免 source 后把终端会话带崩

关闭代理：

```bash
source ./disable-proxy.sh
```

脚本会根据当前配置中的 `mixed-port` 自动设置以下环境变量：

- `http_proxy`
- `https_proxy`
- `HTTP_PROXY`
- `HTTPS_PROXY`
- `all_proxy`
- `ALL_PROXY`

## 推荐使用流程

```bash
cd /path/to/mihomo
./start-mihomo.sh
source ./enable-proxy.sh
curl https://api.ipify.org
```

不用时：

```bash
source ./disable-proxy.sh
./stop-mihomo.sh
```

## 验证当前 Mihomo 代理是否可用

执行下面这条命令：

```bash
source ./enable-proxy.sh && curl -sS https://api.ipify.org && echo && curl -I -sS https://api.anthropic.com | head -n 5
```

判断方式：

1. 第一段会输出一个公网 IP，说明请求已经经由当前代理出站
2. 第二段如果返回 `HTTP/2 404` 或其他正常的 HTTP 响应头，说明到 Anthropic 的网络链路已经打通
3. 如果出现连接失败、超时或无法解析域名，再检查 `./status-mihomo.sh`、节点状态和本地网络限制

## 兼容性说明

这个仓库已经处理了两类常见问题：

1. **架构不匹配**：启动脚本会优先选择当前机器能运行的 Mihomo 内核，不再盲目执行错误架构的 `run/mihomo`
2. **配置兼容问题**：启动时会生成 `run/config.runtime.yaml` 作为运行时副本，避免直接改动你的原始 `config/config.yaml`

如果你的订阅配置里包含某些与当前 `GeoIP.dat` 不兼容的规则，脚本会优先使用运行时副本，避免污染原配置。

## 常见排查

### 1. 启动失败，提示找不到配置

确认以下文件存在且非空：

```bash
ls -l config/config.yaml
```

### 2. 启动后不能联网

按顺序检查：

1. `./status-mihomo.sh` 是否显示进程在运行
2. `source ./enable-proxy.sh` 是否已执行
3. `mixed-port` 是否与本地端口一致
4. 节点是否过期
5. 目标网络是否拦截相关出站连接

### 3. 想在另一台机器复用

只需要带上仓库脚本，然后在目标机重新执行：

```bash
./install-mihomo.sh
```

再把你自己的配置文件放到：

```bash
config/config.yaml
```

之后执行：

```bash
./start-mihomo.sh
source ./enable-proxy.sh
```
