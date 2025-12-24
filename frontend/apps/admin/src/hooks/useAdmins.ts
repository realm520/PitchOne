'use client';

import { useState, useEffect, useCallback } from 'react';
import { graphqlClient, ADMINS_QUERY, ADMIN_QUERY, ROLE_CHANGES_QUERY } from '@pitchone/web3';

// Admin 实体类型
export interface Admin {
    id: string;
    hasAdminRole: boolean;
    hasOperatorRole: boolean;
    hasRouterRole: boolean;
    hasKeeperRole: boolean;
    hasOracleRole: boolean;
    firstGrantedAt: string;
    lastUpdatedAt: string;
}

// 角色变更记录类型
export interface RoleChange {
    id: string;
    admin?: { id: string };
    role: string;
    roleName: string;
    action: 'Grant' | 'Revoke';
    sender: string;
    timestamp: string;
    blockNumber: string;
    transactionHash: string;
}

// Admin 详情（包含角色变更历史）
export interface AdminDetail extends Admin {
    roleChanges: RoleChange[];
}

interface AdminsResponse {
    admins: Admin[];
}

interface AdminResponse {
    admin: AdminDetail | null;
}

interface RoleChangesResponse {
    roleChanges: RoleChange[];
}

/**
 * 获取所有管理员列表
 */
export function useAdmins(first: number = 100, skip: number = 0) {
    const [data, setData] = useState<Admin[]>([]);
    const [isLoading, setIsLoading] = useState(true);
    const [error, setError] = useState<Error | null>(null);

    const fetchAdmins = useCallback(async () => {
        setIsLoading(true);
        setError(null);
        try {
            const response = await graphqlClient.request<AdminsResponse>(ADMINS_QUERY, {
                first,
                skip,
            });
            console.log('[useAdmins] 获取管理员列表', response);
            setData(response.admins || []);
        } catch (err) {
            console.error('[useAdmins] 获取管理员列表失败', err);
            setError(err instanceof Error ? err : new Error('Failed to fetch admins'));
        } finally {
            setIsLoading(false);
        }
    }, [first, skip]);

    useEffect(() => {
        fetchAdmins();
    }, [fetchAdmins]);

    return { data, isLoading, error, refetch: fetchAdmins };
}

/**
 * 获取单个管理员详情
 */
export function useAdmin(address: string | undefined) {
    const [data, setData] = useState<AdminDetail | null>(null);
    const [isLoading, setIsLoading] = useState(false);
    const [error, setError] = useState<Error | null>(null);

    const fetchAdmin = useCallback(async () => {
        if (!address) {
            setData(null);
            return;
        }
        setIsLoading(true);
        setError(null);
        try {
            const response = await graphqlClient.request<AdminResponse>(ADMIN_QUERY, {
                id: address.toLowerCase(),
            });
            console.log('[useAdmin] 获取管理员详情', response);
            setData(response.admin);
        } catch (err) {
            console.error('[useAdmin] 获取管理员详情失败', err);
            setError(err instanceof Error ? err : new Error('Failed to fetch admin'));
        } finally {
            setIsLoading(false);
        }
    }, [address]);

    useEffect(() => {
        fetchAdmin();
    }, [fetchAdmin]);

    return { data, isLoading, error, refetch: fetchAdmin };
}

/**
 * 获取角色变更历史
 */
export function useRoleChanges(first: number = 50, skip: number = 0) {
    const [data, setData] = useState<RoleChange[]>([]);
    const [isLoading, setIsLoading] = useState(true);
    const [error, setError] = useState<Error | null>(null);

    const fetchRoleChanges = useCallback(async () => {
        setIsLoading(true);
        setError(null);
        try {
            const response = await graphqlClient.request<RoleChangesResponse>(ROLE_CHANGES_QUERY, {
                first,
                skip,
            });
            console.log('[useRoleChanges] 获取角色变更历史', response);
            setData(response.roleChanges || []);
        } catch (err) {
            console.error('[useRoleChanges] 获取角色变更历史失败', err);
            setError(err instanceof Error ? err : new Error('Failed to fetch role changes'));
        } finally {
            setIsLoading(false);
        }
    }, [first, skip]);

    useEffect(() => {
        fetchRoleChanges();
    }, [fetchRoleChanges]);

    return { data, isLoading, error, refetch: fetchRoleChanges };
}

/**
 * 将 Admin 对象转换为角色哈希数组
 */
export function adminToRoleHashes(admin: Admin): `0x${string}`[] {
    const roles: `0x${string}`[] = [];
    // 角色哈希（与 ROLES 常量中的定义一致）
    if (admin.hasAdminRole) {
        roles.push('0x0000000000000000000000000000000000000000000000000000000000000000');
    }
    if (admin.hasOperatorRole) {
        roles.push('0x97667070c54ef182b0f5858b034beac1b6f3089aa2d3188bb1e8929f4fa9b929');
    }
    if (admin.hasRouterRole) {
        roles.push('0x7a05a596cb0ce7fdea8a1e1ec73be300bdb35097c944ce1897202f7a13122eb2');
    }
    if (admin.hasKeeperRole) {
        roles.push('0xfc8737ab85eb45125971625a9ebdb75cc78e01d5c1fa80c4c6e5203f47bc4fab');
    }
    if (admin.hasOracleRole) {
        roles.push('0x68e79a7bf1e0bc45d0a330c573bc367f9cf464fd326078812f301165fbda4ef1');
    }
    return roles;
}

/**
 * 检查 Admin 是否拥有任何角色
 */
export function hasAnyRole(admin: Admin): boolean {
    return admin.hasAdminRole ||
        admin.hasOperatorRole ||
        admin.hasRouterRole ||
        admin.hasKeeperRole ||
        admin.hasOracleRole;
}
