pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract AES is ERC20 {
    constructor() ERC20("AES", "aestandard.finance") {
        _mint(msg.sender, 10000000 * (10 ** 18));
    }

    function decimals() public view virtual override returns (uint8) {
      return 9;
    }
}
