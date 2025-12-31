'use client';

import { useState, useEffect } from 'react';
import { useWriteContract, useWaitForTransactionReceipt } from '@pitchone/web3';
import { Button, LoadingSpinner } from '@pitchone/ui';
import { MarketFactory_V3_ABI } from '@pitchone/contracts';
import { ROLES } from '@/constants/roles';

// Keeper 角色哈希（与 roles.ts 中 KEEPER_ROLE 的 hash 一致）
const KEEPER_ROLE_HASH = '0xfc8737ab85eb45125971625a9ebdb75cc78e01d5c1fa80c4c6e5203f47bc4fab' as `0x${string}`;

/**
 * 根据角色获取撤销时的合约调用参数
 * - KEEPER_ROLE: 使用 removeKeeper
 * - 其他角色: 使用 revokeRole
 */
function getRevokeContractCall(roleHash: `0x${string}`, userAddress: `0x${string}`) {
    if (roleHash === KEEPER_ROLE_HASH) {
        return {
            functionName: 'removeKeeper' as const,
            args: [userAddress] as const,
        };
    } else {
        return {
            functionName: 'revokeRole' as const,
            args: [roleHash, userAddress] as const,
        };
    }
}

export interface DeleteUserModalProps {
    isOpen: boolean;
    onClose: () => void;
    address: `0x${string}`;
    currentRoles: `0x${string}`[];
    factoryAddress: `0x${string}`;
    onSuccess: () => void;
}

export function DeleteUserModal({
    isOpen,
    onClose,
    address,
    currentRoles,
    factoryAddress,
    onSuccess,
}: DeleteUserModalProps) {
    const [currentRoleIndex, setCurrentRoleIndex] = useState(0);
    const [isSubmitting, setIsSubmitting] = useState(false);

    const { writeContract, data: hash, isPending, error, reset } = useWriteContract();
    const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({ hash });

    const resetState = () => {
        setCurrentRoleIndex(0);
        setIsSubmitting(false);
        reset();
    };

    const handleClose = () => {
        resetState();
        onClose();
    };

    // 处理交易成功
    useEffect(() => {
        if (isSuccess && isSubmitting) {
            const nextIndex = currentRoleIndex + 1;
            if (nextIndex < currentRoles.length) {
                setCurrentRoleIndex(nextIndex);
                reset();
                const nextRole = currentRoles[nextIndex];
                console.log(`[DeleteUserModal] 撤销下一个角色`, {
                    address,
                    role: ROLES.find(r => r.hash === nextRole)?.name,
                    progress: `${nextIndex + 1}/${currentRoles.length}`,
                });
                const contractCall = getRevokeContractCall(nextRole, address);
                writeContract({
                    address: factoryAddress,
                    abi: MarketFactory_V3_ABI,
                    functionName: contractCall.functionName,
                    args: contractCall.args,
                });
            } else {
                console.log(`[DeleteUserModal] 删除用户成功`, {
                    address,
                    roles: currentRoles.map(h => ROLES.find(r => r.hash === h)?.name),
                });
                setTimeout(() => {
                    onSuccess();
                    handleClose();
                }, 1000);
            }
        }
    }, [isSuccess, isSubmitting, currentRoleIndex, currentRoles, address, factoryAddress, writeContract, reset, onSuccess]);

    // 处理错误
    useEffect(() => {
        if (error && isSubmitting) {
            console.error(`[DeleteUserModal] 撤销角色失败`, {
                address,
                role: ROLES.find(r => r.hash === currentRoles[currentRoleIndex])?.name,
                error: error.message,
            });
            setIsSubmitting(false);
        }
    }, [error, isSubmitting, address, currentRoles, currentRoleIndex]);

    const handleDelete = () => {
        if (currentRoles.length === 0) {
            handleClose();
            return;
        }

        setIsSubmitting(true);
        setCurrentRoleIndex(0);
        const firstRole = currentRoles[0];
        console.log(`[DeleteUserModal] 开始撤销角色`, {
            address,
            role: ROLES.find(r => r.hash === firstRole)?.name,
            totalRoles: currentRoles.length,
        });
        const contractCall = getRevokeContractCall(firstRole, address);
        writeContract({
            address: factoryAddress,
            abi: MarketFactory_V3_ABI,
            functionName: contractCall.functionName,
            args: contractCall.args,
        });
    };

    if (!isOpen) return null;

    const isProcessing = isPending || isConfirming || isSubmitting;
    const currentRole = currentRoles[currentRoleIndex];
    const currentRoleInfo = ROLES.find(r => r.hash === currentRole);
    const userRoles = ROLES.filter(r => currentRoles.includes(r.hash));

    return (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
            <div className="bg-white dark:bg-gray-800 rounded-lg p-6 max-w-md w-full mx-4">
                <div className="flex items-center gap-3 mb-4">
                    <div className="w-10 h-10 rounded-full bg-red-100 dark:bg-red-900/30 flex items-center justify-center">
                        <svg className="w-5 h-5 text-red-600 dark:text-red-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                        </svg>
                    </div>
                    <h3 className="text-lg font-semibold text-gray-900 dark:text-white">
                        删除用户
                    </h3>
                </div>

                <div className="mb-6">
                    <p className="text-sm text-gray-600 dark:text-gray-400 mb-4">
                        确定要删除此用户吗？这将撤销该用户的所有角色权限。
                    </p>

                    {/* 用户信息 */}
                    <div className="p-3 bg-gray-50 dark:bg-gray-700/50 rounded-lg">
                        <p className="text-sm text-gray-500 dark:text-gray-400 mb-1">钱包地址</p>
                        <p className="font-mono text-sm text-gray-900 dark:text-white break-all">
                            {address}
                        </p>

                        {userRoles.length > 0 && (
                            <>
                                <p className="text-sm text-gray-500 dark:text-gray-400 mt-3 mb-1">
                                    将撤销的角色 ({userRoles.length} 个)
                                </p>
                                <div className="flex flex-wrap gap-1">
                                    {userRoles.map((role) => (
                                        <span
                                            key={role.hash}
                                            className={`px-2 py-0.5 rounded text-xs font-medium ${role.color}`}
                                        >
                                            {role.label}
                                        </span>
                                    ))}
                                </div>
                            </>
                        )}
                    </div>
                </div>

                {/* 进度显示 */}
                {isSubmitting && currentRoles.length > 0 && (
                    <div className="mb-4 p-3 bg-orange-50 dark:bg-orange-900/20 border border-orange-200 dark:border-orange-800 rounded-lg">
                        <p className="text-sm text-orange-800 dark:text-orange-200">
                            正在撤销角色 ({currentRoleIndex + 1}/{currentRoles.length})：
                            <span className={`ml-2 px-2 py-0.5 rounded text-xs font-medium ${currentRoleInfo?.color}`}>
                                {currentRoleInfo?.label}
                            </span>
                        </p>
                    </div>
                )}

                {error && (
                    <div className="mb-4 p-3 bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg">
                        <p className="text-sm text-red-600 dark:text-red-400">
                            错误: {error.message.slice(0, 100)}...
                        </p>
                    </div>
                )}

                {isSuccess && currentRoleIndex >= currentRoles.length - 1 && (
                    <div className="mb-4 p-3 bg-green-50 dark:bg-green-900/20 border border-green-200 dark:border-green-800 rounded-lg">
                        <p className="text-sm text-green-600 dark:text-green-400">用户删除成功！</p>
                    </div>
                )}

                <div className="flex gap-3">
                    <Button onClick={handleClose} variant="ghost" className="flex-1" disabled={isProcessing}>
                        取消
                    </Button>
                    <Button
                        onClick={handleDelete}
                        variant="primary"
                        className="flex-1 !bg-red-600 hover:!bg-red-700"
                        disabled={isProcessing}
                    >
                        {isProcessing ? (
                            <span className="flex items-center justify-center gap-2">
                                <LoadingSpinner size="sm" />
                                {isPending ? '确认中...' : '删除中...'}
                            </span>
                        ) : '确认删除'}
                    </Button>
                </div>
            </div>
        </div>
    );
}
