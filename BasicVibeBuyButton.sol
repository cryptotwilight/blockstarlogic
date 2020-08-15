pragma solidity ^0.6.11; 


contract BasicVibeBuyButton { 

    address bvbb_administrator; 

    constructor (address _administrator) public { 
        bvbb_administrator = _administrator; 
    }
    
    
    
    struct Artwork { 
        string key; 
        string artist_name;
        string art_piece_name; 
        string ipfs_cid; 
        uint256 art_piece_price;
        address payable artist_wallet;
        uint256 register_date;
        uint256 sold_date; 
        string description;
        string thumbnail_url;
    }
 
    
    mapping(string=>Artwork)  artworkRegistryByKey;
    mapping(string=>string[]) artworkNameRegistryByArtist; 

    mapping(string=>string) receiptRegistryByReceiptKey; 
    mapping(string=>string) artworkKeyByReceipt; 
    mapping(string=>Artwork[]) artworksSoldByArtist;
    mapping(string=>string[]) artworkNamesSoldByArtist; 
    mapping(string=>mapping(string=>string[])) artworkKeysByArtistNameAndArtworkName; 
 
    function registerArtwork(string memory _artist_name, 
                             string memory _art_piece_name, 
                             uint256 _art_piece_price,
                             string memory _ipfs_cid, 
                             string memory _description, 
                             string memory _thumbnail_url) public returns (string  memory _code)   {
        string memory _key = generateKey(_artist_name, _art_piece_name, now); 
        Artwork memory  artwork = Artwork( {key : _key,
                                            artist_name : _artist_name,
                                            art_piece_name : _art_piece_name, 
                                            ipfs_cid : _ipfs_cid, 
                                            art_piece_price : _art_piece_price, 
                                            artist_wallet: msg.sender,
                                            register_date : now, 
                                            sold_date : 0, 
                                            description: _description,
                                            thumbnail_url: _thumbnail_url
        });
        artworkRegistryByKey[artwork.key] = artwork; 
        artworkNameRegistryByArtist[artwork.artist_name].push(artwork.art_piece_name);
        artworkKeysByArtistNameAndArtworkName[_artist_name][_art_piece_name].push(_key);
        return generateHTMLButtonCodeInsert(artwork); 
    }
    
    
    function buyArtwork(string memory _artwork_key) public payable returns (string memory _receipt) {
           Artwork memory artwork = artworkRegistryByKey[_artwork_key]; 
           
           require(msg.value == artwork.art_piece_price);
           // send the money to the artist
           artwork.artist_wallet.transfer(msg.value);
           // remove the artwork from on sale
           artwork.sold_date = now; 
           delete artworkRegistryByKey[ _artwork_key];
           
           // log the sale of the artwork
           Artwork[] storage  soldList = artworksSoldByArtist[artwork.artist_name];
           soldList.push(artwork);
           
           string [] storage soldNameList = artworkNamesSoldByArtist[artwork.artist_name];
           soldNameList.push(artwork.art_piece_name);
           
           return generateIPFSKeyTransferJSON(artwork);
    }
    
    function findArtworkPrice(string memory _artist_name, string memory _art_piece_name)  public view returns(uint256) {
       string [] memory keys =  artworkKeysByArtistNameAndArtworkName[_artist_name][_art_piece_name];
       return findArtworkPrice(keys[keys.length-1]);
    }
    
    
    function findArtworkPrice(string memory _artwork_key)  public view returns(uint256){
        return artworkRegistryByKey[_artwork_key].art_piece_price;
    }
    
    function findSoldArtworks(string memory _artist_name) public view returns (string memory _artworkList) {
        string [] memory artworks = artworkNamesSoldByArtist[_artist_name];
        return arrayToString(artworks);
    }
    
    function findArtworks(string memory _artist_name) public view returns (string memory _artworkList) {
        string [] memory artworks = artworkNameRegistryByArtist[_artist_name];
        return arrayToString(artworks);
    }
    
    function findReceipt(string memory _receipt_key) public view returns (string memory _receipt){
        return  receiptRegistryByReceiptKey[_receipt_key];
    }
    
    
    //Internal functions 
    function generateKey(string memory _artist_name, string memory _art_piece_name, uint256 date) internal pure returns (string memory _key){
        string memory key =  append(_artist_name, '_'); 
        return appendc(append(key, _art_piece_name), date);
    }

    string inputOpener = "<input type='hidden' id='";
    string inputValue = "' value='";
    string inputCloser = "'/>";
    string newLine = "<br/>";
    
    
    function generateHTMLButtonCodeInsert(Artwork memory artwork) internal view returns (string memory _code) { 
        string memory _key = string(abi.encodePacked(inputOpener,"_artist_piece_key",inputValue, artwork.key, inputCloser));
        string memory _price = string(abi.encodePacked(inputOpener,"_artist_piece_price",inputValue, artwork.art_piece_price, inputCloser));
        return string(abi.encodePacked(_key,newLine,_price));
    }

    function generateIPFSKeyTransferJSON(Artwork memory _artwork) internal returns (string memory _json) { 
        string memory ipfs_key_transfer_JSON = "";
        ipfs_key_transfer_JSON = append(append(append(ipfs_key_transfer_JSON ,"{ art_piece_name: "),  _artwork.art_piece_name),", ");
        ipfs_key_transfer_JSON = append(append(append(ipfs_key_transfer_JSON ,"artist_name: " ), _artwork.artist_name ), ", ");
        ipfs_key_transfer_JSON = appendb(appendc(append(ipfs_key_transfer_JSON ,"price_paid: " ), _artwork.art_piece_price ), ", ");
        ipfs_key_transfer_JSON = append(append(append(ipfs_key_transfer_JSON ,"ipfs_cid: " ), _artwork.ipfs_cid ), ", ");
        ipfs_key_transfer_JSON = appendb(appendc(append(ipfs_key_transfer_JSON ,"purchase_date: "), now ), ", ");
        ipfs_key_transfer_JSON = appendb(appendc(append(ipfs_key_transfer_JSON ,"register_date: " ), _artwork.register_date ), ", ");
        ipfs_key_transfer_JSON = appendb(appendc(append(ipfs_key_transfer_JSON ,"register_address: " ), uint256( _artwork.artist_wallet)), ", "); 
        ipfs_key_transfer_JSON = appendb(appendc(append(ipfs_key_transfer_JSON ,"buyer_address: " ), uint256( msg.sender)), ", "); 
        string memory receipt_key = string(abi.encode(ipfs_key_transfer_JSON));
        ipfs_key_transfer_JSON = appendb(append(append(ipfs_key_transfer_JSON,  "receipt_key: "), receipt_key), "}");
        
        receiptRegistryByReceiptKey[receipt_key] = ipfs_key_transfer_JSON;
        return ipfs_key_transfer_JSON;
    
    }

    function arrayToString(string [] memory list ) internal pure returns (string memory _c){
        string memory  result = "";
        uint len = list.length; 
        for(uint x = 0 ; x < len; x++){
            result = append(result, list[x]);
            if(x == len-1) {
                result = appendb(result, ",");
            }
        }
        return result;
    }

    function appendc(string memory a, uint256 b) internal pure returns (string memory _c) {
        return string( abi.encodePacked(bytes(a), b));
    }

    
    function appendb(string memory a, bytes32 b) internal  pure returns (string memory _c) {
        return string( abi.encodePacked(bytes(a), b));
    }
    
    function append(string memory a, string memory b ) internal  pure returns (string memory _c) {
        return string(abi.encodePacked(bytes(a), bytes(b)));
    }
    
}
