#!/usr/bin/env node
/**
 * Subgraph 配置更新脚本
 * 从 deployments/localhost.json 读取合约地址并更新 subgraph.yaml
 *
 * 使用方法:
 *   node config/update-config.js ../contracts/deployments/localhost.json
 */

const fs = require('fs');
const path = require('path');

// 读取命令行参数
const deploymentFile = process.argv[2];
if (!deploymentFile) {
  console.error('❌ Usage: node update-config.js <deployment-file>');
  console.error('   Example: node config/update-config.js ../contracts/deployments/localhost.json');
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

console.log('\n📝 Updating Subgraph configuration...');
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

// 替换变量
const config = template
  .replace(/{{FACTORY_ADDRESS}}/g, deployment.contracts.factory)
  .replace(/{{FEE_ROUTER_ADDRESS}}/g, deployment.contracts.feeRouter)
  .replace(/{{START_BLOCK}}/g, startBlock.toString());

// 写入最终配置
const outputPath = path.join(__dirname, '../subgraph.yaml');
fs.writeFileSync(outputPath, config);

console.log('\n✅ Subgraph config updated successfully!');
console.log(`  Factory: ${deployment.contracts.factory}`);
console.log(`  FeeRouter: ${deployment.contracts.feeRouter}`);
console.log(`  StartBlock: ${deployment.deployedAt}`);
console.log(`  Output: ${outputPath}\n`);
