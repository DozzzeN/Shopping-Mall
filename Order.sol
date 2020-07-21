pragma solidity ^0.4.23;
pragma experimental ABIEncoderV2;

contract Order {
    //{
    //  "product_name":"pen",
    //  "number":"2",
    //  "shipping_address":"0xc7eaC4D0fD7f2700cc8e0ADD2F6428310D118b02",
    //  "sig":"xxxxxxxxxx"
    //}
    //["0x70656e0000000000000000000000000000000000000000000000000000000000",
    //"0x3200000000000000000000000000000000000000000000000000000000000000",
    //"0x3078633765614334443066443766323730306363386530414444324636343238",
    //"0x026f64410415266b2f551f1b58006d5545490611386530414444324636343238"]
    address public owner;//TTP
    address public buyer;
    address public seller;
    address public express;
    
    string public pk_e;
    string public pk_s;
    string public pk_b;
    string public pk_t;
    
    bytes32[4] public enc_order_and_sig;
    bytes32[3] public enc_order; 
    bytes32 public enc_confirmation;
    bytes32 public enc_key;
    
    bytes32 public venc_sig_confirmation;
    bytes32 public venc_sig_order;
    bytes32 public venc_sig_waybill;
    uint p;

    bytes32[2] public enc_order_confirmation_and_sig;

    bytes32[2] public enc_receive_sig;

    bytes32[2] public enc_return_sig;

    string public waybill;

    uint public quantity;
    string hash_waybill;
    uint return_number;
    string hash_returned_waybill;

    uint timestamp_seller_pay;//卖家抵押付款
    uint time_pay;//买家付款期限

    uint timestamp_buyer_pay;//买家付款时戳
    uint time_deposit;//快递抵押时限
    
    uint timestamp_express_pay;//快递付款时戳
    uint time_deliver;//快递发货时限

    uint timestamp_buyer_receive;//买家收货日期
    uint time_refund;//买家退货时限
    //uint timestamp_buyer_refund;//买家退货日期
    //uint time_extended_refund;//卖家签收退货时限

    event OrderPlaced(address buyer, string message);
    event OrderConfirmed(address seller, string message);
    event Data(bytes32 data);

    modifier isSeller() {
        require(msg.sender == seller);
        _;
    }

    modifier isBuyer() {
        require(msg.sender == buyer);
        _;
    }

    modifier isExpress() {
        require(msg.sender == express);
        _;
    }

    modifier isExpressOrSeller() {
        require(msg.sender == express || msg.sender == seller);
        _;
    }

    modifier isTTP() {
        require(msg.sender == owner);
        _;
    }
    
    //暂时让买家公私钥一致
    //"private_key_of_express","public_key_of_seller","private_key_of_buyer","public_key_of_ttp"
    constructor (string _pk_e, string _pk_s, string _pk_b, string _pk_t) public {
        owner = msg.sender;
        pk_e = _pk_e;
        pk_s = _pk_s;
        pk_b = _pk_b;
        pk_t = _pk_t;

    }

    //买方下订单
    /*
    ["0x1b00170000000000000000000000000000000000000000000000000000000000",
    "0x5965790000000000000000000000000000000000000000000000000000000000",
    "0x5b1d1a3765614334443066443766323730306363386530414444324636343238",
    "0x690a1d410415266b2f551f1b58006d5545490611386530414444324636343238"],

    "0x1b101b6c69635f6b65795f6f665f73656c6c6572000000000000000000000000"
    */
    function PlaceOrder(bytes32[4] _enc_order_and_sig, bytes32 _enc_key) public {
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
    //暂时让公私钥一样
    //"public_key_of_seller","0x6368657c616557147a744310664b4f62674c1f10116365737366756c6c792100"
    function ConfirmOrder(string _sk_s, bytes32 _venc_sig_confirmation) payable public {
        seller = msg.sender;
        p = msg.value;
        timestamp_seller_pay = now;
        time_pay = now + 2 hours;//买家付款期限
        venc_sig_confirmation = _venc_sig_confirmation;
        //解密
        bytes32 k = enc_key ^ stringToBytes32(_sk_s);
        bytes32 product_name = k ^ enc_order_and_sig[0];
        emit Data(product_name);
        bytes32 number = k ^ enc_order_and_sig[1];
        emit Data(number);
        quantity = bytesToUint(bytes(byte32ToString(number)));
        bytes32 shipping_address = k ^ enc_order_and_sig[2];
        emit Data(shipping_address);
        bytes32 order = product_name ^ number ^ shipping_address;
        bytes32 order_sig = k ^ enc_order_and_sig[3];
        emit Data(order_sig);
        //校验签名
        if (order_sig ^ stringToBytes32(pk_b) != order) {
            emit OrderConfirmed(msg.sender, "confirm the order unsuccessfully!");
            msg.sender.transfer(p);//退回抵押
        } else {
            FurtherOrderVerification();
            bytes32 order_confirmation = "signature verification succeeded";
            bytes32 order_confirmation_sig = stringToBytes32(_sk_s) ^ order_confirmation;

            //enc_order_confirmation_and_sig
            //0x180c1e6e617475726520766572696669636174696f6e20737563636565646564
            //0x68797c0208172a190059290a1436150c0f0d111b6f6e20737563636565646564
            //enc_confirmation
            //0x180c1e6e617475726520766572696669636174696f6e20737563636565646564
            enc_order_confirmation_and_sig[0] = order_confirmation ^ k;
            enc_confirmation = enc_order_confirmation_and_sig[0];
            enc_order_confirmation_and_sig[1] = order_confirmation_sig ^ k;
            emit OrderConfirmed(msg.sender, "confirm the order successfully!");
        }
    }

    //买家支付
    //买家私钥签名
    //0x400a59445712536b5f54496b5e536d54431b5714353531663162353830303664
    //加密的签名
    //"0x307f3b283e710c003a2d1604380c1920331b5714353531663162353830303664"
    function PayOrder(bytes32 _venc_sig_order) payable isBuyer public {
        p = msg.value;//还未对p的值进行校验（至少要求等于商品金额)
        require(now < time_pay);
        venc_sig_order = _venc_sig_order;
        timestamp_buyer_pay = now;
        time_deposit = timestamp_buyer_pay + 1 days;//快递抵押时限
    }

    //买家不支付
    //"0x68797c0208172a190059290a1436041c1a0406696f6e20737563636565646564"
    function WithdrawDeposit(bytes32 _sig_enc_confirmation) public isSeller {
        require(now > time_pay);
        require(enc_confirmation == _sig_enc_confirmation ^ stringToBytes32(pk_b));
        msg.sender.transfer(p);
    }

    //快递抵押
     //waybill:{"public_key_of_express","public_key_of_seller","000001"}
    //快递私钥签名
    //0x404259465145655f6b65795f6f664978646e7264007300000000000000000000
    //加密的签名
    /*
    ["public_key_of_express","public_key_of_seller","000001"],
    "0x30373b2a38263a340e1c263009393d0c146e7264007300000000000000000000"
    */
    function DepositWaybill(string[3] _waybill, bytes32 _venc_sig_waybill) payable public {
        waybill = _waybill;
        express = msg.sender;
        require(p == msg.value);
        //发货日期还未过，过了直接退还买家的存款
        require(now < time_deposit);
        venc_sig_waybill = _venc_sig_waybill;
        timestamp_express_pay = now;
        time_deliver = timestamp_express_pay + 3 days;//卖家发货时限
    }

    //快递不抵押
    //卖方可以在买方退货超时后取回
    /*
    ["0x6b75756c69635f6b65795f6f665f627579657200000000000000000000000000",
    "0x29101b6c69635f6b65795f6f665f627579657200000000000000000000000000",
    "0x2b68785b0c021c5f2149392b5139504249551163386530414444324636343238"]
    */
    function WithdrawPayment(bytes32[3] _sig_enc_order) isBuyer public {
        require(now > time_deposit);
        //用自己的签名赎回
        for (uint i = 0; i < 3; i++) {
            require(enc_order[i] == _sig_enc_order[i] ^ stringToBytes32(pk_b));
        }
        msg.sender.transfer(p);
    } 

    //卖家送货

    //卖家不送货
    //"0x404259465145655f6b65795f6f664978646e7264007300000000000000000000"
    function RedeemDeposit(bytes32 _sig_waybill) isExpress public {
        require(now > time_deliver);
        //用自己的签名赎回
        bytes32 sig_waybill;
        for(uint i = 0; i < 3; i++) {
            sig_waybill ^= stringToBytes32(waybill[i]);
        }
        if (_sig_waybill ^ stringToBytes32(pk_e) == sig_waybill) {
            msg.sender.transfer(p);
        }
    }
    
    //快递付款
    //"0x404259465145655f6b65795f6f664978646e7264007300000000000000000000"
    function PayProduct(bytes32 _sig_waybill) isExpress public {
        bytes32 sig_waybill;
        for(uint i = 0; i < 3; i++) {
            sig_waybill ^= stringToBytes32(waybill[i]);
        }
        if (_sig_waybill ^ stringToBytes32(pk_e) == sig_waybill) {
            seller.transfer(p);//卖家收款
        }
    }

    //买家收货付款
    /*
    ["0x6b75756c69635f6b65795f6f665f627579657200000000000000000000000000",
    "0x29101b6c69635f6b65795f6f665f627579657200000000000000000000000000",
    "0x2b68785b0c021c5f2149392b5139504249551163386530414444324636343238"]
    */
    function ReceiveProduct(bytes32[3] _sig_enc_order) isBuyer public {
        for (uint i = 0; i < _sig_enc_order.length; i++) {
            require(enc_order[i] == _sig_enc_order[i] ^ stringToBytes32(pk_b));
        }
        express.transfer(p);
        timestamp_buyer_receive = now;
        time_refund = timestamp_buyer_receive + 7 days;
    }

    //买家不签收
    //_sig_enc_message =_sig_waybill
    //"0x404259465145655f6b65795f6f664978646e7264007300000000000000000000"
    //或
    //"0x68797c0208172a190059290a1436041c1a0406696f6e20737563636565646564"
    function GetPaidBySeller(bytes32 _sig_enc_message) isExpressOrSeller public {
        //超过退款期限，默认买家不退货
        require(now > time_refund);
        //快递取回抵押
        if (msg.sender == express) {
            bytes32 sig_waybill;
            for(uint i = 0; i < 3; i++) {
                sig_waybill ^= stringToBytes32(waybill[i]);
            }
            require (_sig_enc_message ^ stringToBytes32(pk_e) == sig_waybill);
            express.transfer(p);
        }
        //卖家取回抵押
        if (msg.sender == seller) {
            require(enc_confirmation == _sig_enc_message ^ stringToBytes32(pk_b));
            enc_confirmation == "";
            seller.transfer(p);
        }
    }

    // //买家退货
    // function RefundProduct(bytes32[2] _enc_return_sig, string pk_b, string pk_s, 
    // uint return_number, string _hash_return_waybill) isBuyer public {
    //     require(now < time_refund);
    //     enc_return_sig = _enc_return_sig;
    //     returnedWaybill.pk_b = pk_b;
    //     returnedWaybill.pk_s = pk_s;
    //     returnedWaybill.number = return_number;
    //     returnedWaybill.timestamp_buyer_refund = now; 
    //     //timestamp_buyer_refund = now;
    //     time_extended_refund = returnedWaybill.timestamp_buyer_refund + 15 days;
    //     //退货时限被延长
    //     time_refund = time_extended_refund;
    //     hash_returned_waybill = _hash_return_waybill;
    // }

    // //卖家收到退货
    // function GetReturnedProduct(uint return_number) isSeller public {
    //     require(now > returnedWaybill.timestamp_buyer_refund);
    //     //验证订单号和订单哈希
    //     require(return_number == returnedWaybill.number);
    //     buyer.transfer(waybill.amount);
    // }

    // //卖家不签收退货
    // function WithdrawFinalDepositByBuyer() isBuyer public {
    //     require(now > time_extended_refund);
    //     buyer.transfer(waybill.amount);
    // }

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
