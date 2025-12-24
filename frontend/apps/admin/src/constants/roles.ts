import { keccak256, toBytes } from 'viem';

// 角色定义
export const ROLES = [
    {
        name: 'DEFAULT_ADMIN_ROLE',
        hash: '0x0000000000000000000000000000000000000000000000000000000000000000' as `0x${string}`,
        label: '超级管理员',
        description: '可以授予和撤销所有角色',
        color: 'bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-200',
    },
    {
        name: 'OPERATOR_ROLE',
        hash: keccak256(toBytes('OPERATOR_ROLE')) as `0x${string}`,
        label: '运营',
        description: '可以创建市场、管理模板',
        color: 'bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-200',
    },
    {
        name: 'ROUTER_ROLE',
        hash: keccak256(toBytes('ROUTER_ROLE')) as `0x${string}`,
        label: '路由',
        description: 'BettingRouter 专用',
        color: 'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200',
    },
    {
        name: 'KEEPER_ROLE',
        hash: keccak256(toBytes('KEEPER_ROLE')) as `0x${string}`,
        label: 'Keeper',
        description: '自动化任务执行',
        color: 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-200',
    },
    {
        name: 'ORACLE_ROLE',
        hash: keccak256(toBytes('ORACLE_ROLE')) as `0x${string}`,
        label: '预言机',
        description: '提交赛果提案',
        color: 'bg-purple-100 text-purple-800 dark:bg-purple-900 dark:text-purple-200',
    },
] as const;

export type Role = (typeof ROLES)[number];
