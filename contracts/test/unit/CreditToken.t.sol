// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../../src/tokens/CreditToken.sol";

/**
 * @title CreditToken Test Suite
 * @notice 免手续费券系统完整测试
 */
contract CreditTokenTest is Test {
    CreditToken public creditToken;

    address public admin = address(this);
    address public minter = address(0x1);
    address public pauser = address(0x2);
    address public alice = address(0x3);
    address public bob = address(0x4);
    address public charlie = address(0x5);

    uint256 public constant BPS_DENOMINATOR = 10000;

    // 测试用券种 ID
    uint256 public creditTypeId1; // 1 USDC, 100% 折扣, 永不过期, 无限使用
    uint256 public creditTypeId2; // 5 USDC, 50% 折扣, 30 天后过期, 最多 3 次
    uint256 public creditTypeId3; // 10 USDC, 100% 折扣, 过期, 单次使用

    event CreditTypeCreated(
        uint256 indexed creditTypeId,
        uint256 value,
        uint256 discountBps,
        uint256 expiresAt,
        uint256 maxUses
    );

    event CreditUsed(
        address indexed user,
        uint256 indexed creditTypeId,
        uint256 amount,
        uint256 discountValue
    );

    event CreditBatchMinted(
        uint256 indexed creditTypeId,
        address[] recipients,
        uint256[] amounts,
        uint256 totalAmount
    );

    function setUp() public {
        creditToken = new CreditToken("https://pitchone.io/credits/{id}.json");

        // 授予角色
        creditToken.grantRole(creditToken.MINTER_ROLE(), minter);
        creditToken.grantRole(creditToken.PAUSER_ROLE(), pauser);

        // 创建测试券种
        creditTypeId1 = creditToken.createCreditType(
            1_000_000, // 1 USDC (6 decimals)
            10000,     // 100% 折扣
            0,         // 永不过期
            0,         // 无限使用
            "type1.json"
        );

        creditTypeId2 = creditToken.createCreditType(
            5_000_000, // 5 USDC
            5000,      // 50% 折扣
            block.timestamp + 30 days,
            3,         // 最多 3 次
            "type2.json"
        );

        creditTypeId3 = creditToken.createCreditType(
            10_000_000, // 10 USDC
            10000,      // 100% 折扣
            block.timestamp - 1, // 已过期
            1,          // 单次使用
            "type3.json"
        );

        // 将过期的券设置为不活跃，模拟真实场景
        creditToken.setCreditTypeStatus(creditTypeId3, false);
    }

    // ============================================================================
    // Constructor & Setup Tests
    // ============================================================================

    function test_Constructor() public view {
        assertEq(creditToken.hasRole(creditToken.DEFAULT_ADMIN_ROLE(), admin), true);
        assertEq(creditToken.hasRole(creditToken.MINTER_ROLE(), admin), true);
        assertEq(creditToken.hasRole(creditToken.PAUSER_ROLE(), admin), true);
        assertEq(creditToken.nextCreditTypeId(), 3);
    }

    function test_CreateCreditType() public {
        vm.expectEmit(true, false, false, true);
        emit CreditTypeCreated(3, 2_000_000, 10000, 0, 0);

        uint256 newId = creditToken.createCreditType(
            2_000_000,
            10000,
            0,
            0,
            "new.json"
        );

        assertEq(newId, 3);
        assertEq(creditToken.nextCreditTypeId(), 4);

        (
            uint256 value,
            uint256 discountBps,
            uint256 expiresAt,
            uint256 maxUses,
            bool isActive,
            string memory metadata
        ) = creditToken.creditTypes(newId);

        assertEq(value, 2_000_000);
        assertEq(discountBps, 10000);
        assertEq(expiresAt, 0);
        assertEq(maxUses, 0);
        assertTrue(isActive);
        assertEq(metadata, "new.json");
    }

    function test_RevertWhen_CreateCreditTypeInvalidDiscount() public {
        vm.expectRevert(CreditToken.InvalidDiscountBps.selector);
        creditToken.createCreditType(
            1_000_000,
            10001, // > 100%
            0,
            0,
            ""
        );
    }

    function test_RevertWhen_CreateCreditTypeNotAdmin() public {
        vm.prank(alice);
        vm.expectRevert();
        creditToken.createCreditType(1_000_000, 10000, 0, 0, "");
    }

    // ============================================================================
    // Minting Tests
    // ============================================================================

    function test_Mint() public {
        vm.prank(minter);
        creditToken.mint(alice, creditTypeId1, 5);

        assertEq(creditToken.balanceOf(alice, creditTypeId1), 5);
        assertEq(creditToken.totalSupply(creditTypeId1), 5);
    }

    function test_BatchMint() public {
        address[] memory recipients = new address[](3);
        recipients[0] = alice;
        recipients[1] = bob;
        recipients[2] = charlie;

        uint256[] memory amounts = new uint256[](3);
        amounts[0] = 10;
        amounts[1] = 20;
        amounts[2] = 30;

        vm.expectEmit(true, false, false, false);
        emit CreditBatchMinted(creditTypeId1, recipients, amounts, 60);

        vm.prank(minter);
        creditToken.batchMint(creditTypeId1, recipients, amounts);

        assertEq(creditToken.balanceOf(alice, creditTypeId1), 10);
        assertEq(creditToken.balanceOf(bob, creditTypeId1), 20);
        assertEq(creditToken.balanceOf(charlie, creditTypeId1), 30);
        assertEq(creditToken.totalSupply(creditTypeId1), 60);
    }

    function test_RevertWhen_MintInvalidCreditType() public {
        vm.prank(minter);
        vm.expectRevert(CreditToken.InvalidCreditType.selector);
        creditToken.mint(alice, 999, 1);
    }

    function test_RevertWhen_MintInactiveCreditType() public {
        creditToken.setCreditTypeStatus(creditTypeId1, false);

        vm.prank(minter);
        vm.expectRevert(CreditToken.CreditNotActive.selector);
        creditToken.mint(alice, creditTypeId1, 1);
    }

    function test_RevertWhen_MintZeroAddress() public {
        vm.prank(minter);
        vm.expectRevert(CreditToken.ZeroAddress.selector);
        creditToken.mint(address(0), creditTypeId1, 1);
    }

    function test_RevertWhen_MintNotMinter() public {
        vm.prank(alice);
        vm.expectRevert();
        creditToken.mint(alice, creditTypeId1, 1);
    }

    function test_RevertWhen_BatchMintArrayLengthMismatch() public {
        address[] memory recipients = new address[](2);
        uint256[] memory amounts = new uint256[](3);

        vm.prank(minter);
        vm.expectRevert(CreditToken.InvalidArrayLength.selector);
        creditToken.batchMint(creditTypeId1, recipients, amounts);
    }

    // ============================================================================
    // Usage Tests
    // ============================================================================

    function test_UseCredit() public {
        // 先铸造券
        vm.prank(minter);
        creditToken.mint(alice, creditTypeId1, 5);

        // 使用券
        vm.expectEmit(true, true, false, true);
        emit CreditUsed(alice, creditTypeId1, 2, 2_000_000); // 2 * 1 USDC * 100%

        vm.prank(minter);
        uint256 discountValue = creditToken.useCredit(alice, creditTypeId1, 2);

        assertEq(discountValue, 2_000_000);
        assertEq(creditToken.balanceOf(alice, creditTypeId1), 3); // 5 - 2 = 3
        assertEq(creditToken.totalUsed(creditTypeId1), 2);
        assertEq(creditToken.usedCount(alice, creditTypeId1), 0); // 无限使用，不计数
    }

    function test_UseCreditWithMaxUses() public {
        // 使用有次数限制的券
        vm.prank(minter);
        creditToken.mint(alice, creditTypeId2, 5);

        vm.prank(minter);
        uint256 discountValue = creditToken.useCredit(alice, creditTypeId2, 2);

        // 5 USDC * 50% * 2 = 5 USDC
        assertEq(discountValue, 5_000_000);
        assertEq(creditToken.usedCount(alice, creditTypeId2), 2);
        assertEq(creditToken.balanceOf(alice, creditTypeId2), 3);
    }

    function test_RevertWhen_UseCreditExpired() public {
        // 创建一个新的即将过期的券种，然后铸造
        uint256 expiringId = creditToken.createCreditType(
            1_000_000,
            10000,
            block.timestamp + 1 hours, // 1小时后过期
            0,
            ""
        );

        vm.prank(minter);
        creditToken.mint(alice, expiringId, 1);

        // 时间快进到过期后
        vm.warp(block.timestamp + 2 hours);

        vm.prank(minter);
        vm.expectRevert(CreditToken.CreditExpired.selector);
        creditToken.useCredit(alice, expiringId, 1);
    }

    function test_RevertWhen_UseCreditInsufficientBalance() public {
        vm.prank(minter);
        creditToken.mint(alice, creditTypeId1, 2);

        vm.prank(minter);
        vm.expectRevert(CreditToken.InsufficientCredit.selector);
        creditToken.useCredit(alice, creditTypeId1, 3);
    }

    function test_RevertWhen_UseCreditMaxUsesExceeded() public {
        vm.prank(minter);
        creditToken.mint(alice, creditTypeId2, 10);

        // 使用 3 次（上限）
        vm.prank(minter);
        creditToken.useCredit(alice, creditTypeId2, 3);

        // 第 4 次应该失败
        vm.prank(minter);
        vm.expectRevert(CreditToken.MaxUsesExceeded.selector);
        creditToken.useCredit(alice, creditTypeId2, 1);
    }

    function test_RevertWhen_UseCreditInactive() public {
        // 先铸造
        vm.prank(minter);
        creditToken.mint(alice, creditTypeId1, 5);

        // 然后禁用
        creditToken.setCreditTypeStatus(creditTypeId1, false);

        vm.prank(minter);
        vm.expectRevert(CreditToken.CreditNotActive.selector);
        creditToken.useCredit(alice, creditTypeId1, 1);
    }

    // ============================================================================
    // Query Tests
    // ============================================================================

    function test_GetAvailableDiscount() public {
        vm.prank(minter);
        creditToken.mint(alice, creditTypeId1, 5);

        uint256 discount = creditToken.getAvailableDiscount(alice, creditTypeId1);
        // 5 * 1 USDC * 100% = 5 USDC
        assertEq(discount, 5_000_000);
    }

    function test_GetAvailableDiscountWithMaxUses() public {
        vm.prank(minter);
        creditToken.mint(alice, creditTypeId2, 10);

        uint256 discount = creditToken.getAvailableDiscount(alice, creditTypeId2);
        // maxUses = 3, 所以只能用 3 张
        // 3 * 5 USDC * 50% = 7.5 USDC
        assertEq(discount, 7_500_000);
    }

    function test_GetAvailableDiscountAfterPartialUse() public {
        vm.prank(minter);
        creditToken.mint(alice, creditTypeId2, 10);

        // 使用 2 次
        vm.prank(minter);
        creditToken.useCredit(alice, creditTypeId2, 2);

        // 剩余 1 次
        uint256 discount = creditToken.getAvailableDiscount(alice, creditTypeId2);
        assertEq(discount, 2_500_000); // 1 * 5 USDC * 50%
    }

    function test_GetAvailableDiscountExpired() public {
        // 创建一个新的即将过期的券种
        uint256 expiringId = creditToken.createCreditType(
            1_000_000,
            10000,
            block.timestamp + 1 hours,
            0,
            ""
        );

        vm.prank(minter);
        creditToken.mint(alice, expiringId, 5);

        // 时间快进到过期后
        vm.warp(block.timestamp + 2 hours);

        uint256 discount = creditToken.getAvailableDiscount(alice, expiringId);
        assertEq(discount, 0); // 已过期
    }

    function test_IsCreditValid() public view {
        assertTrue(creditToken.isCreditValid(creditTypeId1));
        assertTrue(creditToken.isCreditValid(creditTypeId2));
        assertFalse(creditToken.isCreditValid(creditTypeId3)); // 已禁用
        assertFalse(creditToken.isCreditValid(999)); // 不存在
    }

    function test_IsCreditValidExpired() public {
        // 创建一个新的即将过期的券种
        uint256 expiringId = creditToken.createCreditType(
            1_000_000,
            10000,
            block.timestamp + 1 hours,
            0,
            ""
        );

        assertTrue(creditToken.isCreditValid(expiringId)); // 未过期

        // 时间快进到过期后
        vm.warp(block.timestamp + 2 hours);

        assertFalse(creditToken.isCreditValid(expiringId)); // 已过期
    }

    function test_GetCreditStatus() public {
        vm.prank(minter);
        creditToken.mint(alice, creditTypeId2, 10);

        (uint256 balance, uint256 used, uint256 maxUses) = creditToken.getCreditStatus(
            alice,
            creditTypeId2
        );

        assertEq(balance, 10);
        assertEq(used, 0);
        assertEq(maxUses, 3);

        // 使用后
        vm.prank(minter);
        creditToken.useCredit(alice, creditTypeId2, 2);

        (balance, used, maxUses) = creditToken.getCreditStatus(alice, creditTypeId2);
        assertEq(balance, 8);
        assertEq(used, 2);
        assertEq(maxUses, 3);
    }

    // ============================================================================
    // Admin Functions Tests
    // ============================================================================

    function test_SetCreditTypeStatus() public {
        assertTrue(getCreditTypeActive(creditTypeId1));

        creditToken.setCreditTypeStatus(creditTypeId1, false);
        assertFalse(getCreditTypeActive(creditTypeId1));

        creditToken.setCreditTypeStatus(creditTypeId1, true);
        assertTrue(getCreditTypeActive(creditTypeId1));
    }

    function test_RevertWhen_SetCreditTypeStatusInvalidId() public {
        vm.expectRevert(CreditToken.InvalidCreditType.selector);
        creditToken.setCreditTypeStatus(999, false);
    }

    function test_SetURI() public {
        string memory newUri = "https://new.uri/{id}";
        creditToken.setURI(newUri);
        // URI 已更新，但无法直接验证（ERC1155 内部状态）
    }

    // ============================================================================
    // Pause Tests
    // ============================================================================

    function test_Pause() public {
        vm.prank(pauser);
        creditToken.pause();

        assertTrue(creditToken.paused());

        // 暂停后无法铸造
        vm.prank(minter);
        vm.expectRevert();
        creditToken.mint(alice, creditTypeId1, 1);
    }

    function test_Unpause() public {
        vm.prank(pauser);
        creditToken.pause();

        vm.prank(pauser);
        creditToken.unpause();

        assertFalse(creditToken.paused());

        // 恢复后可以铸造
        vm.prank(minter);
        creditToken.mint(alice, creditTypeId1, 1);
        assertEq(creditToken.balanceOf(alice, creditTypeId1), 1);
    }

    // ============================================================================
    // Metadata Tests
    // ============================================================================

    function test_URI() public view {
        string memory uri1 = creditToken.uri(creditTypeId1);
        assertEq(uri1, "type1.json");

        string memory uri2 = creditToken.uri(creditTypeId2);
        assertEq(uri2, "type2.json");

        string memory uriInvalid = creditToken.uri(999);
        assertEq(uriInvalid, "");
    }

    // ============================================================================
    // ERC1155 Standard Tests
    // ============================================================================

    function test_ERC1155Transfer() public {
        vm.prank(minter);
        creditToken.mint(alice, creditTypeId1, 10);

        // Alice 转给 Bob
        vm.prank(alice);
        creditToken.safeTransferFrom(alice, bob, creditTypeId1, 5, "");

        assertEq(creditToken.balanceOf(alice, creditTypeId1), 5);
        assertEq(creditToken.balanceOf(bob, creditTypeId1), 5);
    }

    function test_ERC1155BatchTransfer() public {
        vm.prank(minter);
        creditToken.mint(alice, creditTypeId1, 10);

        vm.prank(minter);
        creditToken.mint(alice, creditTypeId2, 20);

        uint256[] memory ids = new uint256[](2);
        ids[0] = creditTypeId1;
        ids[1] = creditTypeId2;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 5;
        amounts[1] = 10;

        vm.prank(alice);
        creditToken.safeBatchTransferFrom(alice, bob, ids, amounts, "");

        assertEq(creditToken.balanceOf(bob, creditTypeId1), 5);
        assertEq(creditToken.balanceOf(bob, creditTypeId2), 10);
    }

    function test_SupportsInterface() public view {
        // ERC1155
        assertTrue(creditToken.supportsInterface(0xd9b67a26));
        // AccessControl
        assertTrue(creditToken.supportsInterface(0x7965db0b));
    }

    // ============================================================================
    // Helper Functions
    // ============================================================================

    function getCreditTypeActive(uint256 creditTypeId) internal view returns (bool) {
        (,,,, bool isActive,) = creditToken.creditTypes(creditTypeId);
        return isActive;
    }
}
