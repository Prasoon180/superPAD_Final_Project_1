//SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

/// @title A simple Time Lock contract
/// @author K1-R1
/// @notice Contract owner can queue a unique transaction, but must wait a
/// defined delay before executing; allowing other users to react to the transaction before it executes
/// @dev Queued transactions must be scheduled to execute within a valid range as defined by MIN_DELAY
/// and MAX_DELAY. Only the owner (deployer) can execute a transaction, as long as delay has been
/// observed and the transaction is within the grace period after the specific timestamp scheduled for
/// said transaction.
contract TimeLock {
error NotOwnerError();
error AlreadyQueuedError(bytes32 txId);
error TimestampNotInRangeError(
uint256 blockTimestamp,
uint256 inputTimestamp
);
error NotQueuedError(bytes32 txId);
error DelayNotPassedError(uint256 blockTimestamp, uint256 inputTimestamp);
error TimestampExpiredError(
uint256 blockTimestamp,
uint256 expiryTimestamp
);
error TxFailedError();

event TxQueued(
bytes32 indexed txId,
address indexed target,
uint256 value,
string func,
bytes data,
uint256 timestamp
);
event TxExecuted(
bytes32 indexed txId,
address indexed target,
uint256 value,
string func,
bytes data,
uint256 timestamp
);
event TxCancelled(bytes32 indexed txId);

address public Owner;

mapping(bytes32 => bool) public isTxQueued; //Checks if a specific Transaction Id is currently queued

constructor() {

Owner = msg.sender;
}
uint public constant MIN_DELAY = 864009;
uint public constant MAX_DELAY = 172791;
uint public constant GRACE_PERIOD = 1000;

receive() external payable {}

modifier onlyOwner() {
if (msg.sender != Owner) {
    revert NotOwnerError();
}
_;
}

//Queue a valid transaction, that can only be executed after some delay
function queue(
address _target, //address to call
uint256 _value, //value of ETH (in wei) to send
string calldata _func, //function on target to call
bytes calldata _data, //data to pass to _func
uint256 _timestamp //timestamp after which transaction can be executed
) external onlyOwner {
//Get tx id
bytes32 txId = getTxId(_target, _value, _func, _data, _timestamp);
//check txid is unique (not already queued)
if (isTxQueued[txId]) {
    revert AlreadyQueuedError(txId);
}
//check timestamp is within valid range
if (
    _timestamp < block.timestamp + MIN_DELAY ||
    _timestamp > block.timestamp + MAX_DELAY
) {
    revert TimestampNotInRangeError(block.timestamp, _timestamp);
}
//queue tx
isTxQueued[txId] = true;

emit TxQueued(txId, _target, _value, _func, _data, _timestamp);
}

//Get ID of transaction derived from inputs via hashing
function getTxId(
address _target, //address to call
uint256 _value, //value of ETH (in wei) to send
string calldata _func, //function on target to call
bytes calldata _data, //data to pass to _func
uint256 _timestamp //timestamp after which transaction can be executed
) public pure returns (bytes32 txId) {
return keccak256(abi.encode(_target, _value, _func, _data, _timestamp));
}

//Execute valid transaction
function execute(
address _target, //address to call
uint256 _value, //value of ETH (in wei) to send
string calldata _func, //function on target to call
bytes calldata _data, //data to pass to _func
uint256 _timestamp //timestamp after which transaction can be executed
) external payable onlyOwner returns (bytes memory) {
//Get tx id
bytes32 txId = getTxId(_target, _value, _func, _data, _timestamp);
//Check tx is queued
if (!isTxQueued[txId]) {
    revert NotQueuedError(txId);
}
//Check delay has passed
if (block.timestamp < _timestamp) {
    revert DelayNotPassedError(block.timestamp, _timestamp);
}
//check that timestamp is within valid execution range (grace period)
if (block.timestamp > _timestamp + GRACE_PERIOD) {
    revert TimestampExpiredError(
        block.timestamp,
        _timestamp + GRACE_PERIOD
    );
}
//Remove tx from queue
isTxQueued[txId] = false;
//Setup data for call
bytes memory data;
if (bytes(_func).length > 0) {
    data = abi.encodePacked(bytes4(keccak256(bytes(_func))), _data);
} else {
    data = _data;
}
//execute tx
(bool success, bytes memory result) = _target.call{value: _value}(data);
if (!success) {
    revert TxFailedError();
}

emit TxExecuted(txId, _target, _value, _func, _data, _timestamp);

return result;
}

//Cancel a queued transaction
function cancel(bytes32 _txId) external onlyOwner {
//Check tx is queued
if (!isTxQueued[_txId]) {
    revert NotQueuedError(_txId);
}
// //Remove tx from queue
isTxQueued[_txId] = false;

emit TxCancelled(_txId);
}
}

//A simple test contract
contract TestTimeLock {
address public timeLock;

constructor(address _timeLock) {
timeLock = _timeLock;
}

function test() external view  {
require(msg.sender == timeLock);
// potentially malicious code
}

//Simple test example
function getTimestamp() external view returns (uint256) {
return block.timestamp + 100;
}
}
