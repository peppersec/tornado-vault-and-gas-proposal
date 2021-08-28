// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

interface IWETH {
    function balanceOf(address account) external view returns (uint256);
    function deposit() external payable;
    function withdraw(uint wad) external; 
    function totalSupply() external view returns (uint);
    function approve(address guy, uint wad) external returns (bool);
    function transfer(address dst, uint wad) external returns (bool);
    function transferFrom(address src, address dst, uint wad)
        external
        returns (bool);
}