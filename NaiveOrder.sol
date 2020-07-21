pragma solidity ^0.4.23;

import "RSA.sol";

contract NaiveOrder {
    //{
    //  "product_name":"pen",
    //  "number":"2",
    //  "shipping_address":"0xc7eaC4D0fD7f2700cc8e0ADD2F6428310D118b02",
    //  "sig":"xxxxxxxxxx"
    //}
    //[111,222,333,317]
    address public owner;//TTP
    address public buyer;
    address public seller;
    address public express;
    
    uint256 public pk_e;
    uint256 public pk_s;
    uint256 public pk_b;
    uint256 public pk_t;
    
    uint256[4] public enc_order_and_sig;
    uint256[3] public enc_order; 
    uint256 public enc_confirmation;
    uint256 public enc_key;
    
    uint256 public venc_sig_confirmation;
    uint256 public venc_sig_order;
    uint256 public venc_sig_waybill;
    uint p;

    uint256[2] public enc_order_confirmation_and_sig;

    uint256[2] public enc_receive_sig;

    uint256[2] public enc_return_sig;

    //"3","5","000001"
    uint256[3] public waybill;

    event OrderPlaced(address buyer, string message);
    event OrderConfirmed(address seller, string message);
    event Data(string message, uint256 data);
    
    RSA public rsa;
    string string_confimation = "signature verification succeeded";
    
    //暂时让买家公私钥一致
    //3,5,13,17
    constructor (uint256 _pk_e, uint256 _pk_s, uint256 _pk_b, uint256 _pk_t) public {
        owner = msg.sender;
        pk_e = _pk_e;
        pk_s = _pk_s;
        pk_b = _pk_b;
        pk_t = _pk_t;
        rsa = new RSA();
    }

    //买方下订单
    //[12,189,302,162],592
    function PlaceOrder(uint256[4] _enc_order_and_sig, uint256 _enc_key) public {
        //只能调用一次
        require(buyer == 0x0000000000000000000000000000000000000000);
        buyer = msg.sender;
        enc_order_and_sig = _enc_order_and_sig;
        //分离出加密的订单
        for (uint i = 0; i < 3; i++) {
            enc_order[i] = _enc_order_and_sig[i];
        }
        enc_key = _enc_key;
        emit OrderPlaced(msg.sender, "places the order successfully!");
    }

    //卖方确认订单
    //493,53
    function ConfirmOrder(uint256 _sk_s, uint256 _venc_sig_confirmation) payable public {
        seller = msg.sender;
        p = msg.value;
        venc_sig_confirmation = _venc_sig_confirmation;
        //解密
        uint256 k = rsa.decode(enc_key, _sk_s);
        emit Data("key", k);
        uint256 product_name = k ^ enc_order_and_sig[0];
        emit Data("product_name", product_name);
        uint256 number = k ^ enc_order_and_sig[1];
        emit Data("number", number);
        uint256 shipping_address = k ^ enc_order_and_sig[2];
        emit Data("shipping_address", shipping_address);
        uint256 order = product_name ^ number ^ shipping_address;
        emit Data("order", order);
        uint256 order_sig = k ^ enc_order_and_sig[3];
        uint256 sig = order_sig ^ order;
        emit Data("sig", sig);
        //校验签名
        if (rsa.encode(sig, pk_b) != order) {
            emit OrderConfirmed(msg.sender, "confirm the order unsuccessfully!");
            msg.sender.transfer(p);
        } else {
            FurtherOrderVerification();
           
            bytes storage bytes32_order_confirmation = bytes (string_confimation);
            uint256 order_confirmation = bytesToUint(bytes32_order_confirmation) % rsa.getN();
            uint256 order_confirmation_sig = rsa.encode(order_confirmation, _sk_s); 

            enc_order_confirmation_and_sig[0] = order_confirmation ^ k;
            enc_confirmation = enc_order_confirmation_and_sig[0];
            enc_order_confirmation_and_sig[1] = order_confirmation_sig ^ k;
            emit OrderConfirmed(msg.sender, "confirm the order successfully!");
        }
    }

    //买家支付
    //加密的签名
    //427
    function PayOrder(uint256 _venc_sig_order) payable public {
        //p = msg.value;//还未对p的值进行校验（至少要求等于商品金额)
        venc_sig_order = _venc_sig_order;
    }

    //买家不支付
    //281
    function WithdrawDeposit(uint256 _sig_enc_confirmation) public {
        require(enc_confirmation == rsa.encode(_sig_enc_confirmation, pk_b));
        msg.sender.transfer(1 ether);
    }

    //快递抵押
    //[3,5,1],7
    function DepositWaybill(uint256[3] _waybill, uint256 _venc_sig_waybill) payable public {
        waybill = _waybill;
        express = msg.sender;
        //发货日期还未过，过了直接退还买家的存款
        venc_sig_waybill = _venc_sig_waybill;
    }

    //快递不抵押
    //[331,636,476]
    function WithdrawPayment(uint256[3] _sig_enc_order) public {
        //用自己的签名赎回
        for (uint i = 0; i < 3; i++) {
            require(enc_order[i] == rsa.encode(_sig_enc_order[i], pk_b)); 
        }
        msg.sender.transfer(1 ether);
    } 

    //卖家送货

    //卖家不送货
    //451
    function RedeemDeposit(uint256 _sig_waybill) public {
        //用自己的签名赎回
        uint256 _waybill;
        for(uint i = 0; i < 3; i++) {
            _waybill ^= waybill[i];
        }
        if (rsa.encode(_sig_waybill, pk_e) == _waybill) {
            msg.sender.transfer(1 ether);
        }
    }
    
    //快递付款
    //451
    function PayProduct(uint256 _sig_waybill) public {
        uint256 _waybill;
        for(uint i = 0; i < 3; i++) {
            _waybill ^= waybill[i];
        }
        if (rsa.encode(_sig_waybill, pk_e) == _waybill) {
            buyer.transfer(1 ether);//卖家收款
        }
    }

    //买家收货付款
    //[331,636,476]
    function ReceiveProduct(uint256[3] _sig_enc_order) public {
        for (uint i = 0; i < 3; i++) {
            require(rsa.encode(_sig_enc_order[i], pk_b) == enc_order[i]);
        }
        express.transfer(1 ether);
    }

    //买家不签收
    //_sig_enc_message = _sig_enc_confirmation/_sig_waybill
    //281
    //或
    //451
    function GetPaidBySeller(uint256 _sig_enc_message) public {
        //超过退款期限，默认买家不退货
        //快递取回抵押
        if (msg.sender == express) {
            uint256 _waybill;
            for(uint i = 0; i < 3; i++) {
                _waybill ^= waybill[i];
            }
            if (rsa.encode(_sig_enc_message, pk_e) == _waybill) {
                express.transfer(1 ether);
            }
        }
        //卖家取回抵押
        if (msg.sender == seller) {
            if (rsa.encode(_sig_enc_message, pk_b) == enc_confirmation) {
                enc_confirmation = 0;
                seller.transfer(1 ether);
            }
        }
    }

    //更进一步验证订单信息
    function FurtherOrderVerification() internal pure {}

    function bytesToUint(bytes memory b) public pure returns (uint256) {
        uint256 number;
        for (uint i = 0; i < b.length; i++) {
            number = number + uint8(b[i]) * (2 ** (8 * (b.length - (i + 1))));
        }
        return number;
    }

    function uintToBytes(uint u) public pure returns (bytes memory b) {
        assembly {
            b := mload(0x10)
            mstore(b, 0x20)
            mstore(add(b, 0x20), u)
        }
    }

    function byte32ToString(bytes32 b) public pure returns (string) {
        bytes memory names = new bytes(b.length);
        for (uint i = 0; i < b.length; i++) {
            names[i] = b[i];
        }
        return string(names);
    }

    function stringToBytes32(string memory s) public pure returns (bytes32 b) {
        bytes memory tempEmptyStringTest = bytes(s);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }
        assembly {
            b := mload(add(s, 32))
        }
    }
}
