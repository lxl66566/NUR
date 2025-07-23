#!/usr/bin/env nix-shell
#!nix-shell -i bash -p curl jq nix-prefetch

# 当任何命令失败时立即退出
set -e

# 配置
PNAME=$1
REPO="lxl66566/$PNAME"
OUTPUT_FILE="source-info.nix"

echo "正在从 GitHub API 获取最新的版本号..."

# 1. 获取最新的版本号 (例如 "1.5.0")
LATEST_VERSION=$(curl --silent "https://api.github.com/repos/$REPO/releases/latest" | jq -r .tag_name | sed 's/^v//')

if [ -z "$LATEST_VERSION" ]; then
    echo "错误：无法获取最新的版本号。请检查仓库名称和网络连接。"
    exit 1
fi

echo "找到最新版本: ${LATEST_VERSION}"

# 2. 定义一个函数来预取文件的哈希值
prefetch_hash() {
    local target_system=$1
    local url="https://github.com/$REPO/releases/download/v${LATEST_VERSION}/${PNAME}-${target_system}.tar.gz"
    # 使用 nix-prefetch-url 获取文件的哈希值
    nix-prefetch-url "$url"
}

# 3. 为所有平台分别获取哈希
HASH_X86_64_GNU=$(prefetch_hash "x86_64-unknown-linux-gnu")
HASH_X86_64_MUSL=$(prefetch_hash "x86_64-unknown-linux-musl")
HASH_AARCH64_GNU=$(prefetch_hash "aarch64-unknown-linux-gnu")
HASH_AARCH64_MUSL=$(prefetch_hash "aarch64-unknown-linux-musl")

echo "所有哈希值已成功获取。"
echo "正在生成 ${OUTPUT_FILE}..."

# 4. 使用heredoc语法将版本和哈希写入 Nix 文件
cat > "$OUTPUT_FILE" <<EOF
# 此文件由 ./update.sh 自动生成，请勿手动编辑。
{
  version = "${LATEST_VERSION}";
  hashes = {
    x86_64-linux = {
      gnu = {
        targetSystem = "x86_64-unknown-linux-gnu";
        sha256 = "${HASH_X86_64_GNU}";
      };
      musl = {
        targetSystem = "x86_64-unknown-linux-musl";
        sha256 = "${HASH_X86_64_MUSL}";
      };
    };
    aarch64-linux = {
      gnu = {
        targetSystem = "aarch64-unknown-linux-gnu";
        sha256 = "${HASH_AARCH64_GNU}";
      };
      musl = {
        targetSystem = "aarch64-unknown-linux-musl";
        sha256 = "${HASH_AARCH64_MUSL}";
      };
    };
  };
}
EOF

echo "✅ 更新完成！ ${OUTPUT_FILE} 已更新至版本 ${LATEST_VERSION}。"