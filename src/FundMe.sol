// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {PriceConverter} from "./PriceConverter.sol";

error FundMe_NotOwner();

contract FundMe {
    using PriceConverter for uint256;

    mapping(address => uint256) private s_addressToAmountFunded;

    address[] private s_funders;

    uint256 public constant MINIMUM_USD = 5e18;
    address private immutable i_owner;
    AggregatorV3Interface private s_priceFeed;

    constructor(address priceFeed) {
        s_priceFeed = AggregatorV3Interface(priceFeed);
        i_owner = msg.sender;
    }

    function fund() public payable {
        require(msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD, "Less than minimum amount of eth.");
        s_addressToAmountFunded[msg.sender] += msg.value;
        s_funders.push(msg.sender);
    }

    modifier onlyOwner() {
        if (msg.sender != i_owner) revert FundMe_NotOwner();
        _;
    }

    function getVersion() public view returns (uint256) {
        return s_priceFeed.version();
    }

    function withdraw() public onlyOwner {
        for (uint256 idx = 0; idx < s_funders.length; idx++) {
            address addressoffunder = s_funders[idx];
            s_addressToAmountFunded[addressoffunder] = 0;
        }
        // payable(msg.sender).transfer(address(this).balance);
        // bool success = payable(msg.sender).send(address(this).balance);
        // require(success,"error while withdraw");
        s_funders = new address[](0);
        (bool callSuccess,) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Withdrawal failed.");
    }

    function withdrawCheaper() public onlyOwner {
        uint256 funderLength = s_funders.length;
        for (uint256 idx = 0; idx < funderLength; idx++) {
            address addressoffunder = s_funders[idx];
            s_addressToAmountFunded[addressoffunder] = 0;
        }
        // payable(msg.sender).transfer(address(this).balance);
        // bool success = payable(msg.sender).send(address(this).balance);
        // require(success,"error while withdraw");
        s_funders = new address[](0);
        (bool callSuccess,) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Withdrawal failed.");
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }

    // getter functions
    function getAdressToAmountFunded(address fundingAddress) external view returns (uint256) {
        return s_addressToAmountFunded[fundingAddress];
    }

    function getFunder(uint256 index) external view returns (address) {
        return s_funders[index];
    }

    function getOwner() external view returns (address) {
        return i_owner;
    }
}
