import { useReadContract } from '@pitchone/web3';
import { MarketFactory_V3_ABI } from '@pitchone/contracts';

// 检查单个角色的 hook
export function useHasRole(
    factoryAddress: `0x${string}`,
    roleHash: `0x${string}`,
    userAddress: `0x${string}`
) {
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    return useReadContract({
        address: factoryAddress,
        abi: MarketFactory_V3_ABI as any,
        functionName: 'hasRole',
        args: [roleHash, userAddress],
    });
}
