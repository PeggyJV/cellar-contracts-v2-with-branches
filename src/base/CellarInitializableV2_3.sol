// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.16;

import { Cellar, Registry, ERC20, PriceRouter } from "src/base/Cellar.sol";
import { Initializable } from "@openzeppelin/contracts/proxy/utils/Initializable.sol";

contract CellarInitializableV2_3 is Cellar, Initializable {
    /**
     * @notice Constructor is only called for the implementation contract,
     *         so it can be safely filled with mostly zero inputs.
     */
    constructor(
        Registry _registry
    )
        Cellar(
            _registry,
            ERC20(address(0)),
            "",
            "",
            abi.encode(new uint32[](0), new uint32[](0), new bytes[](0), new bytes[](0), 0, address(0), 0, 0)
        )
    {}

    /**
     * @notice Initialize function called by factory contract immediately after deployment.
     * @param params abi encoded parameter containing
     *               - Registry contract
     *               - ERC20 cellar asset
     *               - String name of cellar
     *               - String symbol of cellar
     *               - uint32 holding position
     *               - bytes holding position config
     *               - uint64 Strategist platform cut
     *               - address Aave Pool contract address
     * @dev Before calling `sendFees` in the FeesAndReserves contract INSURE that strategist payout is set!
     */
    function initialize(bytes calldata params) external initializer {
        (
            address _owner,
            Registry _registry,
            ERC20 _asset,
            string memory _name,
            string memory _symbol,
            uint32 _holdingPosition,
            bytes memory _holdingPositionConfig,
            uint64 _strategistPlatformCut,
            address _aavePool
        ) = abi.decode(params, (address, Registry, ERC20, string, string, uint32, bytes, uint64, address));

        // Initialize Cellar
        registry = _registry;
        asset = _asset;
        owner = _owner;
        shareLockPeriod = MAXIMUM_SHARE_LOCK_PERIOD;
        allowedRebalanceDeviation = 0.003e18;
        priceRouter = PriceRouter(registry.getAddress(PRICE_ROUTER_REGISTRY_SLOT));

        // Aave V3 pool contract on current network.
        aavePool = _aavePool;

        // Initialize ERC20
        name = _name;
        symbol = _symbol;
        decimals = 18;
        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();

        // Initialize Reentrancy Guard
        locked = 1;

        // Initialize Holding Position.
        _addPositionToCatalogue(_holdingPosition);
        _addPosition(0, _holdingPosition, _holdingPositionConfig, false);
        _setHoldingPosition(_holdingPosition);

        // Initialize remaining values.
        feeData.strategistPlatformCut = _strategistPlatformCut;
    }
}
