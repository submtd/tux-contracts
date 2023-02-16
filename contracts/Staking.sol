// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./abstracts/BaseContract.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
// Interfaces.
import "@openzeppelin/contracts/interfaces/IERC20.sol";

error STAKING_transferFailed();

contract Staking is BaseContract, ERC721 {

    /**
     * Contract constructor.
     */
    constructor() ERC721("Tux Staking", "TUXS") {}

    IERC20 private _tux;
    IERC20 private _usdc;
    uint256 private _tokenIdTracker;

    mapping(uint256 => address) private _stakeOwner;
    mapping(uint256 => uint256) private _stakeAmount;
    mapping(uint256 => uint256) private _stakeStart;

    /**
     * Stake.
     * @param amount_ Amount to stake
     */
    function stake(uint256 amount_) external
    {
        if(address(_tux) == address(0)) _tux = IERC20(addressBook.get("tux"));
        if(address(_usdc) == address(0)) _usdc = IERC20(addressBook.get("usdc"));
        // Transfer tokens in.
        if(!_tux.transferFrom(msg.sender, address(this), amount_)) revert STAKING_transferFailed();
        // Create stake.
        _tokenIdTracker++;
        _stakeOwner[_tokenIdTracker] = msg.sender;
        _stakeAmount[_tokenIdTracker] = amount_;
        _stakeStart[_tokenIdTracker] = block.timestamp;
    }

    /**
     * Staked amount.
     * @param owner_ Owner address.
     * @return uint256 Total amount staked by owner.
     */
    function stakedAmount(address owner_) external view returns (uint256)
    {
        uint256 total;
        for(uint256 i = 1; i <= _tokenIdTracker; i++) {
            if(_stakeOwner[i] == owner_) {
                total += _stakeAmount[i];
            }
        }
        return total;
    }
}
