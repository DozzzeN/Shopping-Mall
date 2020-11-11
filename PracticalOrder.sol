pragma solidity ^0.4.23;

contract Order {
    address public owner;//A
    address public buyer;//B
    address public seller;//S
    address public express;//E
    
    uint32 public pk_e;
    uint32 public pk_s;
    uint32 public pk_b;
    uint32 public pk_a;
    
    uint32[5] C_order;
    uint32[3] C_confirm;
    uint32 C_s_k;
    uint32 C_a_k;
    
    uint32[3] C_pay;
    
    uint32[3] VC_confirm;
    uint32[4] VC_order;
    uint32[3] VC_pay;
    uint32 VC_waybill;
    uint p;

    uint32[2] enc_receive_sig;

    uint32[2] enc_return_sig;

    uint32[4] Sigma_waybill;
    uint32[3] waybill;

    uint timestamp_buyer_order;

    uint timestamp_seller_pay;
    uint time_pay;

    uint timestamp_buyer_pay;
    uint time_deposit;
    
    uint timestamp_express_pay;
    uint time_deliver;

    uint timestamp_buyer_receive;
    uint time_refund;
    //uint timestamp_buyer_refund;
    //uint time_extended_refund;
    
    uint32 n = 23 * 29;

    event OrderPlaced(string message);
    event OrderConfirmed(string message);
    event OrderPaid(string message);
    event DepositMade(string message);
    event ProductConfirmed(string message);
    event ProductReceived(string message);
    event Data(uint32 data);

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

    constructor () public {
        owner = msg.sender;
        pk_e = 3;
        pk_s = 5;
        pk_b = 13;
        pk_a = 17;
    }

    //(1)
    //[12,189,302,160016499,328],592,157
    function PlaceOrder(uint32[5] _C_order, uint32 _C_s_k, uint32 _C_a_k) public {
        require(buyer == 0x0000000000000000000000000000000000000000);
        buyer = msg.sender;
        C_order = _C_order;
        C_s_k = _C_s_k;
        C_a_k = _C_a_k;
        timestamp_buyer_order = now;
        emit OrderPlaced("Buyer places the order successfully!");
    }

    //(2)
    //[40069640764081,1600164507,537],[343,498,26]
    function ConfirmOrder(uint32[3] _C_confirm, uint32[3] _VC_confirm) payable public {
        seller = msg.sender;
        p = msg.value;
        timestamp_seller_pay = now; 
        time_pay = now + 2 hours;
        VC_confirm = _VC_confirm;
        C_confirm = _C_confirm;
        emit OrderConfirmed("Seller confirms the order successfully!");
    }

    //(3)
    //[1600165071,1600165171,337],[131,520,155]
    function PayOrder(uint32[3] _C_pay, uint32[3] _VC_pay) payable isBuyer public {
        p = msg.value;
        C_pay = _C_pay;
        VC_pay = _VC_pay;
        timestamp_buyer_pay = now;
        time_deposit = timestamp_buyer_pay + 2 hours;
        emit OrderPaid("Buyer pays the order successfully!");
    }

    // //99,634 
    // function WithdrawDeposit(uint32 _k, uint32 _Sigma_confirm) public isSeller {
    //     require(_Sigma_confirm == C_confirm[2] ^ _k);
    //     msg.sender.transfer(p);
    // }

    function WithdrawDeposit() public isSeller {
        msg.sender.transfer(p);
    }

    //(4)
    //[3,5,1],1600165200,376
    function DepositWaybill(uint32[3] _waybill, uint _timestamp_express_pay, uint32 _VC_waybill) payable public {
        express = msg.sender;
        require(p == msg.value);
        waybill = _waybill;
        VC_waybill = _VC_waybill;
        timestamp_express_pay = _timestamp_express_pay;
        time_deliver = timestamp_express_pay + 1 days;
        emit DepositMade("Express makes the deposit successfully!");
    }

    // //99,306
    // function WithdrawPayment(uint32 _k, uint32 _Sigma_pay) isBuyer public {
    //     require(_k ^ _Sigma_pay == C_pay[2]);
    //     msg.sender.transfer(p);
    // } 

    function WithdrawPayment() isBuyer public {
        msg.sender.transfer(p);
    } 

    //244
    function RedeemDeposit(uint32 _Sigma_waybill) isExpress public {
        uint32 _waybill = (waybill[0] ^ waybill[1]) ^ waybill[2];//7
        require((_waybill ^ timestamp_express_pay) % n == verify(_Sigma_waybill, pk_e));//verify the signature _Sigma_waybill
        msg.sender.transfer(p);
    }
    
    //(5)
    //244
    function PayProduct(uint32 _Sigma_waybill) isExpress public {
        uint32 _waybill = waybill[0] ^ waybill[1] ^ waybill[2];
        require((_waybill ^ timestamp_express_pay) % n == verify(_Sigma_waybill, pk_e));//verify the signature _Sigma_waybill
        seller.transfer(p);
        emit ProductConfirmed("Express confirms the product successfully!");
    }

    //99,634
    function SellerGetPaidByExpress(uint32 _k, uint32 _Sigma_confirm) isSeller public {
        require(_Sigma_confirm == C_confirm[2] ^ _k);
        msg.sender.transfer(p);
    }
    
    // //99,306
    // function BuyerGetPaidByExpress(uint32 _k, uint32 _Sigma_pay) isBuyer public {
    //     require(_k ^ _Sigma_pay == C_pay[2]);
    //     msg.sender.transfer(p);
    // }

    function BuyerGetPaidByExpress() isBuyer public {
        msg.sender.transfer(p);
    }

    // //99,306
    // function ReceiveProduct(uint32 _k, uint32 _Sigma_pay) isBuyer public {
    //     require(_k ^ _Sigma_pay == C_pay[2]);
    //     express.transfer(p);
    //     timestamp_buyer_receive = now;
    //     time_refund = timestamp_buyer_receive + 7 days;
    //     emit ProductReceived("Buyer receives and confirms the product successfully!");
    // }

    //(6)
    function ReceiveProduct() isBuyer public {
        express.transfer(p);
        timestamp_buyer_receive = now;
        time_refund = timestamp_buyer_receive + 7 days;
        emit ProductReceived("Buyer receives and confirms the product successfully!");
    }

    //244
    function GetPaidByExpress(uint32 _Sigma_waybill) isExpress public {
        uint32 _waybill = waybill[0] ^ waybill[1] ^ waybill[2];
        require((_waybill ^ timestamp_express_pay) % n == verify(_Sigma_waybill, pk_e));//verify the signature _Sigma_waybill
        msg.sender.transfer(p);
    }
    
    // //493,634
    // function GetPaidBySeller(uint32 _sk_s, uint32 _Sigma_confirm) isSeller public {
    //     uint32 k = C_s_k ^ _sk_s;
    //     require(_Sigma_confirm == C_confirm[2] ^ k);
    //     msg.sender.transfer(p);
    // }

    function GetPaidBySeller() isSeller public {
        msg.sender.transfer(p);
    }

    function verify(uint32 m, uint32 _e) public view returns (uint32) {
        uint32 c = 1;
        uint32 t = m % n;
        while (_e != 0) {
            if (_e & 1 == 1) {
                c = (c * t) % n;
            }
            _e >>= 1;
            t = (t * t) % n;
        }
        return c;
    }
}
