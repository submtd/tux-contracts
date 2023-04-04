// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./abstracts/BaseContract.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
// Interfaces.
import "./interfaces/IWhiteCarpet.sol";
import "./interfaces/IRedCarpet.sol";
import "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

error NATIVE_TOKEN_TRANSFER_FAILED();
error NOT_OWNER();
error INDEX_OUT_OF_BOUNDS();

contract StakingNft is BaseContract, ERC721 {
    using Strings for uint256;
    using SafeERC20 for IERC20Metadata;

    /**
     * Contract constructor.
     */
    constructor() ERC721("Tux Staking", "TUXS") {}

    /**
     * External contracts.
     */
    IERC20Metadata private _nativeToken;
    uint256 private _nativeTokenDecimals;
    IERC20Metadata private _paymentToken;
    uint256 private _paymentTokenDecimals;
    IWhiteCarpet private _whiteCarpet;
    IRedCarpet private _redCarpet;
    IUniswapV2Router02 private _router;

    /**
     * NFT data.
     */
    uint256 private _tokenIdTracker;
    mapping(uint256 => uint256) private _entryPrice;

    /**
     * Setup.
     */
    function setup() external override
    {
        _nativeToken = IERC20Metadata(addressBook.get("Tux"));
        _nativeTokenDecimals = _nativeToken.decimals();
        _paymentToken = IERC20Metadata(addressBook.get("Usdc"));
        _paymentTokenDecimals = _paymentToken.decimals();
        _whiteCarpet = IWhiteCarpet(addressBook.get("WhiteCarpet"));
        _redCarpet = IRedCarpet(addressBook.get("RedCarpet"));
        _router = IUniswapV2Router02(addressBook.get("Router"));
    }

    /**
     * Token of owner by index.
     * @param owner_ Owner address.
     * @param index_ Index.
     * @return uint256 Token ID.
     */
    function tokenOfOwnerByIndex(address owner_, uint256 index_) public view returns (uint256)
    {
        if(balanceOf(owner_) <= index_) revert INDEX_OUT_OF_BOUNDS();
        for(uint256 i = 1; i <= _tokenIdTracker; i++) {
            if(ownerOf(i) == owner_) {
                if(index_ == 0) return i;
                index_--;
            }
        }
        return 0;
    }

    /**
     * Stake.
     * @param amount_ Amount to stake.
     */
    function stake(uint256 amount_) external runCron
    {
        _stake(msg.sender, amount_);
    }

    /**
     * Stake internal.
     * @param staker_ Staker address.
     * @param amount_ Amount to stake.
     */
    function _stake(address staker_, uint256 amount_) internal
    {
        _nativeToken.safeTransferFrom(staker_, address(_whiteCarpet), amount_);
        // Get current native token price.
        address[] memory _path_ = new address[](2);
        _path_[0] = address(_nativeToken);
        _path_[1] = address(_paymentToken);
        uint256 _price_ = _router.getAmountsOut((10 ** _nativeTokenDecimals), _path_)[1];
        // Mint a new NFT.
        _tokenIdTracker ++;
        _entryPrice[_tokenIdTracker] = _price_;
        _mint(staker_, _tokenIdTracker);
        _whiteCarpet.stake(_tokenIdTracker, amount_);
    }

    /**
     * Unstake.
     * @param tokenId_ Token ID.
     */
    function unstake(uint256 tokenId_) external runCron
    {
        if(ownerOf(tokenId_) != msg.sender) revert NOT_OWNER();
        _unstake(msg.sender, tokenId_);
    }

    /**
     * Unstake internal.
     * @param tokenId_ Token ID.
     */
    function _unstake(address recipient_, uint256 tokenId_) internal
    {
        _whiteCarpet.unstake(tokenId_, recipient_);
        _burn(tokenId_);
    }

    /**
     * Compound.
     * @param tokenId_ Token ID.
     */
    function compound(uint256 tokenId_) external runCron
    {
        if(ownerOf(tokenId_) != msg.sender) revert NOT_OWNER();
        _compound(tokenId_);
    }

    /**
     * Compound internal.
     * @param tokenId_ Token ID.
     */
    function _compound(uint256 tokenId_) internal
    {
        _whiteCarpet.compound(tokenId_);
    }

    /**
     * Claim.
     * @param tokenId_ Token ID.
     */
    function claim(uint256 tokenId_) external runCron
    {
        if(ownerOf(tokenId_) != msg.sender) revert NOT_OWNER();
        _claim(msg.sender, tokenId_);
    }

    /**
     * Claim internal.
     * @param recipient_ Recipient address.
     * @param tokenId_ Token ID.
     */
    function _claim(address recipient_, uint256 tokenId_) internal
    {
        _whiteCarpet.claim(tokenId_, recipient_);
    }

    /**
     * Available dividends.
     * @param tokenId_ Token ID.
     * @return uint256 Available dividends.
     */
    function availableDividends(uint256 tokenId_) public view returns (uint256)
    {
        return _availableDividends(tokenId_);
    }

    /**
     * Available dividends internal.
     * @param tokenId_ Token ID.
     * @return uint256 Available dividends.
     */
    function _availableDividends(uint256 tokenId_) internal view returns (uint256)
    {
        (,,uint256 _availableDividends_) = _whiteCarpet.getStake(tokenId_);
        return _availableDividends_;
    }

    /**
     * Cron.
     */
    function cron() external
    {

    }
}
