pragma solidity ^0.4.23;

contract RSA {
    uint256 public p = 23;
    uint256 public q = 29;
    uint256 public n = p * q;
    uint256 public phi = (p - 1) * (q - 1);
    uint256 public e = 3; //3 5 7 9
    uint256 public d;
    
    // constructor() public {
    //     do {
    //         e += 2;
    //     } while (gcd(e, phi) != 1);
        
    //     for(uint k = 1; ; k++) {
    //         if((phi * k + 1) % e == 0) {
    //             d = (phi * k + 1) / e;
    //             break;
    //         }
    //     }
    // }
    
    function getN() public view returns (uint256) {
        return n;
    }
    
    function getD(uint256 _e) public view returns (uint256) {
        uint256 _d;
        for(uint k = 1; ; k++) {
            if((phi * k + 1) % _e == 0) {
                _d = (phi * k + 1) / _e;
                break;
            }
        }
        return _d;
    }
    
    function gcd(uint256 x, uint256 y) public pure returns (uint256 z) {
        z = y;
    	while(x % y != 0)
    	{
    		z = x % y;
    		x = y;
    		y = z;	
    	}
    	return z;
    }
    
    function encode(uint256 m) public view returns (uint256) {
        uint256 c = m;
        for (uint i = 1; i < e; i++) {
            c = (c * m) % n;
        }
        return c;
    }
    
    function decode(uint256 c) public view returns (uint256) {
        uint256 m = c;
        for (uint i = 1; i < d; i++) {
            m = (m * c) % n;
        }
        return m;
    }
    
     function encode(uint256 m, uint256 _e) public view returns (uint256) {
        uint256 c = m;
        for (uint i = 1; i < _e; i++) {
            c = (c * m) % n;
        }
        return c;
    }
    
    function decode(uint256 c, uint256 _d) public view returns (uint256) {
        uint256 m = c;
        for (uint i = 1; i < _d; i++) {
            m = (m * c) % n;
        }
        return m;
    }
}