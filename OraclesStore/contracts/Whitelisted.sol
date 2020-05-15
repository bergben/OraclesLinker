pragma solidity >=0.5.17;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";


/**
 * @title Whitelisted
 * @notice Allows the owner to add and remove addresses from a whitelist
 */
contract Whitelisted is Ownable {
    mapping(address => bool) public whitelisted;

    event AddedToWhitelist(address whiteListedAddress);
    event RemovedFromWhitelist(address whiteListedAddress);

    /**
     * @notice Adds an address to the whitelist
     * @param _whiteListedAddress The address to whitelist
     */
    function addToWhitelist(address _whiteListedAddress) external onlyOwner() {
        whitelisted[_whiteListedAddress] = true;
        emit AddedToWhitelist(_whiteListedAddress);
    }

    /**
     * @notice Removes an address from the whitelist
     * @param _whiteListedAddress The address to remove
     */
    function removeFromWhitelist(address _whiteListedAddress) external onlyOwner() {
        delete whitelisted[_whiteListedAddress];
        emit RemovedFromWhitelist(_whiteListedAddress);
    }

    /**
     * @dev reverts if the caller is not whitelisted
     */
    modifier onlyWhitelisted() {
        require(whitelisted[msg.sender], "Permission denied: Not whitelisted");
        _;
    }
}
