'use client';

import { useState, useEffect } from 'react';
import { useWriteContract, useWaitForTransactionReceipt } from '@pitchone/web3';
import { isAddress } from 'viem';
import { Button, LoadingSpinner, Input } from '@pitchone/ui';
import { MarketFactory_V3_ABI } from '@pitchone/contracts';
import { ROLES } from '@/constants/roles';

export interface AddUserModalProps {
    isOpen: boolean;
    onClose: () => void;
    factoryAddress: `0x${string}`;
    onSuccess: () => void;
}

export function AddUserModal({
    isOpen,
    onClose,
    factoryAddress,
    onSuccess,
}: AddUserModalProps) {
    const [address, setAddress] = useState('');
    const [selectedRoles, setSelectedRoles] = useState<`0x${string}`[]>([]);
    const [currentRoleIndex, setCurrentRoleIndex] = useState(0);
    const [isSubmitting, setIsSubmitting] = useState(false);
    const [isDropdownOpen, setIsDropdownOpen] = useState(false);

    const { writeContract, data: hash, isPending, error, reset } = useWriteContract();
    const { isLoading: isConfirming, isSuccess: isConfirmed } = useWaitForTransactionReceipt({ hash });

    // 所有角色都授予成功
    const [allRolesGranted, setAllRolesGranted] = useState(false);

    const resetForm = () => {
        setAddress('');
        setSelectedRoles([]);
        setCurrentRoleIndex(0);
        setIsSubmitting(false);
        setIsDropdownOpen(false);
        setAllRolesGranted(false);
        reset();
    };

    const handleClose = () => {
        resetForm();
        onClose();
    };

    const toggleRole = (roleHash: `0x${string}`) => {
        setSelectedRoles(prev =>
            prev.includes(roleHash)
                ? prev.filter(r => r !== roleHash)
                : [...prev, roleHash]
        );
    };

    const removeRole = (roleHash: `0x${string}`) => {
        setSelectedRoles(prev => prev.filter(r => r !== roleHash));
    };

    // 处理交易确认成功
    useEffect(() => {
        if (isConfirmed && isSubmitting && !allRolesGranted) {
            const nextIndex = currentRoleIndex + 1;
            if (nextIndex < selectedRoles.length) {
                // 还有更多角色需要授予
                setCurrentRoleIndex(nextIndex);
                reset();
                const nextRole = selectedRoles[nextIndex];
                console.log(`[AddUserModal] 授予下一个角色`, {
                    address,
                    role: ROLES.find(r => r.hash === nextRole)?.name,
                    progress: `${nextIndex + 1}/${selectedRoles.length}`,
                });
                writeContract({
                    address: factoryAddress,
                    abi: MarketFactory_V3_ABI,
                    functionName: 'grantRole',
                    args: [nextRole, address as `0x${string}`],
                });
            } else {
                // 所有角色都已授予成功
                console.log(`[AddUserModal] 所有角色授予成功`, {
                    address,
                    roles: selectedRoles.map(h => ROLES.find(r => r.hash === h)?.name),
                });
                setAllRolesGranted(true);
                setIsSubmitting(false);
                setTimeout(() => {
                    onSuccess();
                    handleClose();
                }, 1500);
            }
        }
    }, [isConfirmed, isSubmitting, allRolesGranted, currentRoleIndex, selectedRoles, address, factoryAddress, writeContract, reset, onSuccess]);

    // 处理错误
    useEffect(() => {
        if (error && isSubmitting) {
            console.error(`[AddUserModal] 授予角色失败`, {
                address,
                role: ROLES.find(r => r.hash === selectedRoles[currentRoleIndex])?.name,
                error: error.message,
            });
            setIsSubmitting(false);
        }
    }, [error, isSubmitting, address, selectedRoles, currentRoleIndex]);

    const handleSubmit = () => {
        if (!isAddress(address)) {
            alert('请输入有效的钱包地址');
            return;
        }

        if (selectedRoles.length === 0) {
            console.log(`[AddUserModal] 添加用户（无角色）`, { address });
            onSuccess();
            handleClose();
            return;
        }

        setIsSubmitting(true);
        setCurrentRoleIndex(0);
        const firstRole = selectedRoles[0];
        console.log(`[AddUserModal] 开始授予角色`, {
            address,
            role: ROLES.find(r => r.hash === firstRole)?.name,
            totalRoles: selectedRoles.length,
        });
        writeContract({
            address: factoryAddress,
            abi: MarketFactory_V3_ABI,
            functionName: 'grantRole',
            args: [firstRole, address as `0x${string}`],
        });
    };

    if (!isOpen) return null;

    const isProcessing = isPending || isConfirming || isSubmitting;
    const currentRole = selectedRoles[currentRoleIndex];
    const currentRoleInfo = ROLES.find(r => r.hash === currentRole);

    return (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
            <div className="bg-white dark:bg-gray-800 rounded-lg p-6 max-w-md w-full mx-4">
                <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-4">
                    添加用户
                </h3>

                <div className="space-y-4 mb-6">
                    {/* 地址输入 */}
                    <div>
                        <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                            钱包地址
                        </label>
                        <Input
                            type="text"
                            value={address}
                            onChange={(e) => setAddress(e.target.value)}
                            placeholder="0x..."
                            className="w-full font-mono"
                            disabled={isProcessing}
                        />
                    </div>

                    {/* 角色选择 */}
                    <div>
                        <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                            初始角色（可选）
                        </label>

                        {/* 已选角色 */}
                        {selectedRoles.length > 0 && (
                            <div className="flex flex-wrap gap-2 mb-2">
                                {selectedRoles.map((roleHash) => {
                                    const role = ROLES.find(r => r.hash === roleHash);
                                    return (
                                        <span
                                            key={roleHash}
                                            className={`inline-flex items-center gap-1 px-2 py-1 rounded text-xs font-medium ${role?.color}`}
                                        >
                                            {role?.label}
                                            {!isProcessing && (
                                                <button
                                                    type="button"
                                                    onClick={() => removeRole(roleHash)}
                                                    className="ml-1 hover:opacity-70"
                                                >
                                                    ✕
                                                </button>
                                            )}
                                        </span>
                                    );
                                })}
                            </div>
                        )}

                        {/* 下拉选择 */}
                        <div className="relative">
                            <button
                                type="button"
                                onClick={() => !isProcessing && setIsDropdownOpen(!isDropdownOpen)}
                                disabled={isProcessing}
                                className={`w-full px-3 py-2 text-left border dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white flex items-center justify-between ${isProcessing ? 'opacity-50 cursor-not-allowed' : 'hover:bg-gray-50 dark:hover:bg-gray-600'}`}
                            >
                                <span className="text-gray-500 dark:text-gray-400">
                                    {selectedRoles.length === 0 ? '选择角色...' : `已选择 ${selectedRoles.length} 个角色`}
                                </span>
                                <svg className={`w-4 h-4 transition-transform ${isDropdownOpen ? 'rotate-180' : ''}`} fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
                                </svg>
                            </button>

                            {isDropdownOpen && (
                                <div className="absolute z-10 w-full mt-1 bg-white dark:bg-gray-700 border dark:border-gray-600 rounded-lg shadow-lg max-h-60 overflow-auto">
                                    {ROLES.map((role) => (
                                        <label
                                            key={role.hash}
                                            className={`flex items-center gap-3 px-3 py-2 cursor-pointer transition-colors ${selectedRoles.includes(role.hash) ? 'bg-blue-50 dark:bg-blue-900/20' : 'hover:bg-gray-50 dark:hover:bg-gray-600'}`}
                                        >
                                            <input
                                                type="checkbox"
                                                checked={selectedRoles.includes(role.hash)}
                                                onChange={() => toggleRole(role.hash)}
                                                className="w-4 h-4 text-blue-600 rounded"
                                            />
                                            <span className={`px-2 py-0.5 rounded text-xs font-medium ${role.color}`}>{role.label}</span>
                                            <span className="text-sm text-gray-600 dark:text-gray-400 flex-1">{role.description}</span>
                                        </label>
                                    ))}
                                </div>
                            )}
                        </div>
                    </div>
                </div>

                {/* 进度显示 */}
                {isSubmitting && selectedRoles.length > 0 && !allRolesGranted && (
                    <div className="mb-4 p-3 bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800 rounded-lg">
                        <p className="text-sm text-blue-800 dark:text-blue-200">
                            {isPending ? '请在钱包中确认交易...' : isConfirming ? '等待区块确认...' : '准备中...'}
                        </p>
                        <p className="text-sm text-blue-800 dark:text-blue-200 mt-1">
                            角色 ({currentRoleIndex + 1}/{selectedRoles.length})：
                            <span className={`ml-2 px-2 py-0.5 rounded text-xs font-medium ${currentRoleInfo?.color}`}>{currentRoleInfo?.label}</span>
                        </p>
                    </div>
                )}

                {error && (
                    <div className="mb-4 p-3 bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg">
                        <p className="text-sm text-red-600 dark:text-red-400">错误: {error.message.slice(0, 100)}...</p>
                    </div>
                )}

                {allRolesGranted && (
                    <div className="mb-4 p-3 bg-green-50 dark:bg-green-900/20 border border-green-200 dark:border-green-800 rounded-lg">
                        <p className="text-sm text-green-600 dark:text-green-400">用户添加成功！所有角色已授予。</p>
                    </div>
                )}

                <div className="flex gap-3">
                    <Button onClick={handleClose} variant="ghost" className="flex-1" disabled={isProcessing && !allRolesGranted}>
                        {allRolesGranted ? '关闭' : '取消'}
                    </Button>
                    <Button onClick={handleSubmit} variant="primary" className="flex-1" disabled={isProcessing || !address || allRolesGranted}>
                        {allRolesGranted ? (
                            '完成'
                        ) : isProcessing ? (
                            <span className="flex items-center justify-center gap-2">
                                <LoadingSpinner size="sm" />
                                {isPending ? '请确认钱包...' : isConfirming ? '等待确认...' : '处理中...'}
                            </span>
                        ) : selectedRoles.length > 0 ? `授予 ${selectedRoles.length} 个角色` : '添加用户'}
                    </Button>
                </div>
            </div>
        </div>
    );
}
