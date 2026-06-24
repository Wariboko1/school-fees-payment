// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {PriceConverter} from "./PriceConverter.sol";
import {MockV3Aggregator} from "./MockV3Aggregator.sol";

error FundMe_NotOwner;

contract FundMe {
    using PriceConverter for uint256;

    mapping(address => uint256) private s_addressToAmountFunded;
    address[] private s_funders;

    address private immutable i_owner;
    uint256 public constant MINIMUM_USD = 5 * 10 ** 18;
    MockV3Aggregator private s_priceFeed;

    constructor(address priceFeed) {
        i_owner = msg.sender;
        s_priceFeed = MockV3Aggregator(priceFeed);
    }

    function fund() public payable {
        require(
            msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD,  // assuming library function needs aggregator
            "You are to send more ETH!"
        );
        s_addressToAmountFunded[msg.sender] += msg.value;
        s_funders.push(msg.sender);
    }

    function withdraw() public onlyOwner {
        for (uint256 i = 0; i < s_funders.length; i++) {
            s_addressToAmountFunded[s_funders[i]] = 0;
        }
        s_funders = new address[](0);

        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success, "Call failed");
    }

    modifier onlyOwner() {
        if (msg.sender != i_owner) revert FundMe_NotOwner;
        _;
    }

    receive() external payable { fund(); }
    fallback() external payable { fund(); }

    // Getters
    function getOwner() public view returns(address) {
        return i_owner;
    }

    function getAddressToAmountFunded(address fundingAddress) public view returns(uint256) {
        return s_addressToAmountFunded[fundingAddress];
    }

    function getFunder(uint256 index) public view returns(address) {
        return s_funders[index];
    }

    function getVersion() public pure returns(uint256) {
        return 4;
    }
}