// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IStakingNft {
    function _addNextWcToRc (  ) external;
    function _rewardNextRc (  ) external;
    function _updateWcRewards (  ) external;
    function addressBook (  ) external view returns ( address );
    function approve ( address to, uint256 tokenId ) external;
    function availableDividends ( uint256 tokenId_ ) external view returns ( uint256 );
    function balanceOf ( address owner ) external view returns ( uint256 );
    function claim ( uint256 tokenId_ ) external;
    function compound ( uint256 tokenId_ ) external;
    function currentTuxPrice (  ) external view returns ( uint256 );
    function getApproved ( uint256 tokenId ) external view returns ( address );
    function isApprovedForAll ( address owner, address operator ) external view returns ( bool );
    function lastRcEntered (  ) external view returns ( uint256 );
    function lastRcRewarded (  ) external view returns ( uint256 );
    function maxRcReward (  ) external view returns ( uint256 );
    function name (  ) external view returns ( string memory );
    function owner (  ) external view returns ( address );
    function ownerOf ( uint256 tokenId ) external view returns ( address );
    function rcClaimed (  ) external view returns ( uint256 );
    function rcPending (  ) external view returns ( uint256 );
    function rcRewarded (  ) external view returns ( uint256 );
    function renounceOwnership (  ) external;
    function safeTransferFrom ( address from, address to, uint256 tokenId ) external;
    function safeTransferFrom ( address from, address to, uint256 tokenId, bytes memory data ) external;
    function setAddressBook ( address address_ ) external;
    function setApprovalForAll ( address operator, bool approved ) external;
    function setBurnPercent ( uint256 burnPercent_ ) external;
    function setMaxRcAge ( uint256 maxRcAge_ ) external;
    function setMaxRcReward ( uint256 maxRcReward_ ) external;
    function setTransferTax ( uint256 transferTax_ ) external;
    function setUpdateInterval ( uint256 updateInterval_ ) external;
    function setup (  ) external;
    function stake ( uint256 amount_ ) external;
    function supportsInterface ( bytes4 interfaceId ) external view returns ( bool );
    function symbol (  ) external view returns ( string memory );
    function tokenOfOwnerByIndex ( address owner_, uint256 index_ ) external view returns ( uint256 );
    function tokenURI ( uint256 tokenId_ ) external view returns ( string memory );
    function totalDividends (  ) external view returns ( uint256 );
    function totalRcStaked (  ) external view returns ( uint256 );
    function totalWcStaked (  ) external view returns ( uint256 );
    function transferFrom ( address from, address to, uint256 tokenId ) external;
    function transferOwnership ( address newOwner ) external;
    function unstake ( uint256 tokenId_ ) external;
    function updateRewards (  ) external;
}
