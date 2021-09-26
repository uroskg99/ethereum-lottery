from scripts.help import get_account, get_contract, fund_with_link_token
from brownie import Lottery, network, config
import time


def deploy_lottery():
    account = get_account()
    lottery = Lottery.deploy(
        get_contract("eth_usd_price_feed").address,
        get_contract("vrf_coordinator").address,
        get_contract("link_token").address,
        config["networks"][network.show_active()]["fee"],
        config["networks"][network.show_active()]["keyhash"],
        {"from": account},
        publish_source=config["networks"][network.show_active()].get("verify", False),
    )
    print("Kontrakt je deploy-ovan")
    return lottery


def start_lottery():
    account = get_account()
    lottery = Lottery[-1]
    starting_tx = lottery.startLottery({"from": account})
    starting_tx.wait(1)
    print("Pokrenuta lutrija")


def vote_to_raise():
    account = get_account()
    lottery = Lottery[-1]
    tx = lottery.voteForRaise({"from": account})
    tx.wait(1)
    print("Igrac je glasao da se duplira ulog!")


def vote_not_to_raise():
    account = get_account()
    lottery = Lottery[-1]
    tx = lottery.voteForNotRaise({"from": account})
    tx.wait(1)
    print("Igrac je glasao da se ulog ne duplira!")


def enter_lottery():
    account = get_account()
    lottery = Lottery[-1]
    value = lottery.getEntranceFee() + 1000000000
    tx = lottery.enter({"from": account, "value": value})
    tx.wait(1)
    print("Uspesno ste se platili ucesce za lutriju")


def end_lottery():
    account = get_account()
    lottery = Lottery[-1]
    tx = fund_with_link_token(lottery)
    tx.wait(1)
    ending_transaction = lottery.endLottery({"from": account})
    ending_transaction.wait(1)
    # sleep jer treba da se izvrse ove funkcije za rendom broj
    time.sleep(60)
    print("Pobednik je izracunat!")


def main():
    deploy_lottery()
    vote_to_raise()
    start_lottery()
    enter_lottery()
    end_lottery()
