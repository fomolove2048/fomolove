module fomolove2048::player {
    use sui::object::{Self, UID};
    use sui::tx_context::{Self, TxContext};
    use std::string::{Self, String, utf8};
    use sui::table::{Self, Table};
    use std::vector;
    use sui::coin;
    use sui::pay;
    use sui::coin::Coin;
    use sui::transfer;
    use sui::sui::SUI;

    friend fomolove2048::season;

    const EInvalidPlayerNameLength: u64 = 1000000;
    const EInvalidPlayerNameNoSpace: u64 = 1000001;
    const EInvalidPlayerName: u64 = 1000002;
    const EInvalidAffiliateId: u64 = 1000003;

    struct PlayMaintainer has key {
        id: UID,
        maintainer_address: address,
        registration_fee: u64,
        player_id_by_address: Table<address, u64>,
        player_id_by_name: Table<String, u64>,
        player_id_to_aff_id: Table<u64, u64>,
        player_id_to_name: Table<u64, String>,
        player_id_to_name_list: Table<u64, vector<String>>
    }


    fun init(ctx: &mut TxContext) {
        let sender = tx_context::sender(ctx);

        let player_maintainer = PlayMaintainer{
            id: object::new(ctx),
            maintainer_address: sender,
            registration_fee: 20*10^9,
            player_id_by_address: table::new<address, u64>(ctx),
            player_id_by_name: table::new<String, u64>(ctx),
            player_id_to_aff_id: table::new<u64, u64>(ctx),
            player_id_to_name: table::new<u64, String>(ctx),
            player_id_to_name_list: table::new<u64, vector<String>>(ctx),
        };

        transfer::share_object(player_maintainer);
    }

    public fun check_id_name_valid(
        maintainer: &PlayMaintainer,
        name: &String
    ): bool {
        let valid = name_filter(name);
        if (valid == true){
            return !table::contains(&maintainer.player_id_by_name, *name)
        };
        return valid
    }

    public fun name_filter(name: &String): bool {
        let name_bytes = string::bytes(name);
        let len = vector::length(name_bytes);
        assert!(len <= 32 && len > 0, EInvalidPlayerNameLength);

        let i = 0;
        while (i < len) {
            let byte = *vector::borrow(name_bytes, i);
            assert!(byte != 0x20, EInvalidPlayerNameNoSpace);
            i = i + 1;
        };
        return true
    }

    public(friend) fun get_player_id(maintainer: &mut PlayMaintainer, player: &address): u64 {
        let player_id: u64;
        if (table::contains(&maintainer.player_id_by_address, *player)){
            player_id = *(table::borrow(&maintainer.player_id_by_address, *player));
        }else{
            player_id = table::length(&maintainer.player_id_by_address) + 1;
            table::add(&mut maintainer.player_id_by_address, *player, player_id);
        };
        return player_id
    }

    public(friend) fun register_name(
        maintainer: &mut PlayMaintainer,
        fee: vector<Coin<SUI>>,
        name: String,
        aff_id: u64,
        ctx: &mut TxContext
    ){
        assert!(check_id_name_valid(maintainer, &name), EInvalidPlayerName);
        let player = tx_context::sender(ctx);
        let play_id = get_player_id(maintainer, &player);

        let (paid, remainder) = merge_and_split(fee, maintainer.registration_fee, ctx);
        transfer::public_transfer(paid, maintainer.maintainer_address);
        transfer::public_transfer(remainder, player);


        if (aff_id != 0 && aff_id != play_id){
          if (table::contains(&maintainer.player_id_to_aff_id, play_id)){
              let player_aff_id = *table::borrow(&maintainer.player_id_to_aff_id, play_id);
              if (player_aff_id != aff_id){
                  table::remove(&mut maintainer.player_id_to_aff_id, play_id);
                  table::add(&mut maintainer.player_id_to_aff_id, play_id, aff_id);
              }
          }
        // }
        // else if (aff_id == play_id) {
        //     aff_id = 0;
        };

        table::add(&mut maintainer.player_id_by_name, name, play_id);
        let name_list = *table::borrow(&maintainer.player_id_to_name_list, play_id);
        vector::push_back(&mut name_list, name);
        table::remove(&mut maintainer.player_id_to_name_list, play_id);
        table::add(&mut maintainer.player_id_to_name_list, play_id, name_list);
    }

    public(friend) fun update_aff_id(
        maintainer: &mut PlayMaintainer,
        player_id: u64,
        aff_id: u64
    ){
        assert!(aff_id != 0 && aff_id != player_id, EInvalidAffiliateId);
        if (table::contains(&maintainer.player_id_to_aff_id, player_id)){
            let player_aff_id = *table::borrow(&maintainer.player_id_to_aff_id, player_id);
            if (player_aff_id != aff_id){
                table::remove(&mut maintainer.player_id_to_aff_id, player_id);
                table::add(&mut maintainer.player_id_to_aff_id, player_id, aff_id);
            }
        } else {
            table::add(&mut maintainer.player_id_to_aff_id, player_id, aff_id);
        }
    }

    public fun view_player_id_by_address(
        maintainer: &PlayMaintainer,
        player_address: address
    ): u64{
        if (!table::contains(&maintainer.player_id_by_address, player_address)){
            return 0
        } else {
            return *table::borrow(&maintainer.player_id_by_address, player_address)
        }
    }

    public fun view_player_id_by_name(
        maintainer: &PlayMaintainer,
        name: String
    ): u64{
        if (!table::contains(&maintainer.player_id_by_name, name)){
            return 0
        } else {
            return *table::borrow(&maintainer.player_id_by_name, name)
        }
    }

    public fun view_player_aff_id(
        maintainer: &PlayMaintainer,
        player_id: u64
    ): u64{
        if (!table::contains(&maintainer.player_id_to_aff_id, player_id)){
            return 0
        } else {
            return *table::borrow(&maintainer.player_id_to_aff_id, player_id)
        }
    }

    public fun view_player_name_list(
        maintainer: &PlayMaintainer,
        player_id: u64
    ): vector<String>{
        if (!table::contains(&maintainer.player_id_to_name_list, player_id)){
            return vector::empty<String>()
        } else {
            return *table::borrow(&maintainer.player_id_to_name_list, player_id)
        }
    }

    public fun view_player_actived_name_by_player_id(
        maintainer: &PlayMaintainer,
        player_id: u64
    ): String{
        if (!table::contains(&maintainer.player_id_to_name, player_id)){
            return utf8(b"")
        } else {
            return *table::borrow(&maintainer.player_id_to_name, player_id)
        }
    }

    public fun view_player_actived_name_by_player_address(
        maintainer: &PlayMaintainer,
        player_address: address
    ): String{
        let player_id= view_player_id_by_address(maintainer, player_address);
        return view_player_actived_name_by_player_id(maintainer, player_id)
    }

    public fun merge_and_split(
        coins: vector<Coin<SUI>>, amount: u64, ctx: &mut TxContext
    ): (Coin<SUI>, Coin<SUI>) {
        let base = vector::pop_back(&mut coins);
        pay::join_vec(&mut base, coins);
        let coin_value = coin::value(&base);
        assert!(coin_value >= amount, coin_value);
        (coin::split(&mut base, amount, ctx), base)
    }
}


