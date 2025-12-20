#!/usr/bin/env node
/**
 * Subgraph 配置更新脚本 (V3 架构)
 * 从 deployments/localhost_v3.json 读取合约地址并更新 subgraph.yaml
 *
 * 支持的合约地址（4 个）:
 *   - Factory (MarketFactory_V3)
 *   - FeeRouter
 *   - LiquidityVault (LiquidityVault_V3)
 *   - ReferralRegistry
 *
 * 使用方法:
 *   node config/update-config.js ../contracts/deployments/localhost_v3.json
 */

const fs = require('fs');
const path = require('path');

// 读取命令行参数
const deploymentFile = process.argv[2];
if (!deploymentFile) {
  console.error('❌ Usage: node update-config.js <deployment-file>');
  console.error('   Example: node config/update-config.js ../contracts/deployments/localhost_v3.json');
  process.exit(1);
}

// 检查文件是否存在
if (!fs.existsSync(deploymentFile)) {
  console.error(`❌ Deployment file not found: ${deploymentFile}`);
  process.exit(1);
}

// 读取部署数据
const deployment = JSON.parse(fs.readFileSync(deploymentFile, 'utf-8'));

// 处理 deployedAt 字段（可能未定义，使用默认值 0）
const startBlock = deployment.deployedAt || 0;

console.log('\n📝 Updating Subgraph configuration (V3)...');
console.log(`  Network: ${deployment.network}`);
console.log(`  ChainId: ${deployment.chainId}`);
console.log(`  Deployed at block: ${startBlock}`);
if (!deployment.deployedAt) {
  console.log('  ⚠️  Warning: deployedAt not found in deployment file, using block 0');
}

// 读取模板文件
const templatePath = path.join(__dirname, '../subgraph.template.yaml');
if (!fs.existsSync(templatePath)) {
  console.error(`❌ Template file not found: ${templatePath}`);
  console.error('   Please create subgraph.template.yaml first');
  process.exit(1);
}

const template = fs.readFileSync(templatePath, 'utf-8');

// 提取合约地址（带默认值和验证）
const contracts = deployment.contracts || {};

const getAddress = (key, fallback = '0x0000000000000000000000000000000000000000') => {
  const addr = contracts[key];
  if (!addr || addr === 'null') {
    console.warn(`  ⚠️  Warning: ${key} not found, using fallback`);
    return fallback;
  }
  return addr;
};

// V3 架构的合约地址
const factory = getAddress('factory');
const feeRouter = getAddress('feeRouter');
const liquidityVault = getAddress('liquidityVault');
const referralRegistry = getAddress('referralRegistry');

// 替换变量（4 个地址 + 1 个区块号）
const config = template
  .replace(/{{FACTORY_ADDRESS}}/g, factory)
  .replace(/{{FEE_ROUTER_ADDRESS}}/g, feeRouter)
  .replace(/{{LIQUIDITY_VAULT_ADDRESS}}/g, liquidityVault)
  .replace(/{{REFERRAL_REGISTRY_ADDRESS}}/g, referralRegistry)
  .replace(/{{START_BLOCK}}/g, startBlock.toString());

// 写入最终配置
const outputPath = path.join(__dirname, '../subgraph.yaml');
fs.writeFileSync(outputPath, config);

console.log('\n✅ Subgraph config updated successfully!');
console.log('  Addresses:');
console.log(`    Factory:          ${factory}`);
console.log(`    FeeRouter:        ${feeRouter}`);
console.log(`    LiquidityVault:   ${liquidityVault}`);
console.log(`    ReferralRegistry: ${referralRegistry}`);
console.log(`  StartBlock: ${startBlock}`);
console.log(`  Output: ${outputPath}\n`);
