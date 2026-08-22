# venv 真正独立（Termux）

**问题**：Termux 默认 `python3 -m venv` 创建的 venv，其 Python 是符号链接到系统 Python 的。`pkg upgrade` 后系统 Python 升到 3.14+，venv 立即崩溃。

**用户要求**：venv 应该是独立 Python 环境，不能依赖系统 Python。

## 解决方案：复制二进制+库

```bash
# 1. 删除符号链接，复制真正的二进制
cd ~/hermes-agent/venv/bin
rm -f python python3 python3.13
cp /data/data/com.termux/files/usr/bin/python3.13 ~/hermes-agent/venv/bin/python3.13
ln -sf python3.13 ~/hermes-agent/venv/bin/python3
ln -sf python3 ~/hermes-agent/venv/bin/python

# 2. 复制共享库
mkdir -p ~/hermes-agent/venv/lib
cp /data/data/com.termux/files/usr/lib/libpython3.13.so ~/hermes-agent/venv/lib/

# 3. 修复 pyvenv.cfg
cat > ~/hermes-agent/venv/pyvenv.cfg << 'EOF'
home = /data/data/com.termux/files/usr/bin
implementation = CPython
version_info = 3.13.12
include-system-site-packages = false
EOF
```

## 验证

```bash
# 检查 venv 独立性
ls -la ~/hermes-agent/venv/bin/python*
# python3.13 应该是真实文件（不是符号链接）

# 检查 hermes 运行
hermes --version
```

## 重建 venv 的完整流程

```bash
cd ~/hermes-agent
rm -rf venv
python3 -m venv --without-pip venv
source venv/bin/activate
curl -sS https://bootstrap.pypa.io/get-pip.py | python3
pip install -e ".[termux-all]"
# 如果 psutil 编译失败：
# pip install -e . --no-deps
```

## Pitfalls

1. **`ensurepip` 失败**：Termux 上 `python3 -m venv` 经常因 ensurepip 失败，用 `--without-pip` + `get-pip.py`
2. **psutil 编译失败**：Android 平台标记不支持，用 `--no-deps` 安装（系统已有 psutil）
3. **依赖丢失**：重建 venv 后所有 pip 包需要重新安装
4. **PYTHONPATH 污染**：不要设置 PYTHONPATH 指向系统 Python 的 stdlib，会导致编码错误

## 相关 GitHub Issues

- [#58576](https://github.com/NousResearch/hermes-agent/issues/58576) — GIL pressure event loop stall
- [#57921](https://github.com/NousResearch/hermes-agent/issues/57921) — SQLite database locked under GIL pressure
- [#74554](https://github.com/NousResearch/hermes-agent/issues/74554) — ARM64 Docker image ships x86_64 wheels
