import asyncio
import copy
import math
import os
import time
import traceback
from decimal import Decimal
from enum import Enum
from logging import DEBUG, ERROR, INFO, WARNING
from os import path
from pathlib import Path
from typing import Any, Dict, List, Union

import jsonpickle
import numpy as np

from hummingbot.client.hummingbot_application import HummingbotApplication
from hummingbot.connector.gateway.clob_spot.data_sources.kujira.kujira_constants import KUJIRA_NATIVE_TOKEN
from hummingbot.connector.gateway.clob_spot.data_sources.kujira.kujira_helpers import (
    convert_hb_trading_pair_to_market_name,
)
from hummingbot.connector.gateway.clob_spot.data_sources.kujira.kujira_types import OrderSide, OrderStatus, OrderType
from hummingbot.connector.gateway.clob_spot.gateway_clob_spot import GatewayCLOBSPOT
from hummingbot.core.clock import Clock
from hummingbot.core.data_type.common import TradeType
from hummingbot.core.data_type.order_candidate import OrderCandidate
from hummingbot.core.gateway.gateway_http_client import GatewayHttpClient
from hummingbot.strategy.script_strategy_base import ScriptStrategyBase


# noinspection DuplicatedCode
class KujiraPMMExample(ScriptStrategyBase):

    class MiddlePriceStrategy(Enum):
        SAP = 'SIMPLE_AVERAGE_PRICE'
        WAP = 'WEIGHTED_AVERAGE_PRICE'
        VWAP = 'VOLUME_WEIGHTED_AVERAGE_PRICE'

    def __init__(self):
        try:
            # self._log(DEBUG, """__init__... start""")

            super().__init__()

            self._can_run: bool = True
            self._script_name = path.basename(Path(__file__))
            self._configuration = {
                "chain": "kujira",
                "network": "testnet",
                "connector": "kujira",
                "owner_address": os.environ["TEST_KUJIRA_WALLET_PUBLIC_KEY"],
                "markets": {
                    "kujira_kujira_testnet": [  # Only one market can be used for now
                        # "KUJI-DEMO",  # "kujira1suhgf5svhu4usrurvxzlgn54ksxmn8gljarjtxqnapv8kjnp4nrsqq4jjh"
                        "KUJI-USK",   # "kujira1wl003xxwqltxpg5pkre0rl605e406ktmq5gnv0ngyjamq69mc2kqm06ey6"
                        # "DEMO-USK",   # "kujira14sa4u42n2a8kmlvj3qcergjhy6g9ps06rzeth94f2y6grlat6u6ssqzgtg"
                    ]
                },
                "strategy": {
                    "layers": [
                        {
                            "bid": {
                                "quantity": 1,
                                "spread_percentage": 1,
                                "max_liquidity_in_dollars": 100
                            },
                            "ask": {
                                "quantity": 1,
                                "spread_percentage": 1,
                                "max_liquidity_in_dollars": 100
                            }
                        },
                        {
                            "bid": {
                                "quantity": 1,
                                "spread_percentage": 5,
                                "max_liquidity_in_dollars": 100
                            },
                            "ask": {
                                "quantity": 1,
                                "spread_percentage": 5,
                                "max_liquidity_in_dollars": 100
                            }
                        },
                        {
                            "bid": {
                                "quantity": 1,
                                "spread_percentage": 10,
                                "max_liquidity_in_dollars": 100
                            },
                            "ask": {
                                "quantity": 1,
                                "spread_percentage": 10,
                                "max_liquidity_in_dollars": 100
                            }
                        },
                    ],
                    "tick_interval": 59,
                    "kujira_order_type": OrderType.LIMIT,
                    "price_strategy": "middle",
                    "middle_price_strategy": "SAP",
                    "cancel_all_orders_on_start": True,
                    "cancel_all_orders_on_stop": True,
                    "run_only_once": False
                },
                "logger": {
                    "level": "DEBUG"
                }
            }
            self._owner_address = None
            self._connector_id = None
            self._quote_token_name = None
            self._base_token_name = None
            self._hb_trading_pair = None
            self._is_busy: bool = False
            self._refresh_timestamp: int
            self._gateway: GatewayHttpClient
            self._connector: GatewayCLOBSPOT
            self._market: Dict[str, Any]
            self._balances: Dict[str, Any] = {}
            self._tickers: Dict[str, Any]
            self._currently_tracked_orders_ids: [str] = []
            self._tracked_orders_ids: [str] = []
            self._open_orders: Dict[str, Any]
            self._filled_orders: Dict[str, Any]
            self._vwap_threshold = 50
            self._int_zero = int(0)
            self._float_zero = float(0)
            self._float_infinity = float('inf')
            self._decimal_zero = Decimal(0)
            self._decimal_infinity = Decimal("Infinity")
        finally:
            pass
        #     self._log(DEBUG, """__init__... end""")

    def get_markets_definitions(self) -> Dict[str, List[str]]:
        return self._configuration["markets"]

    # noinspection PyAttributeOutsideInit
    async def initialize(self, start_command):
        try:
            self._log(DEBUG, """_initialize... start""")

            self.logger().setLevel(self._configuration["logger"].get("level", "INFO"))

            # await super().initialize(start_command)
            # self.initialized = False

            self._connector_id = next(iter(self._configuration["markets"]))

            self._hb_trading_pair = self._configuration["markets"][self._connector_id][0]
            self._market_name = convert_hb_trading_pair_to_market_name(self._hb_trading_pair)

            # noinspection PyTypeChecker
            # self._connector: GatewayCLOBSPOT = self.connectors[self._connector_id]
            self._gateway: GatewayHttpClient = GatewayHttpClient.get_instance()

            # self._owner_address = self._connector.address
            self._owner_address = self._configuration["owner_address"]

            self._market = await self._get_market()

            self._base_token = self._market["baseToken"]
            self._quote_token = self._market["quoteToken"]

            self._base_token_name = self._market["baseToken"]["name"]
            self._quote_token_name = self._market["quoteToken"]["name"]

            if self._configuration["strategy"]["cancel_all_orders_on_start"]:
                await self._cancel_all_orders()

            await self._market_withdraw()

            waiting_time = self._calculate_waiting_time(self._configuration["strategy"]["tick_interval"])
            self._log(DEBUG, f"""Waiting for {waiting_time}s.""")
            self._refresh_timestamp = waiting_time + self.current_timestamp

            self.initialized = True
        except Exception as exception:
            self._handle_error(exception)

            HummingbotApplication.main_application().stop()
        finally:
            self._log(DEBUG, """_initialize... end""")

    async def on_tick(self):
        if (not self._is_busy) and (not self._can_run):
            HummingbotApplication.main_application().stop()

        if self._is_busy or (self._refresh_timestamp > self.current_timestamp):
            return

        try:
            self._log(DEBUG, """on_tick... start""")

            self._is_busy = True

            try:
                await self._market_withdraw()
            except Exception as exception:
                self._handle_error(exception)

            open_orders = await self._get_open_orders(use_cache=False)
            await self._get_filled_orders(use_cache=False)
            await self._get_balances(use_cache=False)

            open_orders_ids = list(open_orders.keys())
            await self._cancel_currently_untracked_orders(open_orders_ids)

            proposal: List[OrderCandidate] = await self._create_proposal()
            candidate_orders: List[OrderCandidate] = await self._adjust_proposal_to_budget(proposal)

            await self._replace_orders(candidate_orders)
        except Exception as exception:
            self._handle_error(exception)
        finally:
            waiting_time = self._calculate_waiting_time(self._configuration["strategy"]["tick_interval"])

            # noinspection PyAttributeOutsideInit
            self._refresh_timestamp = waiting_time + self.current_timestamp
            self._is_busy = False

            self._log(DEBUG, f"""Waiting for {waiting_time}s.""")

            self._log(DEBUG, """on_tick... end""")

            if self._configuration["strategy"]["run_only_once"]:
                HummingbotApplication.main_application().stop()

    def stop(self, clock: Clock):
        asyncio.get_event_loop().run_until_complete(self.async_stop(clock))

    async def async_stop(self, clock: Clock):
        try:
            self._log(DEBUG, """_stop... start""")

            self._can_run = False

            if self._configuration["strategy"]["cancel_all_orders_on_stop"]:
                await self.retry_async_with_timeout(self._cancel_all_orders)

            await self.retry_async_with_timeout(self._market_withdraw)

            super().stop(clock)
        finally:
            self._log(DEBUG, """_stop... end""")

    async def _create_proposal(self) -> List[OrderCandidate]:
        try:
            self._log(DEBUG, """_create_proposal... start""")

            order_book = await self._get_order_book()
            bids, asks = self._parse_order_book(order_book)

            ticker_price = await self._get_market_price()
            try:
                last_filled_order_price = await self._get_last_filled_order_price()
            except Exception as exception:
                self._handle_error(exception)

                last_filled_order_price = self._decimal_zero

            price_strategy = self._configuration["strategy"]["price_strategy"]
            if price_strategy == "ticker":
                used_price = ticker_price
            elif price_strategy == "middle":
                used_price = await self._get_market_mid_price(
                    bids,
                    asks,
                    self.MiddlePriceStrategy[
                        self._configuration["strategy"].get(
                            "middle_price_strategy",
                            "VWAP"
                        )
                    ]
                )
            elif price_strategy == "last_fill":
                used_price = last_filled_order_price
            else:
                raise ValueError("""Invalid "strategy.middle_price_strategy" configuration value.""")

            if used_price is None or used_price <= self._decimal_zero:
                raise ValueError(f"Invalid price: {used_price}")

            tick_size = Decimal(self._market["tickSize"])
            min_order_size = Decimal(self._market["minimumOrderSize"])

            client_id = 1
            proposal = []

            bid_orders = []
            for index, layer in enumerate(self._configuration["strategy"]["layers"], start=1):
                best_ask = Decimal(next(iter(asks), {"price": self._float_infinity})["price"])
                bid_quantity = int(layer["bid"]["quantity"])
                bid_spread_percentage = Decimal(layer["bid"]["spread_percentage"])
                bid_market_price = ((100 - bid_spread_percentage) / 100) * min(used_price, best_ask)
                bid_max_liquidity_in_dollars = Decimal(layer["bid"]["max_liquidity_in_dollars"])
                bid_size = bid_max_liquidity_in_dollars / bid_market_price / bid_quantity if bid_quantity > 0 else 0

                if bid_market_price < tick_size:
                    self._log(
                        WARNING,
                        f"""Skipping orders placement from layer {index}, bid price too low:\n\n{'{:^30}'.format(round(bid_market_price, 6))}"""
                    )
                elif bid_size < min_order_size:
                    self._log(
                        WARNING,
                        f"""Skipping orders placement from layer {index}, bid size too low:\n\n{'{:^30}'.format(round(bid_size, 9))}"""
                    )
                else:
                    for i in range(bid_quantity):
                        bid_order = OrderCandidate(
                            trading_pair=self._hb_trading_pair,
                            is_maker=True,
                            order_type=OrderType.LIMIT,
                            order_side=TradeType.BUY,
                            amount=bid_size,
                            price=bid_market_price
                        )

                        bid_order.client_id = str(client_id)

                        bid_orders.append(bid_order)

                        client_id += 1

            ask_orders = []
            for index, layer in enumerate(self._configuration["strategy"]["layers"], start=1):
                best_bid = Decimal(next(iter(bids), {"price": self._float_zero})["price"])
                ask_quantity = int(layer["ask"]["quantity"])
                ask_spread_percentage = Decimal(layer["ask"]["spread_percentage"])
                ask_market_price = ((100 + ask_spread_percentage) / 100) * max(used_price, best_bid)
                ask_max_liquidity_in_dollars = Decimal(layer["ask"]["max_liquidity_in_dollars"])
                ask_size = ask_max_liquidity_in_dollars / ask_market_price / ask_quantity if ask_quantity > 0 else 0

                if ask_market_price < tick_size:
                    self._log(WARNING,
                              f"""Skipping orders placement from layer {index}, ask price too low:\n\n{'{:^30}'.format(round(ask_market_price, 9))}""",
                              True)
                elif ask_size < min_order_size:
                    self._log(WARNING,
                              f"""Skipping orders placement from layer {index}, ask size too low:\n\n{'{:^30}'.format(round(ask_size, 9))}""",
                              True)
                else:
                    for i in range(ask_quantity):
                        ask_order = OrderCandidate(
                            trading_pair=self._hb_trading_pair,
                            is_maker=True,
                            order_type=OrderType.LIMIT,
                            order_side=TradeType.SELL,
                            amount=ask_size,
                            price=ask_market_price
                        )

                        ask_order.client_id = str(client_id)

                        ask_orders.append(ask_order)

                        client_id += 1

            proposal = [*proposal, *bid_orders, *ask_orders]

            self._log(DEBUG, f"""proposal:\n{self._dump(proposal)}""")

            return proposal
        finally:
            self._log(DEBUG, """_create_proposal... end""")

    async def _adjust_proposal_to_budget(self, candidate_proposal: List[OrderCandidate]) -> List[OrderCandidate]:
        try:
            self._log(DEBUG, """_adjust_proposal_to_budget... start""")

            adjusted_proposal: List[OrderCandidate] = []

            balances = await self._get_balances()
            base_balance = Decimal(balances["tokens"][self._base_token["id"]]["free"])
            quote_balance = Decimal(balances["tokens"][self._quote_token["id"]]["free"])
            current_base_balance = base_balance
            current_quote_balance = quote_balance

            for order in candidate_proposal:
                if order.order_side == TradeType.BUY:
                    if current_quote_balance > order.amount:
                        current_quote_balance -= order.amount
                        adjusted_proposal.append(order)
                    else:
                        continue
                elif order.order_side == TradeType.SELL:
                    if current_base_balance > order.amount:
                        current_base_balance -= order.amount
                        adjusted_proposal.append(order)
                    else:
                        continue
                else:
                    raise ValueError(f"""Unrecognized order size "{order.order_side}".""")

            self._log(DEBUG, f"""adjusted_proposal:\n{self._dump(adjusted_proposal)}""")

            return adjusted_proposal
        finally:
            self._log(DEBUG, """_adjust_proposal_to_budget... end""")

    async def _get_base_ticker_price(self) -> Decimal:
        try:
            self._log(DEBUG, """_get_ticker_price... start""")

            return Decimal((await self._get_ticker(use_cache=False))["price"])
        finally:
            self._log(DEBUG, """_get_ticker_price... end""")

    async def _get_last_filled_order_price(self) -> Decimal:
        try:
            self._log(DEBUG, """_get_last_filled_order_price... start""")

            last_filled_order = await self._get_last_filled_order()

            if last_filled_order:
                return Decimal(last_filled_order["price"])
            else:
                return None
        finally:
            self._log(DEBUG, """_get_last_filled_order_price... end""")

    async def _get_market_price(self) -> Decimal:
        return await self._get_base_ticker_price()

    async def _get_market_mid_price(self, bids, asks, strategy: MiddlePriceStrategy = None) -> Decimal:
        try:
            self._log(DEBUG, """_get_market_mid_price... start""")

            if strategy:
                return self._calculate_mid_price(bids, asks, strategy)

            try:
                return self._calculate_mid_price(bids, asks, self.MiddlePriceStrategy.VWAP)
            except (Exception,):
                try:
                    return self._calculate_mid_price(bids, asks, self.MiddlePriceStrategy.WAP)
                except (Exception,):
                    try:
                        return self._calculate_mid_price(bids, asks, self.MiddlePriceStrategy.SAP)
                    except (Exception,):
                        return await self._get_market_price()
        finally:
            self._log(DEBUG, """_get_market_mid_price... end""")

    async def _get_base_balance(self) -> Decimal:
        try:
            self._log(DEBUG, """_get_base_balance... start""")

            base_balance = Decimal((await self._get_balances())[self._base_token["id"]]["free"])

            return base_balance
        finally:
            self._log(DEBUG, """_get_base_balance... end""")

    async def _get_quote_balance(self) -> Decimal:
        try:
            self._log(DEBUG, """_get_quote_balance... start""")

            quote_balance = Decimal((await self._get_balances())[self._quote_token["id"]]["free"])

            return quote_balance
        finally:
            self._log(DEBUG, """_get_quote_balance... start""")

    async def _get_balances(self, use_cache: bool = True) -> Dict[str, Any]:
        try:
            self._log(DEBUG, """_get_balances... start""")

            response = None
            try:
                request = {
                    "chain": self._configuration["chain"],
                    "network": self._configuration["network"],
                    "connector": self._configuration["connector"],
                    "ownerAddress": self._owner_address,
                    "tokenIds": [KUJIRA_NATIVE_TOKEN["id"], self._base_token["id"], self._quote_token["id"]]
                }

                self._log(INFO, f"""gateway.kujira_get_balances:\nrequest:\n{self._dump(request)}""")

                if use_cache and self._balances is not None:
                    response = self._balances
                else:
                    response = await self._gateway.kujira_get_balances(request)

                    self._balances = copy.deepcopy(response)

                    self._balances["total"]["free"] = Decimal(self._balances["total"]["free"])
                    self._balances["total"]["lockedInOrders"] = Decimal(self._balances["total"]["lockedInOrders"])
                    self._balances["total"]["unsettled"] = Decimal(self._balances["total"]["unsettled"])

                    for (token, balance) in dict(response["tokens"]).items():
                        balance["free"] = Decimal(balance["free"])
                        balance["lockedInOrders"] = Decimal(balance["lockedInOrders"])
                        balance["unsettled"] = Decimal(balance["unsettled"])

                return response
            except Exception as exception:
                response = traceback.format_exc()

                raise exception
            finally:
                self._log(INFO, f"""gateway.kujira_get_balances:\nresponse:\n{self._dump(response)}""")
        finally:
            self._log(DEBUG, """_get_balances... end""")

    async def _get_market(self):
        try:
            self._log(DEBUG, """_get_market... start""")

            request = None
            response = None
            try:
                request = {
                    "chain": self._configuration["chain"],
                    "network": self._configuration["network"],
                    "connector": self._configuration["connector"],
                    "name": self._market_name
                }

                response = await self._gateway.kujira_get_market(request)

                return response
            except Exception as exception:
                response = traceback.format_exc()

                raise exception
            finally:
                self._log(INFO,
                          f"""gateway.kujira_get_market:\nrequest:\n{self._dump(request)}\nresponse:\n{self._dump(response)}""")
        finally:
            self._log(DEBUG, """_get_market... end""")

    async def _get_order_book(self):
        try:
            self._log(DEBUG, """_get_order_book... start""")

            request = None
            response = None
            try:
                request = {
                    "chain": self._configuration["chain"],
                    "network": self._configuration["network"],
                    "connector": self._configuration["connector"],
                    "marketId": self._market["id"]
                }

                response = await self._gateway.kujira_get_order_book(request)

                return response
            except Exception as exception:
                response = traceback.format_exc()

                raise exception
            finally:
                self._log(DEBUG,
                          f"""gateway.kujira_get_order_books:\nrequest:\n{self._dump(request)}\nresponse:\n{self._dump(response)}""")
        finally:
            self._log(DEBUG, """_get_order_book... end""")

    async def _get_ticker(self, use_cache: bool = True) -> Dict[str, Any]:
        try:
            self._log(DEBUG, """_get_ticker... start""")

            request = None
            response = None
            try:
                request = {
                    "chain": self._configuration["chain"],
                    "network": self._configuration["network"],
                    "connector": self._configuration["connector"],
                    "marketId": self._market["id"]
                }

                if use_cache and self._tickers is not None:
                    response = self._tickers
                else:
                    response = await self._gateway.kujira_get_ticker(request)

                    self._tickers = response

                return response
            except Exception as exception:
                response = exception

                raise exception
            finally:
                self._log(INFO,
                          f"""gateway.kujira_get_ticker:\nrequest:\n{self._dump(request)}\nresponse:\n{self._dump(response)}""")

        finally:
            self._log(DEBUG, """_get_ticker... end""")

    async def _get_open_orders(self, use_cache: bool = True) -> Dict[str, Any]:
        try:
            self._log(DEBUG, """_get_open_orders... start""")

            request = None
            response = None
            try:
                request = {
                    "chain": self._configuration["chain"],
                    "network": self._configuration["network"],
                    "connector": self._configuration["connector"],
                    "marketId": self._market["id"],
                    "ownerAddress": self._owner_address,
                    "status": OrderStatus.OPEN.value[0]
                }

                if use_cache and self._open_orders is not None:
                    response = self._open_orders
                else:
                    response = await self._gateway.kujira_get_orders(request)
                    self._open_orders = response

                return response
            except Exception as exception:
                response = traceback.format_exc()

                raise exception
            finally:
                self._log(INFO,
                          f"""gateway.kujira_get_open_orders:\nrequest:\n{self._dump(request)}\nresponse:\n{self._dump(response)}""")
        finally:
            self._log(DEBUG, """_get_open_orders... end""")

    async def _get_last_filled_order(self) -> Dict[str, Any]:
        try:
            self._log(DEBUG, """_get_last_filled_order... start""")

            filled_orders = await self._get_filled_orders()

            if len((filled_orders or {})):
                last_filled_order = list(dict(filled_orders).values())[0]
            else:
                last_filled_order = None

            return last_filled_order
        finally:
            self._log(DEBUG, """_get_last_filled_order... end""")

    async def _get_filled_orders(self, use_cache: bool = True) -> Dict[str, Any]:
        try:
            self._log(DEBUG, """_get_filled_orders... start""")

            request = None
            response = None
            try:
                request = {
                    "chain": self._configuration["chain"],
                    "network": self._configuration["network"],
                    "connector": self._configuration["connector"],
                    "marketId": self._market["id"],
                    "ownerAddress": self._owner_address,
                    "status": OrderStatus.FILLED.value[0]
                }

                if use_cache and self._filled_orders is not None:
                    response = self._filled_orders
                else:
                    response = await self._gateway.kujira_get_orders(request)
                    self._filled_orders = response

                return response
            except Exception as exception:
                response = traceback.format_exc()

                raise exception
            finally:
                self._log(DEBUG, f"""gateway.kujira_get_filled_orders:\nrequest:\n{self._dump(request)}\nresponse:\n{self._dump(response)}""")

        finally:
            self._log(DEBUG, """_get_filled_orders... end""")

    async def _replace_orders(self, proposal: List[OrderCandidate]) -> Dict[str, Any]:
        try:
            self._log(DEBUG, """_replace_orders... start""")

            response = None
            try:
                orders = []
                for candidate in proposal:
                    orders.append({
                        "clientId": candidate.client_id,
                        "marketId": self._market["id"],
                        "ownerAddress": self._owner_address,
                        "side": OrderSide.from_hummingbot(candidate.order_side).value[0],
                        "price": str(candidate.price),
                        "amount": str(candidate.amount),
                        "type": self._configuration["strategy"].get("kujira_order_type", OrderType.LIMIT).value,
                    })

                request = {
                    "chain": self._configuration["chain"],
                    "network": self._configuration["network"],
                    "connector": self._configuration["connector"],
                    "orders": orders
                }

                self._log(INFO, f"""gateway.kujira_post_orders:\nrequest:\n{self._dump(request)}""")

                if len(orders):
                    response = await self._gateway.kujira_post_orders(request)

                    self._currently_tracked_orders_ids = list(response.keys())
                    self._tracked_orders_ids.extend(self._currently_tracked_orders_ids)
                else:
                    self._log(WARNING, "No order was defined for placement/replacement. Skipping.", True)
                    response = []

                return response
            except Exception as exception:
                response = traceback.format_exc()

                raise exception
            finally:
                self._log(INFO, f"""gateway.kujira_post_orders:\nresponse:\n{self._dump(response)}""")
        finally:
            self._log(DEBUG, """_replace_orders... end""")

    async def _cancel_currently_untracked_orders(self, open_orders_ids: List[str]):
        try:
            self._log(DEBUG, """_cancel_untracked_orders... start""")

            request = None
            response = None
            try:
                untracked_orders_ids = list(set(self._tracked_orders_ids).intersection(set(open_orders_ids)) - set(self._currently_tracked_orders_ids))

                if len(untracked_orders_ids) > 0:
                    request = {
                        "chain": self._configuration["chain"],
                        "network": self._configuration["network"],
                        "connector": self._configuration["connector"],
                        "ids": untracked_orders_ids,
                        "marketId": self._market["id"],
                        "ownerAddress": self._owner_address,
                    }

                    response = await self._gateway.kujira_delete_orders(request)
                else:
                    self._log(INFO, "No order needed to be canceled.")
                    response = {}

                return response
            except Exception as exception:
                response = traceback.format_exc()

                raise exception
            finally:
                self._log(INFO,
                          f"""gateway.kujira_delete_orders:\nrequest:\n{self._dump(request)}\nresponse:\n{self._dump(response)}""")
        finally:
            self._log(DEBUG, """_cancel_untracked_orders... end""")

    async def _cancel_all_orders(self):
        try:
            self._log(DEBUG, """_cancel_all_orders... start""")

            request = None
            response = None
            try:
                request = {
                    "chain": self._configuration["chain"],
                    "network": self._configuration["network"],
                    "connector": self._configuration["connector"],
                    "marketId": self._market["id"],
                    "ownerAddress": self._owner_address,
                }

                response = await self._gateway.kujira_delete_orders_all(request)
            except Exception as exception:
                response = traceback.format_exc()

                raise exception
            finally:
                self._log(INFO,
                          f"""gateway.clob_delete_orders:\nrequest:\n{self._dump(request)}\nresponse:\n{self._dump(response)}""")
        finally:
            self._log(DEBUG, """_cancel_all_orders... end""")

    async def _market_withdraw(self):
        try:
            self._log(DEBUG, """_market_withdraw... start""")

            response = None
            try:
                request = {
                    "chain": self._configuration["chain"],
                    "network": self._configuration["network"],
                    "connector": self._configuration["connector"],
                    "marketId": self._market["id"],
                    "ownerAddress": self._owner_address,
                }

                self._log(INFO, f"""gateway.kujira_post_market_withdraw:\nrequest:\n{self._dump(request)}""")

                response = await self._gateway.kujira_post_market_withdraw(request)
            except Exception as exception:
                response = traceback.format_exc()

                raise exception
            finally:
                self._log(INFO,
                          f"""gateway.kujira_post_market_withdraw:\nresponse:\n{self._dump(response)}""")
        finally:
            self._log(DEBUG, """_market_withdraw... end""")

    async def _get_remaining_orders_ids(self, candidate_orders, created_orders) -> List[str]:
        self._log(DEBUG, """_get_remaining_orders_ids... end""")

        try:
            candidate_orders_client_ids = [order.client_id for order in candidate_orders] if len(candidate_orders) else []
            created_orders_client_ids = [order["clientId"] for order in created_orders.values()] if len(created_orders) else []
            remaining_orders_client_ids = list(set(candidate_orders_client_ids) - set(created_orders_client_ids))
            remaining_orders_ids = list(filter(lambda order: (order["clientId"] in remaining_orders_client_ids), created_orders.values()))

            self._log(INFO, f"""remaining_orders_ids:\n{self._dump(remaining_orders_ids)}""")

            return remaining_orders_ids
        finally:
            self._log(DEBUG, """_get_remaining_orders_ids... end""")

    async def _get_duplicated_orders_ids(self) -> List[str]:
        self._log(DEBUG, """_get_duplicated_orders_ids... start""")

        try:
            open_orders = (await self._get_open_orders()).values()

            open_orders_map = {}
            duplicated_orders_ids = []

            for open_order in open_orders:
                if open_order["clientId"] == "0":  # Avoid touching manually created orders.
                    continue
                elif open_order["clientId"] not in open_orders_map:
                    open_orders_map[open_order["clientId"]] = [open_order]
                else:
                    open_orders_map[open_order["clientId"]].append(open_order)

            for orders in open_orders_map.values():
                orders.sort(key=lambda order: order["id"])

                duplicated_orders_ids = [
                    *duplicated_orders_ids,
                    *[order["id"] for order in orders[:-1]]
                ]

            self._log(INFO, f"""duplicated_orders_ids:\n{self._dump(duplicated_orders_ids)}""")

            return duplicated_orders_ids
        finally:
            self._log(DEBUG, """_get_duplicated_orders_ids... end""")

    # noinspection PyMethodMayBeStatic
    def _parse_order_book(self, orderbook: Dict[str, Any]) -> List[Union[List[Dict[str, Any]], List[Dict[str, Any]]]]:
        bids_list = []
        asks_list = []

        bids: Dict[str, Any] = orderbook["bids"]
        asks: Dict[str, Any] = orderbook["asks"]

        for value in bids.values():
            bids_list.append({'price': value["price"], 'amount': value["amount"]})

        for value in asks.values():
            asks_list.append({'price': value["price"], 'amount': value["amount"]})

        bids_list.sort(key=lambda x: x['price'], reverse=True)
        asks_list.sort(key=lambda x: x['price'], reverse=False)

        return [bids_list, asks_list]

    def _split_percentage(self, bids: [Dict[str, Any]], asks: [Dict[str, Any]]) -> List[Any]:
        asks = asks[:math.ceil((self._vwap_threshold / 100) * len(asks))]
        bids = bids[:math.ceil((self._vwap_threshold / 100) * len(bids))]

        return [bids, asks]

    # noinspection PyMethodMayBeStatic
    def _compute_volume_weighted_average_price(self, book: [Dict[str, Any]]) -> np.array:
        prices = [float(order['price']) for order in book]
        amounts = [float(order['amount']) for order in book]

        prices = np.array(prices)
        amounts = np.array(amounts)

        vwap = (np.cumsum(amounts * prices) / np.cumsum(amounts))

        return vwap

    # noinspection PyMethodMayBeStatic
    def _remove_outliers(self, order_book: [Dict[str, Any]], side: OrderSide) -> [Dict[str, Any]]:
        prices = [order['price'] for order in order_book]

        q75, q25 = np.percentile(prices, [75, 25])

        # https://www.askpython.com/python/examples/detection-removal-outliers-in-python
        # intr_qr = q75-q25
        # max_threshold = q75+(1.5*intr_qr)
        # min_threshold = q75-(1.5*intr_qr) # Error: Sometimes this function assigns negative value for min

        max_threshold = q75 * 1.5
        min_threshold = q25 * 0.5

        orders = []
        if side == OrderSide.SELL:
            orders = [order for order in order_book if order['price'] < max_threshold]
        elif side == OrderSide.BUY:
            orders = [order for order in order_book if order['price'] > min_threshold]

        return orders

    def _calculate_mid_price(self, bids: [Dict[str, Any]], asks: [Dict[str, Any]], strategy: MiddlePriceStrategy) -> Decimal:
        if strategy == self.MiddlePriceStrategy.SAP:
            bid_prices = [float(item['price']) for item in bids]
            ask_prices = [float(item['price']) for item in asks]

            best_ask_price = 0
            best_bid_price = 0

            if len(ask_prices) > 0:
                best_ask_price = min(ask_prices)

            if len(bid_prices) > 0:
                best_bid_price = max(bid_prices)

            return Decimal((best_ask_price + best_bid_price) / 2.0)
        elif strategy == self.MiddlePriceStrategy.WAP:
            bid_prices = [float(item['price']) for item in bids]
            ask_prices = [float(item['price']) for item in asks]

            best_ask_price = 0
            best_ask_volume = 0
            best_bid_price = 0
            best_bid_amount = 0

            if len(ask_prices) > 0:
                best_ask_idx = ask_prices.index(min(ask_prices))
                best_ask_price = float(asks[best_ask_idx]['price'])
                best_ask_volume = float(asks[best_ask_idx]['amount'])

            if len(bid_prices) > 0:
                best_bid_idx = bid_prices.index(max(bid_prices))
                best_bid_price = float(bids[best_bid_idx]['price'])
                best_bid_amount = float(bids[best_bid_idx]['amount'])

            if best_ask_volume + best_bid_amount > 0:
                return Decimal(
                    (best_ask_price * best_ask_volume + best_bid_price * best_bid_amount)
                    / (best_ask_volume + best_bid_amount)
                )
            else:
                return self._decimal_zero
        elif strategy == self.MiddlePriceStrategy.VWAP:
            bids, asks = self._split_percentage(bids, asks)

            if len(bids) > 0:
                bids = self._remove_outliers(bids, OrderSide.BUY)

            if len(asks) > 0:
                asks = self._remove_outliers(asks, OrderSide.SELL)

            book = [*bids, *asks]

            if len(book) > 0:
                vwap = self._compute_volume_weighted_average_price(book)

                return Decimal(vwap[-1])
            else:
                return self._decimal_zero
        else:
            raise ValueError(f'Unrecognized mid price strategy "{strategy}".')

    # noinspection PyMethodMayBeStatic
    def _calculate_waiting_time(self, number: int) -> int:
        current_timestamp_in_milliseconds = int(time.time() * 1000)
        result = number - (current_timestamp_in_milliseconds % number)

        return result

    async def retry_async_with_timeout(self, function, *arguments, number_of_retries=3, timeout_in_seconds=60, delay_between_retries_in_seconds=0.5):
        for retry in range(number_of_retries):
            try:
                return await asyncio.wait_for(function(*arguments), timeout_in_seconds)
            except asyncio.TimeoutError:
                self._log(ERROR, f"TimeoutError in the attempt {retry+1} of {number_of_retries}.", True)
            except Exception as exception:
                message = f"""ERROR in the attempt {retry+1} of {number_of_retries}: {type(exception).__name__} {str(exception)}"""
                self._log(ERROR, message, True)
            await asyncio.sleep(delay_between_retries_in_seconds)
        raise Exception(f"Operation failed with {number_of_retries} attempts.")

    def _log(self, level: int, message: str, *args, **kwargs):
        # noinspection PyUnresolvedReferences
        message = f"""{message}"""

        self.logger().log(level, message, *args, **kwargs)

    def _handle_error(self, exception: Exception):
        message = f"""ERROR: {type(exception).__name__} {str(exception)}"""
        self._log(ERROR, message, True)

    @staticmethod
    def _dump(target: Any):
        try:
            return jsonpickle.encode(target, unpicklable=True, indent=2)
        except (Exception,):
            return target
