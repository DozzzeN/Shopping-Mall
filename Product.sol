pragma solidity ^0.4.23;

contract Product {
    string seller_name;
    string product_name;
    int quantity;
    string category;
    string origin_place;
    string specification;
    int price;
    address seller_address;
    address shipping_address;

    //Bob,pen,100,stationery,China,box,30
    constructor (
        string _seller_name,
        string _product_name,
        int _quantity,
        string _category,
        string _origin_place,
        string _specification,
        int _price
    ) public {
        seller_name = _seller_name;
        product_name = _product_name;
        quantity = _quantity;
        category = _category;
        origin_place = _origin_place;
        specification = _specification;
        price = _price;

        seller_address = msg.sender;
    }
}
