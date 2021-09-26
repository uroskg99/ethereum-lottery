// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.6/VRFConsumerBase.sol";

contract Lottery is VRFConsumerBase, Ownable {
    address payable[] public players;
    uint256 public entryFeeUSD;
    AggregatorV3Interface internal ethUsdPriceFee;
    enum STATE {
        OPEN,
        CLOSED,
        CALCULATING_WINNER
    }

    STATE public current_state;
    uint256 public fee;
    bytes32 public keyhash;
    address payable public lastWinner;
    uint256 public random;
    uint256 public winnerIndex;
    event RequestedRandomness(bytes32 requestId);

    address[] public votedToRaise;
    address[] public votedNotToRaise;

    constructor(
        address _priceFeeAddress,
        address _vrfCoordinator,
        address _link,
        uint256 _fee,
        bytes32 _keyhash
    ) public VRFConsumerBase(_vrfCoordinator, _link) {
        entryFeeUSD = 50 * (10**18);
        ethUsdPriceFee = AggregatorV3Interface(_priceFeeAddress);
        current_state = STATE.CLOSED;
        fee = _fee;
        keyhash = _keyhash;
    }

    function getEntranceFee() public view returns (uint256) {
        (, int256 price, , , ) = ethUsdPriceFee.latestRoundData();
        uint256 adjustedPrice = uint256(price) * 10**10; //da bi imalo 18 decimala
        uint256 costToEnter = (entryFeeUSD * 10**18) / adjustedPrice;
        return costToEnter;
    }

    function voteForRaise() public {
        uint256 alreadyVoted;
        for (uint256 i = 0; i < votedToRaise.length; i++) {
            if (msg.sender == votedToRaise[i]) {
                alreadyVoted = 1;
            }
        }
        for (uint256 i = 0; i < votedNotToRaise.length; i++) {
            if (msg.sender == votedNotToRaise[i]) {
                alreadyVoted = 1;
            }
        }
        require(alreadyVoted == 0, "Vec ste glasali");
        require(
            current_state == STATE.CLOSED,
            "Igra je vec zapoceta, sacekajte da se zavrsi"
        );
        votedToRaise.push(msg.sender);
    }

    function voteForNotRaise() public {
        uint256 alreadyVoted;
        for (uint256 i = 0; i < votedToRaise.length; i++) {
            if (msg.sender == votedToRaise[i]) {
                alreadyVoted = 1;
            }
        }
        for (uint256 i = 0; i < votedNotToRaise.length; i++) {
            if (msg.sender == votedNotToRaise[i]) {
                alreadyVoted = 1;
            }
        }
        require(alreadyVoted == 0, "Vec ste glasali");
        require(
            current_state == STATE.CLOSED,
            "Igra je vec zapoceta, sacekajte da se zavrsi"
        );
        votedNotToRaise.push(msg.sender);
    }

    function startLottery() public onlyOwner {
        require(
            current_state == STATE.CLOSED,
            "Jos uvek nije dozvoljeno pokretanje igre"
        );
        if (votedToRaise.length > votedNotToRaise.length) {
            entryFeeUSD = entryFeeUSD * 2;
        }
        current_state = STATE.OPEN;
        random = 0;
    }

    function enter() public payable {
        require(current_state == STATE.OPEN);
        require(msg.value >= getEntranceFee(), "Nedovoljno ETH!");
        players.push(payable(msg.sender));
    }

    function endLottery() public onlyOwner {
        current_state = STATE.CALCULATING_WINNER;

        //princip request-receive
        bytes32 requestId = requestRandomness(keyhash, fee);
        emit RequestedRandomness(requestId);
    }

    function fulfillRandomness(bytes32 _requestId, uint256 _random)
        internal
        override
    {
        require(
            current_state == STATE.CALCULATING_WINNER,
            "Nemoguce je pokrenuti ovu funkciju jos uvek"
        );
        require(_random > 0, "Nije izracunat pobednik");
        winnerIndex = _random % players.length;
        lastWinner = players[winnerIndex];
        lastWinner.transfer(address(this).balance);

        // nova lutrija
        players = new address payable[](0);
        votedToRaise = new address[](0);
        votedNotToRaise = new address[](0);
        current_state = STATE.CLOSED;
        random = _random;
    }
}
