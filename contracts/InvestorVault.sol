// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./abstracts/BaseContract.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
// Interfaces.
import "@openzeppelin/contracts/interfaces/IERC20.sol";

error INVESTORVAULT_invalidTokenId();
error INVESTORVAULT_invalidAmount();

contract InvestorVault is BaseContract, ERC721
{
    /**
     * Contract constructor.
     */
    constructor() ERC721("Tux Investor Vault", "TUXIV") {}

    using Strings for uint256;

    /**
     * External contracts.
     */
    IERC20 private usdc;
    IERC20 private tux;

    /**
     * Stats.
     */
    uint256 public totalInvested;
    uint256 public totalWithdrawn;

    /**
     * Investors.
     */
    uint256 private _tokenIdTracker;
    mapping(uint256 => uint256) public invested;
    mapping(uint256 => uint256) public withdrawn;

    /**
     * Total repaid.
     * @return uint256 Total repaid.
     */
    function totalRepaid() public view returns (uint256)
    {
        return _totalRepaid();
    }

    /**
     * Total repaid internal.
     * @return uint256 Total repaid.
     */
    function _totalRepaid() internal view returns (uint256)
    {
        return usdc.balanceOf(address(this)) + totalWithdrawn;
    }

    /**
     * Total outstanding.
     * @return uint256 Total outstanding.
     */
    function totalOutstanding() external view returns (uint256)
    {
        return totalInvested - _totalRepaid();
    }

    /**
     * Setup.
     */
    function setup() external override
    {
        usdc = IERC20(addressBook.get("Usdc"));
        tux = IERC20(addressBook.get("Tux"));
    }

    /**
     * Add investor.
     * @param investor_ Investor address.
     * @param amount_ Amount to add.
     */
    function addInvestor(address investor_, uint256 amount_) external onlyOwner
    {
        _addInvestor(investor_, amount_);
    }

    /**
     * Add investor internal.
     * @param investor_ Investor address.
     * @param amount_ Amount to add.
     */
    function _addInvestor(address investor_, uint256 amount_) internal
    {
        totalInvested += amount_;
        _tokenIdTracker++;
        invested[_tokenIdTracker] = amount_;
        _mint(investor_, _tokenIdTracker);
    }

    /**
     * Available per share.
     * @return uint256 Available per share.
     */
    function _availablePerShare() internal view returns (uint256)
    {
        return ((usdc.balanceOf(address(this)) + totalWithdrawn) * 1e18) / totalInvested;
    }

    /**
     * Available.
     * @param tokenId_ Token ID.
     * @return uint256 Available.
     */
    function available(uint256 tokenId_) external view returns (uint256)
    {
        return _available(tokenId_);
    }

    /**
     * Available internal.
     * @param tokenId_ Token ID.
     * @return uint256 Available.
     */
    function _available(uint256 tokenId_) internal view returns (uint256)
    {
        return (invested[tokenId_] * _availablePerShare()) / 1e18 - withdrawn[tokenId_];
    }

    /**
     * Withdraw.
     * @param tokenId_ Token ID.
     */
    function withdraw(uint256 tokenId_) external
    {
        uint256 _available_ = _available(tokenId_);
        if(_available_ <= 0) revert INVESTORVAULT_invalidAmount();
        withdrawn[tokenId_] += _available_;
        totalWithdrawn += _available_;
        usdc.transfer(msg.sender, _available_);
    }

    /**
     * Token URI.
     * @param tokenId_ Token ID.
     * @return string Token metadata.
     */
    function tokenURI(uint256 tokenId_) public view override returns (string memory)
    {
        if(tokenId_ <= 0 || tokenId_ > _tokenIdTracker) revert INVESTORVAULT_invalidTokenId();
        bytes memory _meta_ = abi.encodePacked(
            '{',
            '"name": "Tux Investor Vault #', tokenId_.toString(), '",',
            '"description": "Tux Investor Vault",',
            '"attributes": [',
            abi.encodePacked(
                '{"trait_type": "Invested", "value": "', invested[tokenId_].toString(), '"},',
                '{"trait_type": "Withdrawn", "value": "', withdrawn[tokenId_].toString(), '"}'
            ),
            ']',
            '}'
        );
        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(_meta_)
            )
        );
    }
}
