// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IWhiteCarpet {
    function addressBook (  ) external view returns ( address );
    function claim ( uint256 tokenId_, address recipient_ ) external;
    function compound ( uint256 tokenId_ ) external;
    function distribute (  ) external;
    function getStake ( uint256 tokenId_ ) external view returns ( uint256 stakeAmount, uint256 lastAction, uint256 availableDividends );
    function owner (  ) external view returns ( address );
    function renounceOwnership (  ) external;
    function setAddressBook ( address address_ ) external;
    function setup (  ) external;
    function stake ( uint256 tokenId_, uint256 amount_ ) external;
    function transferOwnership ( address newOwner ) external;
    function unstake ( uint256 tokenId_, address recipient_ ) external;
}
