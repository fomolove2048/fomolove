module fomolove2048::rose {
    use std::string::{Self, utf8};
    use sui::clock::{Self, Clock};
    use sui::object::{Self, ID, UID};
    use sui::event;
    use sui::package;
    use sui::display;
    use sui::transfer::{Self, public_transfer};
    use sui::tx_context::{Self, TxContext, sender};

    friend fomolove2048::season;

    /// One-Time-Witness for the module.
    struct ROSE has drop {}

    /// An example NFT that can be minted by anybody
    struct Rose has key, store {
        id: UID,
        /// Name for the token
        name: string::String,
        created_by: address,
        created_at: u64,
    }

    // ===== Events =====

    struct RoseMinted has copy, drop {
        // The Object ID of the NFT
        object_id: ID,
        // The creator of the NFT
        creator: address,
        // The name of the NFT
        name: string::String,
    }

    fun init(otw: ROSE, ctx: &mut TxContext) {
        let keys = vector[
            utf8(b"name"),
            utf8(b"image_url"),
            utf8(b"description"),
            utf8(b"project_url"),
            utf8(b"project_name"),
            utf8(b"project_image_url"),
            utf8(b"creator"),
        ];

        let values = vector[
            utf8(b"FoMoney2048"),
            utf8(b"https://i.postimg.cc/vBDyR7gc/me11.png"),
            utf8(b"FoMoney is a fully onchain game. Buy Key and combine the tiles to win BIG!"),
            utf8(b"https://fomoney.io"),
            utf8(b"FoMoney"),
            utf8(b"https://i.postimg.cc/vBDyR7gc/me11.png"),
            utf8(b"FoMoney")
        ];

        let publisher = package::claim(otw, ctx);

        let display = display::new_with_fields<Rose>(
            &publisher, keys, values, ctx
        );

        display::update_version(&mut display);

        public_transfer(publisher, sender(ctx));
        public_transfer(display, sender(ctx));
    }

    // ===== Public view functions =====

    /// Get the NFT's `name`
    public fun name(nft: &Rose): &string::String {
        &nft.name
    }

    // /// Get the NFT's `description`
    // public fun description(nft: &Rose): &string::String {
    //     &nft.description
    // }
    //
    // /// Get the NFT's `url`
    // public fun url(nft: &Rose): &Url {
    //     &nft.url
    // }

    // ===== Entrypoints =====

    // Create a new devnet_nft
    #[allow(lint(self_transfer))]
    public(friend) fun mint_to_sender(
        team: u64,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        let sender = tx_context::sender(ctx);
        let name = b"";
        if (team == 1){
            name = b"white rose";
        } else if (team == 2){
            name = b"red rose";
        };

        let nft = Rose {
            id: object::new(ctx),
            name: string::utf8(name),
            created_by: sender,
            created_at: clock::timestamp_ms(clock),
        };

        event::emit(RoseMinted {
            object_id: object::id(&nft),
            creator: sender,
            name: nft.name,
        });

        transfer::public_transfer(nft, sender);
    }

    /// Transfer `nft` to `recipient`
    public fun transfer(
        nft: Rose, recipient: address, _: &mut TxContext
    ) {
        transfer::public_transfer(nft, recipient)
    }
}