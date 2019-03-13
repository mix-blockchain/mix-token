pragma solidity ^0.5.4;


interface MixToken {
    event Transfer(address indexed from, address indexed to, uint value, bytes data);
    event Authorize(address indexed account, address indexed authorized);
    event Unauthorize(address indexed account, address indexed unauthorized);
    function transfer(address to, uint value) external;
    function transfer(address to, uint value, bytes calldata data) external;
    function transfer(address from, address to, uint value, bytes calldata data) external;
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function decimals() external view returns (uint);
    function totalSupply() external view returns (uint);
    function balanceOf(address who) external view returns (uint);
}


interface MixTokenReceiver {
    function receiveMixToken(address from, uint value, bytes calldata data) external;
}


contract MixTokenBase is MixToken {

    mapping (address => uint) accountBalance;

    mapping (address => mapping (address => bool)) accountAuthorized;

    string tokenSymbol;
    string tokenName;
    uint tokenDecimals;
    uint tokenSupply;

    modifier hasSufficientBalance(address account, uint value) {
        require (accountBalance[account] >= value, "Insufficient balance.");
        _;
    }

    modifier isAuthorized(address account) {
        require (accountAuthorized[account][msg.sender], "Not authorized.");
        _;
    }

    function _isContract(address account) internal view returns (bool) {
        uint length;
        assembly {
            length := extcodesize(account)
        }
        return length > 0;
    }

    function _transfer(address from, address to, uint value, bytes memory data) internal hasSufficientBalance(from, value) {
        // Update balances.
        accountBalance[from] -= value;
        accountBalance[to] += value;
        // Tell the receiver they received some tokens.
        if (_isContract(to)) {
            MixTokenReceiver(to).receiveMixToken(from, value, data);
        }
        // Log the event.
        emit Transfer(from, to, value, data);
    }

    function transfer(address to, uint value) external {
        // Transfer the tokens.
        bytes memory empty;
        _transfer(msg.sender, to, value, empty);
    }

    function transfer(address to, uint value, bytes calldata data) external {
        // Transfer the tokens.
        _transfer(msg.sender, to, value, data);
    }

    function transfer(address from, address to, uint value, bytes calldata data) external isAuthorized(from) {
        // Transfer the tokens.
        _transfer(from, to, value, data);
    }

    function authorize(address account) external {
        accountAuthorized[msg.sender][account] = true;
        emit Authorize(msg.sender, account);
    }

    function unauthorize(address account) external {
        delete accountAuthorized[msg.sender][account];
        emit Unauthorize(msg.sender, account);
    }

    function symbol() external view returns (string memory) {
        return tokenSymbol;
    }

    function name() external view returns (string memory) {
        return tokenName;
    }

    function decimals() external view returns (uint) {
        return tokenDecimals;
    }

    function totalSupply() external view returns (uint) {
        return tokenSupply;
    }

    function balanceOf(address who) external view returns (uint) {
        return accountBalance[who];
    }

}