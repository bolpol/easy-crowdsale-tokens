pragma solidity ^0.4.10;
/**
* @author  : telegram @bolpol
* @license : GPL v3.0
*/

/**
 * Math operations with safety checks
 */
library SafeMath
{
  function mul(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

}

contract StandartToken
{

    using SafeMath for uint;

    address _owner;
    uint256 public availableSupply;
    string public name = "Name of tokens";            // ! change before send
    string public symbol = "NAME";                    // ! change before send
    uint256 public constant decimals = 18;
    uint256 public totalSupply = 360000000;           // token's volume
    uint public buyPrice = 1000000000000000000 wei;   // ~ 1 ether default
    uint256 DEC = 10 ** uint256(decimals);
    // This creates an array with all balances
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed __owner, address indexed _spender, uint256 _value);
    event Burn(address indexed _from, uint256 _value);
    event Emit(address indexed _to, uint256 _value);

    // Set admin rules
    modifier onlyOwner() {
      assert(msg.sender == _owner);
      _;
    }

    /**
     * Constrctor function
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    function StandartToken() public {}

    function _transfer(address _from, address _to, uint _value) internal
    {
        require(_to != 0x0);                                 // Prevent transfer to 0x0 address. Use burn() instead
        require(balanceOf[_from] >= _value);                 // Check if the sender has enough
        require(balanceOf[_to] + _value > balanceOf[_to]);   // Check for overflows
        balanceOf[_from] = balanceOf[_from].sub(_value);     // Subtract from the sender
        balanceOf[_to] = balanceOf[_to].add(_value);
        Transfer(_from, _to, _value);
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        /*assert(balanceOf[_from] + balanceOf[_to] == previousBalances);*/
    }

    function transfer(address _to, uint256 _value) public
    {
        _transfer(msg.sender, _to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) internal
        returns (bool success)
    {
        require(_value <= allowance[_from][msg.sender]);      // Check allowance
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) internal
        returns (bool success)
	  {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    function burn(uint256 _value) public onlyOwner
		    returns (bool success)
	  {
        require(balanceOf[msg.sender] >= _value);          // Check if the sender has enough
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);    // Subtract from the sender
        //totalSupply = totalSupply.sub(_value);           // Updates total supply
        availableSupply = availableSupply.sub(_value);     // Update available supply
        Burn(msg.sender, _value);
        return true;
    }

    function emitNewTokens(uint256 _value) public onlyOwner
		    returns (bool success)
	  {
        balanceOf[msg.sender] = balanceOf[msg.sender].add(_value);    // Subtract from the sender
        totalSupply = totalSupply.add(_value);             // Updates total supply
        availableSupply = availableSupply.add(_value);     // Update available supply
        Emit(msg.sender, _value);
        return true;
    }

    function burnFrom(address _from, uint256 _value) public onlyOwner
		    returns (bool success)
	  {
        require(balanceOf[_from] >= _value);                // Check if the targeted balance is enough
        require(_value <= allowance[_from][msg.sender]);    // Check allowance
        balanceOf[_from] = balanceOf[_from].sub(_value);    // Subtract from the targeted balance
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);      // Subtract from the sender's allowance
        //totalSupply = totalSupply.sub(_value);            // Update total supply
        availableSupply = availableSupply.sub(_value);      // Update available supply
        Burn(_from, _value);
        return true;
    }

}

contract CrowdSaleContract is StandartToken
{
    using SafeMath for uint;

    address _multiWalletContract;
    bool public crowdIsNow = false;
    bool public crowdIsFinished = false;
    uint public crowdStage = 0;

    struct CrowdData {
      uint date;
      uint tokens;
    }

    CrowdData public Crowd;

    /* -- Constructor -- */
    function CrowdSaleContract(address multiWalletContract) public
        StandartToken()
    {
        totalSupply = totalSupply * DEC;                      // Update total supply with the decimal amount
        _multiWalletContract = multiWalletContract;           // set address of wallet-contract
        _owner = multiWalletContract;                         // set admin rights wallet-contract
        balanceOf[_multiWalletContract] = totalSupply;        // give all initial tokens to the wallet-contract
        availableSupply = balanceOf[_multiWalletContract];    // make more logical var. for getting of available token's amount
    }

    /**
    *
    * Expanding of the functionality
    *
    */
    function ChangeRate(uint256 _numerator, uint256 _denominator) public onlyOwner
        returns (bool success)
    {
        if (_denominator == 0) _denominator = 1;
        buyPrice = (_numerator * 1 * DEC) / _denominator;
        return true;
    }

    /**
    *
    * ICO block set amout tokens
    *
    */
    function StartCrowd(uint _crowdDays, uint _tokensForCrowd) public onlyOwner
        returns (bool success)
    {
        crowdIsFinished = false;                                // set correct value
        Crowd = CrowdData(now + _crowdDays * 1 days, _tokensForCrowd * DEC);
        crowdIsNow = true;
        crowdStage += 1;
        return true;
    }

    /* manual end */
    function FinishCrowdManually() public onlyOwner
        returns (bool success)
    {
        require(crowdIsNow);
        crowdIsNow = false;
        crowdIsFinished = true;
        return true;
    }

    /* automatical end */
    function finishCrowding() internal
        returns (bool success)
    {
        require(crowdIsNow);
        crowdIsNow = false;
        crowdIsFinished = true;
        return true;
    }

    function checkCrowding() internal
    {
        if (0 == Crowd.tokens) {
            finishCrowding();
        }
        if (now >= Crowd.date) {
            finishCrowding();
        }
    }

    /**
    *
    * Payment block
    *
    */
    function Buy() public payable
        returns (uint256, uint256, uint256, address)
    {
        uint256 amount = msg.value;
        uint256 _amount = (amount/buyPrice) * DEC;                       // calculates the amount

        require(balanceOf[_multiWalletContract] >= _amount);             // checks if it has enough to sell

        //logical for view available crowd period
        if (Crowd.tokens >= _amount) {
            Crowd.tokens = Crowd.tokens.sub(_amount);
        } else {
            Crowd.tokens = 0;     // set tokens in zero
            finishCrowding();     // finish of crowd
            revert();             // stop of transactions
        }

        require(_multiWalletContract.send(msg.value));

        availableSupply = availableSupply.sub(_amount);
        _transfer(_multiWalletContract, msg.sender, _amount);

        return (amount, _amount, Crowd.tokens, _multiWalletContract);    // ends function and returns
    }


    function () public payable
    {
        // minimal deposite value 0.0004 ele
        if (msg.value >= ( ( 4 * DEC ) / 10000 )) {
            if (crowdIsNow) {
                checkCrowding();
                Buy();
            } else {
                revert();
            }
        } else {
            revert();
        }
    }

}contract MyContract {
    /* Constructor */
    function MyContract() {
 
    }
}
