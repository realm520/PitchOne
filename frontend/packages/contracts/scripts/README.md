# 前端合约地址自动同步脚本

## 功能说明

`update-addresses.js` 脚本用于从合约部署文件自动同步合约地址到前端配置。

## 工作原理

1. 读取 `contracts/deployments/localhost.json` 部署文件
2. 提取所有合约地址
3. 自动更新 `frontend/packages/contracts/src/addresses/index.ts`

## 使用方法

### 方式 1：通过 PostDeploy.sh（推荐）

部署合约后自动执行：

```bash
cd contracts
forge script script/Deploy.s.sol:Deploy --rpc-url http://localhost:8545 --broadcast
./script/PostDeploy.sh localhost
```

`PostDeploy.sh` 会自动：
- ✅ 更新 Subgraph 配置
- ✅ 重新部署 Subgraph
- ✅ **更新前端合约地址**（新增功能）

### 方式 2：手动执行

如果需要单独更新前端地址：

```bash
cd frontend/packages/contracts
node scripts/update-addresses.js ../../../contracts/deployments/localhost.json
```

## 输出示例

```
📝 Updating Frontend contract addresses...
  Network: localhost
  ChainId: 31337
  Timestamp: 2025-11-12

✅ Frontend addresses updated successfully!
  USDC: 0x5FbDB2315678afecb367f032d93F642f64180aa3
  Factory: 0x5FC8d32690cc91D4c39d9d3abcBD16989F875707
  Vault: 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512
  SimpleCPMM: 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0
  FeeRouter: 0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9
  ReferralRegistry: 0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9
  Output: /path/to/frontend/packages/contracts/src/addresses/index.ts
```

## 更新后操作

前端地址更新后，需要：

1. **硬刷新浏览器**（Ctrl+Shift+R 或 Cmd+Shift+R）
2. 清除 React 缓存（如果使用 Next.js，重启 `pnpm dev`）

## 支持的网络

- ✅ Anvil (localhost) - chainId 31337
- 🔜 Sepolia - chainId 11155111（待部署后配置）

## 故障排查

### 错误：部署文件未找到

```bash
❌ Deployment file not found: ...
```

**解决方法**：
1. 确认已运行 `Deploy.s.sol` 脚本
2. 检查 `contracts/deployments/localhost.json` 文件是否存在
3. 使用正确的相对路径或绝对路径

### 错误：权限不足

```bash
❌ Cannot write to file ...
```

**解决方法**：
```bash
chmod +x scripts/update-addresses.js
chmod 644 src/addresses/index.ts
```

## 相关文件

- `contracts/deployments/localhost.json` - 合约部署记录（源文件）
- `frontend/packages/contracts/src/addresses/index.ts` - 前端地址配置（目标文件）
- `contracts/script/PostDeploy.sh` - 部署后自动化脚本
- `subgraph/config/update-config.js` - Subgraph 地址同步脚本（类似实现）

## 注意事项

⚠️ **重要**：此脚本会完全覆盖 `src/addresses/index.ts` 文件，请勿手动编辑该文件，所有地址应通过部署脚本生成。

✅ **建议**：每次重新部署合约后，都应运行此脚本确保前端使用最新地址。
