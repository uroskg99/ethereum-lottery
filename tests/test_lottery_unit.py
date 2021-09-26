from scripts.help import (
    LOCAL_BLOCKCHAIN_ENVIRONMENTS,
    get_account,
    fund_with_link_token,
    get_contract,
)
from brownie import Lottery, accounts, config, network, exceptions
from scripts.deploy import deploy_lottery
from web3 import Web3
import pytest


def test_can_pick_winner():
    if network.show_active() not in LOCAL_BLOCKCHAIN_ENVIRONMENTS:
        pytest.skip()
    lottery = deploy_lottery()
    account = get_account()
    lottery.startLottery({"from": account})
    lottery.enter({"from": account, "value": lottery.getEntranceFee()})
    lottery.enter({"from": get_account(index=1), "value": lottery.getEntranceFee()})
    lottery.enter({"from": get_account(index=2), "value": lottery.getEntranceFee()})
    fund_with_link_token(lottery)
    transaction = lottery.endLottery({"from": account})
    request_id = transaction.events["RequestedRandomness"]["requestId"]
    RNG = 1000
    get_contract("vrf_coordinator").callBackWithRandomness(
        request_id, RNG, lottery.address, {"from": account}
    )
    starting_balance_of_account = account.balance()
    balance_of_lottery = lottery.balance()
    assert lottery.lastWinner() == get_account(index=1)
    assert lottery.balance() == 0
    assert account.balance() == starting_balance_of_account + balance_of_lottery
