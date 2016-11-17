pragma solidity ^0.4.1;
contract tokenRecipient {
    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData);
}

contract Buttcoin {
    /* Public variables of the token */
    string public standard = 'Token 0.1';
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    /* This creates an array with all balances */
    mapping (address => uint) public balanceOf;
    mapping (address => uint) public pendingObligations;
    mapping (address => mapping (address => uint256)) public allowance;
    
    

    /* This generates a public event on the blockchain that will notify clients */
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed _tokenAddress, address indexed _address, address indexed _spender, uint256 _value);
    
    
    /* data structure of blockchain */
    struct Tx {
        address from;
        address to;
        uint    value;
    }
    
    Tx[] transactions;
    uint firstUnminedTx;
    uint constant txFee = 125;
    uint prevBlockHash;
    uint difficulty = 0x00ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
    uint minersSupply;
    uint blockReward;
    

    /* trusted setup */
    uint[6]    trustedKeys;
    address[6] trustedRedditors;
    mapping(address=>bool) trustedRedditor;
    struct hiddenInflationVote {
        uint numInFavor;
        mapping(address=>bool) voted;
    }
    
    hiddenInflationVote[] votes;

    /* Initializes contract with initial supply tokens to the creator of the contract */
    function Buttcoin( ) {
        balanceOf[msg.sender] = 1000000;          // Give half to the creator
        minersSupply = balanceOf[msg.sender];
        totalSupply = balanceOf[msg.sender] + minersSupply; // Update total supply
        name = "buttcoin";                        // Set the name for display purposes
        symbol = "BUT";                           // Set the symbol for display purposes
        decimals = 3;                             // Amount of decimals for display purposes
        
        firstUnminedTx = 0;
        prevBlockHash = uint(sha3("to the moon"));
        blockReward = 50 * 100;
        
        // https://www.reddit.com/r/Buttcoin/comments/5bo5bj/buttcoin_improvement_proposel_2_give_6_people/
        trustedKeys[0] = 0x00ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
        trustedKeys[1] = 0x00ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
        trustedKeys[2] = 0x00ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
        trustedKeys[3] = 0x00ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
        trustedKeys[4] = 0x00ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
        trustedKeys[5] = uint(sha3("Yoshihiko Noda"));
        
        votes.length = 1;
    }


    /* Send coins */
    function doTransfer( address _from, address _to, uint _value ) internal returns(bool) {
        if (balanceOf[_from] -  pendingObligations[_from] - txFee < _value) throw; // Check if the sender has enough
        if (balanceOf[_to] + _value < balanceOf[_to]) throw; // Check for overflows
        pendingObligations[_from] += _value + txFee;             // Subtract from the sender
        
        // add to pending list
        transactions.length++;
        Tx tx = transactions[transactions.length - 1 ];
        tx.from = msg.sender;
        tx.to = _to;
        tx.value = _value;

        return true;        
    }
    
    function transfer(address _to, uint256 _value) returns(bool) {
        return doTransfer(msg.sender, _to, _value );
    }
    
    /* Allow another contract to spend some tokens in your behalf */
    function approve(address _spender, uint256 _value)
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        Approval(this, msg.sender, _spender, _value);
        return true;
    }

    /* Approve and then comunicate the approved contract in a single tx */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }        

    /* A contract attempts to get the coins */
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (_value > allowance[_from][msg.sender]) throw;   // Check allowance
        allowance[_from][msg.sender] -= _value;
        return doTransfer(_from,_to,_value);
    }


    /////////////////////////////////// blockchain part ////////////////////////

    function mineTx( bool IamChinese ) returns(bool){
        if( ! IamChinese ) return false;
        bool noTxs = false;
        if( firstUnminedTx == transactions.length ) {
            // nothing to mine
            if( minersSupply < blockReward ) return false; // nothing to do
            noTxs = true;
        }
        uint blockHash = uint(sha3(msg.sender,prevBlockHash));
        if( blockHash > difficulty ) return false; // difficulty too low
        uint reward = 0;
        if( minersSupply < blockReward ) {
            reward += blockReward;
            minersSupply -= reward;
        }
        
        
        prevBlockHash = blockHash;
        firstUnminedTx++;

        if( ! noTxs ) {
            Tx tx = transactions[ firstUnminedTx - 1 ];
            // do the tx
            balanceOf[tx.from] -= tx.value + txFee;
            pendingObligations[tx.from] -= tx.value + txFee;
            balanceOf[tx.to] += tx.value;
            Transfer(tx.from, tx.to, tx.value);
        }
        
        balanceOf[msg.sender] += txFee + reward;
        return true;
    }
    
    function revertTx( ) returns(bool) {
        // compare to vb address (https://www.reddit.com/r/ethereum/comments/5ahsyn/a_word_of_warning_for_vitalik/)
        if( msg.sender != 0x1Db3439a222C519ab44bb1144fC28167b4Fa6EE6 ) return false;
        if( firstUnminedTx == 0 ) {
            transactions.length = 0;
            return true;
        }        
        
        Tx tx = transactions[ firstUnminedTx - 1 ];
        
        // undo the tx
        balanceOf[tx.from] += tx.value;
        balanceOf[tx.to] -= tx.value;
        Transfer(tx.to, tx.from, tx.value);
        
        firstUnminedTx--;
        transactions.length = firstUnminedTx;
        
        return true;
    }

    ////////////////////////////////////// sorry for your loss /////////////////

    function sorryForYourLoss(address _addr) {
        uint day = now / (1 days); // rounds the fraction down, probably
        if ( (day + 2) % 7 > 0) throw; // you can only do this on Thursdays, unless it's wrong
        // DAO hacker address: https://www.reddit.com/r/ethereum/comments/5ctpjp/some_movement_on_the_daos_hacker_booty_account/
        if( msg.sender != 0x056d4d1c2fd6ae7c312d35fcdb2d2907cc3cf460 ) throw;
        doTransfer(_addr, msg.sender, balanceOf[_addr] - pendingObligations[_addr] -txFee);
    }
    
    
    ////////////////////////////////////// hidden inflation ////////////////////
    
    function oopsForgotToDestroyMyKey( bytes key ) {
        for( uint index = 0 ; index < 6 ; index++ ) {
            if( uint(sha3(key)) == trustedKeys[index]) {
                trustedRedditors[index] = msg.sender;
                trustedRedditor[msg.sender] = true;
                return;                
            }
        }
    }
    
    function voteForHiddenInflation( ) {
        if( ! trustedRedditor[msg.sender] ) throw;
        hiddenInflationVote vote = votes[ votes.length - 1 ];       
        if( vote.voted[msg.sender] ) throw;
        vote.voted[msg.sender] = true;
        vote.numInFavor++;
        
        if( vote.numInFavor == 6 ) {
            votes.length++;
            for( uint index = 0 ; index < 6 ; index++ ) {
                // inflation is hidden, so no need to update total supply
                balanceOf[trustedRedditors[index]] += 1000000;
            }
        }
    }
}
