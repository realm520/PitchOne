'use client';

import { useState, useEffect } from 'react';
import { useWriteContract, useWaitForTransactionReceipt } from '@pitchone/web3';
import { Button, LoadingSpinner } from '@pitchone/ui';
import { MarketFactory_V3_ABI } from '@pitchone/contracts';
import { ROLES } from '@/constants/roles';

// Keeper 角色哈希（与 roles.ts 中 KEEPER_ROLE 的 hash 一致）
const KEEPER_ROLE_HASH = '0xfc8737ab85eb45125971625a9ebdb75cc78e01d5c1fa80c4c6e5203f47bc4fab' as `0x${string}`;

/**
 * 根据角色和操作获取合约函数名
 * - KEEPER_ROLE: 使用 addKeeper/removeKeeper
 * - 其他角色: 使用 grantRole/revokeRole
 */
function getContractCall(roleHash: `0x${string}`, action: 'grant' | 'revoke', userAddress: `0x${string}`) {
    if (roleHash === KEEPER_ROLE_HASH) {
        return {
            functionName: action === 'grant' ? 'addKeeper' as const : 'removeKeeper' as const,
            args: [userAddress] as const,
        };
    } else {
        return {
            functionName: action === 'grant' ? 'grantRole' as const : 'revokeRole' as const,
            args: [roleHash, userAddress] as const,
        };
    }
}

export interface EditUserModalProps {
    isOpen: boolean;
    onClose: () => void;
    address: `0x${string}`;
    currentRoles: `0x${string}`[];
    factoryAddress: `0x${string}`;
    onSuccess: () => void;
}

interface RoleChange {
    roleHash: `0x${string}`;
    action: 'grant' | 'revoke';
}

export function EditUserModal({
    isOpen,
    onClose,
    address,
    currentRoles,
    factoryAddress,
    onSuccess,
}: EditUserModalProps) {
    const [selectedRoles, setSelectedRoles] = useState<`0x${string}`[]>([]);
    const [isDropdownOpen, setIsDropdownOpen] = useState(false);
    const [pendingChanges, setPendingChanges] = useState<RoleChange[]>([]);
    const [currentChangeIndex, setCurrentChangeIndex] = useState(0);
    const [isSubmitting, setIsSubmitting] = useState(false);

    const { writeContract, data: hash, isPending, error, reset } = useWriteContract();
    const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({ hash });

    // 初始化选中的角色
    useEffect(() => {
        if (isOpen) {
            setSelectedRoles([...currentRoles]);
        }
    }, [isOpen, currentRoles]);

    const resetForm = () => {
        setSelectedRoles([...currentRoles]);
        setPendingChanges([]);
        setCurrentChangeIndex(0);
        setIsSubmitting(false);
        setIsDropdownOpen(false);
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

    // 计算变更
    const calculateChanges = (): RoleChange[] => {
        const changes: RoleChange[] = [];
        selectedRoles.forEach(roleHash => {
            if (!currentRoles.includes(roleHash)) {
                changes.push({ roleHash, action: 'grant' });
            }
        });
        currentRoles.forEach(roleHash => {
            if (!selectedRoles.includes(roleHash)) {
                changes.push({ roleHash, action: 'revoke' });
            }
        });
        return changes;
    };

    const changes = calculateChanges();
    const hasChanges = changes.length > 0;

    // 处理交易成功
    useEffect(() => {
        if (isSuccess && isSubmitting && pendingChanges.length > 0) {
            const nextIndex = currentChangeIndex + 1;
            if (nextIndex < pendingChanges.length) {
                setCurrentChangeIndex(nextIndex);
                reset();
                const nextChange = pendingChanges[nextIndex];
                console.log(`[EditUserModal] 执行下一个变更`, {
                    address,
                    role: ROLES.find(r => r.hash === nextChange.roleHash)?.name,
                    action: nextChange.action,
                    progress: `${nextIndex + 1}/${pendingChanges.length}`,
                });
                const contractCall = getContractCall(nextChange.roleHash, nextChange.action, address);
                writeContract({
                    address: factoryAddress,
                    abi: MarketFactory_V3_ABI,
                    functionName: contractCall.functionName,
                    args: contractCall.args,
                });
            } else {
                console.log(`[EditUserModal] 角色变更完成`, {
                    address,
                    changes: pendingChanges.map(c => ({
                        role: ROLES.find(r => r.hash === c.roleHash)?.name,
                        action: c.action,
                    })),
                    note: '注意：如果某个角色已存在/已撤销，交易仍会成功但不触发事件',
                });
                setTimeout(() => {
                    onSuccess();
                    handleClose();
                }, 1000);
            }
        }
    }, [isSuccess, isSubmitting, currentChangeIndex, pendingChanges, address, factoryAddress, writeContract, reset, onSuccess]);

    // 处理错误
    useEffect(() => {
        if (error && isSubmitting) {
            const currentChange = pendingChanges[currentChangeIndex];
            console.error(`[EditUserModal] 角色变更失败`, {
                address,
                role: ROLES.find(r => r.hash === currentChange?.roleHash)?.name,
                action: currentChange?.action,
                error: error.message,
            });
            setIsSubmitting(false);
        }
    }, [error, isSubmitting, address, pendingChanges, currentChangeIndex]);

    const handleSubmit = () => {
        if (!hasChanges) {
            handleClose();
            return;
        }
        const changesToApply = calculateChanges();
        setPendingChanges(changesToApply);
        setIsSubmitting(true);
        setCurrentChangeIndex(0);
        const firstChange = changesToApply[0];
        console.log(`[EditUserModal] 开始执行角色变更`, {
            address,
            role: ROLES.find(r => r.hash === firstChange.roleHash)?.name,
            action: firstChange.action,
            totalChanges: changesToApply.length,
        });
        const contractCall = getContractCall(firstChange.roleHash, firstChange.action, address);
        writeContract({
            address: factoryAddress,
            abi: MarketFactory_V3_ABI,
            functionName: contractCall.functionName,
            args: contractCall.args,
        });
    };

    if (!isOpen) return null;

    const isProcessing = isPending || isConfirming || isSubmitting;
    const currentChange = pendingChanges[currentChangeIndex];
    const currentChangeInfo = currentChange ? ROLES.find(r => r.hash === currentChange.roleHash) : null;

    return (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
            <div className="bg-white dark:bg-gray-800 rounded-lg p-6 max-w-md w-full mx-4">
                <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-4">
                    编辑用户角色
                </h3>

                <div className="space-y-4 mb-6">
                    {/* 地址显示 */}
                    <div>
                        <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                            钱包地址
                        </label>
                        <div className="w-full px-3 py-2 border dark:border-gray-600 rounded-lg bg-gray-100 dark:bg-gray-700 text-gray-900 dark:text-white font-mono text-sm">
                            {address}
                        </div>
                    </div>

                    {/* 角色选择 */}
                    <div>
                        <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                            用户角色
                        </label>

                        {/* 已选角色 */}
                        {selectedRoles.length > 0 ? (
                            <div className="flex flex-wrap gap-2 mb-2">
                                {selectedRoles.map((roleHash) => {
                                    const role = ROLES.find(r => r.hash === roleHash);
                                    const isNew = !currentRoles.includes(roleHash);
                                    return (
                                        <span
                                            key={roleHash}
                                            className={`inline-flex items-center gap-1 px-2 py-1 rounded text-xs font-medium ${role?.color} ${isNew ? 'ring-2 ring-green-500' : ''}`}
                                        >
                                            {role?.label}
                                            {isNew && <span className="text-green-600 dark:text-green-400">+</span>}
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
                        ) : (
                            <div className="mb-2 text-sm text-gray-500 dark:text-gray-400">无角色</div>
                        )}

                        {/* 待撤销的角色 */}
                        {currentRoles.filter(r => !selectedRoles.includes(r)).length > 0 && (
                            <div className="flex flex-wrap gap-2 mb-2">
                                {currentRoles.filter(r => !selectedRoles.includes(r)).map((roleHash) => {
                                    const role = ROLES.find(r => r.hash === roleHash);
                                    return (
                                        <span
                                            key={roleHash}
                                            className="inline-flex items-center gap-1 px-2 py-1 rounded text-xs font-medium bg-gray-200 dark:bg-gray-600 text-gray-500 dark:text-gray-400 line-through"
                                        >
                                            {role?.label}
                                            <span className="text-red-500">-</span>
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
                                <span className="text-gray-500 dark:text-gray-400">选择角色...</span>
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

                    {/* 变更预览 */}
                    {hasChanges && !isSubmitting && (
                        <div className="p-3 bg-yellow-50 dark:bg-yellow-900/20 border border-yellow-200 dark:border-yellow-800 rounded-lg">
                            <p className="text-sm font-medium text-yellow-800 dark:text-yellow-200 mb-2">待执行变更：</p>
                            <ul className="text-sm text-yellow-700 dark:text-yellow-300 space-y-1">
                                {changes.map((change, idx) => {
                                    const role = ROLES.find(r => r.hash === change.roleHash);
                                    return (
                                        <li key={idx} className="flex items-center gap-2">
                                            <span className={change.action === 'grant' ? 'text-green-600' : 'text-red-600'}>
                                                {change.action === 'grant' ? '+' : '-'}
                                            </span>
                                            <span className={`px-2 py-0.5 rounded text-xs font-medium ${role?.color}`}>{role?.label}</span>
                                            <span className="text-gray-500">({change.action === 'grant' ? '授予' : '撤销'})</span>
                                        </li>
                                    );
                                })}
                            </ul>
                        </div>
                    )}
                </div>

                {/* 进度显示 */}
                {isSubmitting && (
                    <div className="mb-4 p-3 bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800 rounded-lg">
                        <p className="text-sm text-blue-800 dark:text-blue-200">
                            正在{currentChange?.action === 'grant' ? '授予' : '撤销'}角色 ({currentChangeIndex + 1}/{pendingChanges.length})：
                            <span className={`ml-2 px-2 py-0.5 rounded text-xs font-medium ${currentChangeInfo?.color}`}>{currentChangeInfo?.label}</span>
                        </p>
                    </div>
                )}

                {error && (
                    <div className="mb-4 p-3 bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg">
                        <p className="text-sm text-red-600 dark:text-red-400">错误: {error.message.slice(0, 100)}...</p>
                    </div>
                )}

                {isSuccess && currentChangeIndex >= pendingChanges.length - 1 && pendingChanges.length > 0 && (
                    <div className="mb-4 p-3 bg-green-50 dark:bg-green-900/20 border border-green-200 dark:border-green-800 rounded-lg">
                        <p className="text-sm text-green-600 dark:text-green-400">角色变更完成！</p>
                    </div>
                )}

                <div className="flex gap-3">
                    <Button onClick={handleClose} variant="ghost" className="flex-1" disabled={isProcessing}>
                        取消
                    </Button>
                    <Button onClick={handleSubmit} variant="primary" className="flex-1" disabled={isProcessing || !hasChanges}>
                        {isProcessing ? (
                            <span className="flex items-center justify-center gap-2">
                                <LoadingSpinner size="sm" />
                                {isPending ? '确认中...' : '交易中...'}
                            </span>
                        ) : hasChanges ? `确认变更 (${changes.length})` : '无变更'}
                    </Button>
                </div>
            </div>
        </div>
    );
}
