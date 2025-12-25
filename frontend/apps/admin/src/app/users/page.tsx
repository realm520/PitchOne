'use client';

import { useState, useMemo } from 'react';
import { useChainId, useAccount } from '@pitchone/web3';
import { Button, Card, LoadingSpinner } from '@pitchone/ui';
import { getContractAddresses } from '@pitchone/contracts';
import { ROLES } from '@/constants/roles';
import { PageHeader } from '@/components/PageHeader';
import { AddUserModal } from './components/AddUserModal';
import { EditUserModal } from './components/EditUserModal';
import { DeleteUserModal } from './components/DeleteUserModal';
import { useAdmins, Admin, adminToRoleHashes, hasAnyRole } from '@/hooks/useAdmins';
import { useHasRole } from '@/hooks/useHasRole';

// DEFAULT_ADMIN_ROLE hash
const DEFAULT_ADMIN_ROLE = '0x0000000000000000000000000000000000000000000000000000000000000000' as `0x${string}`;

export default function UsersPage() {
    const chainId = useChainId();
    const { address: currentUserAddress, isConnected } = useAccount();
    const addresses = getContractAddresses(chainId);
    const factoryAddress = addresses.factory;

    // 检查当前用户是否有 Admin 权限
    const { data: hasAdminRole, isLoading: isCheckingRole } = useHasRole(
        factoryAddress,
        DEFAULT_ADMIN_ROLE,
        currentUserAddress || '0x0000000000000000000000000000000000000000'
    );

    // 是否有权限管理用户
    const canManageUsers = isConnected && hasAdminRole === true;

    // 从 Subgraph 获取管理员列表
    const { data: admins, isLoading, error, refetch } = useAdmins(100, 0);

    // 添加用户弹窗状态
    const [isAddModalOpen, setIsAddModalOpen] = useState(false);

    // 编辑用户弹窗状态
    const [editModalState, setEditModalState] = useState<{
        isOpen: boolean;
        address: `0x${string}`;
        currentRoles: `0x${string}`[];
    } | null>(null);

    // 删除用户弹窗状态
    const [deleteModalState, setDeleteModalState] = useState<{
        isOpen: boolean;
        address: `0x${string}`;
        currentRoles: `0x${string}`[];
    } | null>(null);

    // 筛选：只显示拥有至少一个角色的管理员
    const activeAdmins = useMemo(() => {
        return admins.filter(hasAnyRole);
    }, [admins]);

    const handleOpenEditModal = (address: `0x${string}`, currentRoles: `0x${string}`[]) => {
        setEditModalState({ isOpen: true, address, currentRoles });
    };

    const handleOpenDeleteModal = (address: `0x${string}`, currentRoles: `0x${string}`[]) => {
        setDeleteModalState({ isOpen: true, address, currentRoles });
    };

    // 角色变更成功后刷新数据
    const handleSuccess = () => {
        // 延迟刷新，等待 Subgraph 索引完成
        setTimeout(() => {
            refetch();
        }, 3000);
    };

    return (
        <div className="min-h-screen bg-gray-50 dark:bg-gray-900">
            <PageHeader
                title="用户权限管理"
                description="管理 MarketFactory 合约的用户角色和权限（数据来自 Subgraph）"
            />

            {/* Main Content */}
            <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
                {/* 合约地址信息 */}
                <div className="mb-6 p-4 bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800 rounded-lg">
                    <p className="text-sm text-blue-800 dark:text-blue-200">
                        <span className="font-medium">MarketFactory 合约:</span>{' '}
                        <span className="font-mono">{factoryAddress}</span>
                        <span className="ml-4 text-blue-600 dark:text-blue-400">Chain ID: {chainId}</span>
                    </p>
                </div>

                {/* 权限提示 */}
                {!isConnected && (
                    <div className="mb-6 p-4 bg-yellow-50 dark:bg-yellow-900/20 border border-yellow-200 dark:border-yellow-800 rounded-lg">
                        <p className="text-sm text-yellow-800 dark:text-yellow-200">
                            请先连接钱包以管理用户权限
                        </p>
                    </div>
                )}
                {isConnected && !isCheckingRole && !canManageUsers && (
                    <div className="mb-6 p-4 bg-yellow-50 dark:bg-yellow-900/20 border border-yellow-200 dark:border-yellow-800 rounded-lg">
                        <p className="text-sm text-yellow-800 dark:text-yellow-200">
                            当前账户没有管理员权限，无法添加或修改用户
                        </p>
                        <p className="text-xs text-yellow-600 dark:text-yellow-400 mt-1">
                            当前地址: {currentUserAddress?.slice(0, 6)}...{currentUserAddress?.slice(-4)}
                        </p>
                    </div>
                )}

                {/* 添加用户按钮 */}
                <div className="mb-6 flex gap-3">
                    <Button
                        onClick={() => setIsAddModalOpen(true)}
                        variant="primary"
                        disabled={!canManageUsers || isCheckingRole}
                        title={!canManageUsers ? '需要管理员权限' : undefined}
                    >
                        {isCheckingRole ? '检查权限...' : '添加用户'}
                    </Button>
                    <Button onClick={() => refetch()} variant="ghost">
                        刷新数据
                    </Button>
                </div>

                {/* 角色说明 */}
                <div className="mb-6 flex flex-wrap gap-3">
                    {ROLES.map((role) => (
                        <div key={role.name} className="flex items-center gap-2">
                            <span className={`px-2 py-0.5 rounded text-xs font-medium ${role.color}`}>
                                {role.label}
                            </span>
                            <span className="text-xs text-gray-500 dark:text-gray-400">{role.description}</span>
                        </div>
                    ))}
                </div>

                {/* 错误提示 */}
                {error && (
                    <div className="mb-6 p-4 bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg">
                        <p className="text-sm text-red-600 dark:text-red-400">
                            加载数据失败: {error.message}
                        </p>
                        <p className="text-xs text-red-500 dark:text-red-400 mt-1">
                            请确保 Subgraph 已部署并正在运行
                        </p>
                    </div>
                )}

                {/* 用户列表 */}
                <Card className="overflow-hidden">
                    <table className="w-full">
                        <thead className="bg-gray-50 dark:bg-gray-700/50 border-b dark:border-gray-700">
                            <tr>
                                <th className="py-3 px-4 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                                    钱包地址
                                </th>
                                <th className="py-3 px-4 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                                    角色
                                </th>
                                <th className="py-3 px-4 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                                    操作
                                </th>
                            </tr>
                        </thead>
                        <tbody>
                            {isLoading ? (
                                <tr>
                                    <td colSpan={3} className="py-8 text-center">
                                        <div className="flex items-center justify-center gap-2">
                                            <LoadingSpinner size="sm" />
                                            <span className="text-gray-500 dark:text-gray-400">加载中...</span>
                                        </div>
                                    </td>
                                </tr>
                            ) : activeAdmins.length > 0 ? (
                                activeAdmins.map((admin) => (
                                    <UserRowFromSubgraph
                                        key={admin.id}
                                        admin={admin}
                                        factoryAddress={factoryAddress}
                                        onEdit={handleOpenEditModal}
                                        onDelete={handleOpenDeleteModal}
                                        canManageUsers={canManageUsers}
                                    />
                                ))
                            ) : (
                                <tr>
                                    <td colSpan={3} className="py-8 text-center text-gray-500 dark:text-gray-400">
                                        暂无拥有角色的用户
                                    </td>
                                </tr>
                            )}
                        </tbody>
                    </table>
                </Card>

                {/* 统计信息 */}
                <div className="mt-4 text-sm text-gray-500 dark:text-gray-400">
                    共 {activeAdmins.length} 个拥有角色的用户
                </div>
            </div>

            {/* 添加用户弹窗 */}
            <AddUserModal
                isOpen={isAddModalOpen}
                onClose={() => setIsAddModalOpen(false)}
                factoryAddress={factoryAddress}
                onSuccess={handleSuccess}
            />

            {/* 编辑用户弹窗 */}
            {editModalState && (
                <EditUserModal
                    isOpen={editModalState.isOpen}
                    onClose={() => setEditModalState(null)}
                    address={editModalState.address}
                    currentRoles={editModalState.currentRoles}
                    factoryAddress={factoryAddress}
                    onSuccess={handleSuccess}
                />
            )}

            {/* 删除用户弹窗 */}
            {deleteModalState && (
                <DeleteUserModal
                    isOpen={deleteModalState.isOpen}
                    onClose={() => setDeleteModalState(null)}
                    address={deleteModalState.address}
                    currentRoles={deleteModalState.currentRoles}
                    factoryAddress={factoryAddress}
                    onSuccess={handleSuccess}
                />
            )}
        </div>
    );
}

// 从 Subgraph 数据渲染用户行
function UserRowFromSubgraph({
    admin,
    factoryAddress,
    onEdit,
    onDelete,
    canManageUsers,
}: {
    admin: Admin;
    factoryAddress: `0x${string}`;
    onEdit: (address: `0x${string}`, currentRoles: `0x${string}`[]) => void;
    onDelete: (address: `0x${string}`, currentRoles: `0x${string}`[]) => void;
    canManageUsers: boolean;
}) {
    const address = admin.id as `0x${string}`;
    const userRoleHashes = adminToRoleHashes(admin);
    const userRoles = ROLES.filter((role) => userRoleHashes.includes(role.hash));

    const handleEdit = () => {
        onEdit(address, userRoleHashes);
    };

    const handleDelete = () => {
        onDelete(address, userRoleHashes);
    };

    return (
        <tr className="hover:bg-gray-50 dark:hover:bg-gray-800 border-b dark:border-gray-700">
            <td className="py-4 px-4">
                <div className="flex items-center">
                    <span className="font-mono text-sm text-gray-900 dark:text-white">
                        {address.slice(0, 6)}...{address.slice(-4)}
                    </span>
                    <button
                        onClick={() => navigator.clipboard.writeText(address)}
                        className="ml-2 text-gray-400 hover:text-gray-600 dark:hover:text-gray-300"
                        title="复制地址"
                    >
                        <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2v-8a2 2 0 00-2-2h-8a2 2 0 00-2 2v8a2 2 0 002 2z" />
                        </svg>
                    </button>
                </div>
            </td>
            <td className="py-4 px-4">
                {userRoles.length > 0 ? (
                    <div className="flex flex-wrap gap-1">
                        {userRoles.map((role) => (
                            <span
                                key={role.name}
                                className={`px-2 py-0.5 rounded text-xs font-medium ${role.color}`}
                            >
                                {role.label}
                            </span>
                        ))}
                    </div>
                ) : (
                    <span className="text-gray-400 text-sm">无角色</span>
                )}
            </td>
            <td className="py-4 px-4">
                <div className="flex items-center gap-2">
                    <button
                        onClick={handleEdit}
                        disabled={!canManageUsers}
                        className={`flex items-center gap-1 text-sm px-2 py-1 border dark:border-gray-600 rounded bg-white dark:bg-gray-700 text-gray-900 dark:text-white ${canManageUsers ? 'hover:bg-gray-50 dark:hover:bg-gray-600' : 'opacity-50 cursor-not-allowed'}`}
                        title={canManageUsers ? '编辑角色' : '需要管理员权限'}
                    >
                        <svg className="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15.232 5.232l3.536 3.536m-2.036-5.036a2.5 2.5 0 113.536 3.536L6.5 21.036H3v-3.572L16.732 3.732z" />
                        </svg>
                        编辑
                    </button>
                    <button
                        onClick={handleDelete}
                        disabled={!canManageUsers}
                        className={`flex items-center gap-1 text-sm px-2 py-1 border border-red-300 dark:border-red-700 rounded bg-white dark:bg-gray-700 text-red-600 dark:text-red-400 ${canManageUsers ? 'hover:bg-red-50 dark:hover:bg-red-900/20' : 'opacity-50 cursor-not-allowed'}`}
                        title={canManageUsers ? '删除用户' : '需要管理员权限'}
                    >
                        <svg className="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                        </svg>
                        删除
                    </button>
                </div>
            </td>
        </tr>
    );
}
