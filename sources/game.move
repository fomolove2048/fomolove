module fomolove2048::game {
    use std::string::{utf8};
    use sui::object::{Self, ID, UID};
    use sui::tx_context::{Self, TxContext, sender};
    use sui::event;
    use sui::transfer::{transfer, public_transfer};

    
    use sui::package;
    use sui::display;

    use fomolove2048::game_board::{Self, GameBoard};

    friend fomolove2048::season;

    #[test_only]
    friend fomolove2048::game_tests;

    #[test_only]
    friend fomolove2048::leaderboard_tests;

    // const DEFAULT_FEE: u64 = 200_000_000;

    // const EInvalidPlayer: u64 = 0;
    const ENotMaintainer: u64 = 1;
    const ENoBalance: u64 = 2;

    /// One-Time-Witness for the module.
    struct GAME has drop {}

    struct Game has key, store {
        id: UID,
        game: u64,
        player: address,
        active_board: GameBoard,
        move_count: u64,
        score: u64,
        top_tile: u64,      
        game_over: bool
    }

    struct GameMove has store {
        direction: u64,
        player: address
    }

    // struct GameMaintainer has key {
    //     id: UID,
    //     maintainer_address: address,
    //     game_count: u64,
    //     fee: u64,
    //     balance: Balance<SUI>
    // }

    struct NewGameEvent has copy, drop {
        game_id: ID,
        player: address,
        score: u64,
        packed_spaces: u64
    }

    struct GameMoveEvent has copy, drop {
        game_id: ID,
        direction: u64,
        move_count: u64,
        packed_spaces: u64,
        last_tile: vector<u64>,
        top_tile: u64,
        score: u64,
        game_over: bool
    }

    struct GameOverEvent has copy, drop {
        game_id: ID,
        top_tile: u64,
        score: u64
    }

    fun init(otw: GAME, ctx: &mut TxContext) {
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
            utf8(b"Fomolove 2048"),
            utf8(b"https://sui8192.s3.amazonaws.com/{top_tile}.png"),
            utf8(b"Sui 8192 is a fun, 100% on-chain game. Combine the tiles to get a high score!"),
            utf8(b"https://ethoswallet.github.io/Sui8192/"),
            utf8(b"Fomolove 2048"),
            utf8(b"https://sui8192.s3.amazonaws.com/sui-8192.png"),
            utf8(b"Fomolove2048")
        ];

        let publisher = package::claim(otw, ctx);

        let display = display::new_with_fields<Game>(
            &publisher, keys, values, ctx
        );

        display::update_version(&mut display);

        // let maintainer = create_maintainer(ctx);

        public_transfer(publisher, sender(ctx));
        public_transfer(display, sender(ctx));
        // transfer::share_object(maintainer);
    }

    // PUBLIC ENTRY FUNCTIONS //
    
    public(friend) fun create(game_count: u64, ctx: &mut TxContext) {
        let player = tx_context::sender(ctx);
        let uid = object::new(ctx);
        let random = object::uid_to_bytes(&uid);
        let initial_game_board = game_board::default(random);

        let score = *game_board::score(&initial_game_board);
        let top_tile = *game_board::top_tile(&initial_game_board);

        let game = Game {
            id: uid,
            game: game_count + 1,
            player,
            move_count: 0,
            score,
            top_tile,
            active_board: initial_game_board,
            game_over: false,
        };

        event::emit(NewGameEvent {
            game_id: object::uid_to_inner(&game.id),
            player,
            score,
            packed_spaces: *game_board::packed_spaces(&initial_game_board)
        });

        transfer(game, player);
    }

    public entry fun make_move(game: &mut Game, direction: u64, ctx: &mut TxContext)  {
        let new_board;
        {
            new_board = *&game.active_board;

            let uid = object::new(ctx);
            let random = object::uid_to_bytes(&uid);
            object::delete(uid);
            game_board::move_direction(&mut new_board, direction, random);
        };

        let move_count = game.move_count + 1;
        let top_tile = *game_board::top_tile(&new_board);
        let score = *game_board::score(&new_board);
        let game_over = *game_board::game_over(&new_board);

        event::emit(GameMoveEvent {
            game_id: object::uid_to_inner(&game.id),
            direction,
            move_count,
            packed_spaces: *game_board::packed_spaces(&new_board),
            last_tile: *game_board::last_tile(&new_board),
            top_tile,
            score,
            game_over
        });

        if (game_over) {            
            event::emit(GameOverEvent {
                game_id: object::uid_to_inner(&game.id),
                top_tile,
                score
            });
        };

        game.move_count = move_count;
        game.active_board = new_board;
        game.score = score;
        game.top_tile = top_tile;
        game.game_over = game_over;
    }

    public entry fun burn_game(game: Game)  {
        let Game {  
            id,
            game: _,
            player: _,
            active_board: _,
            move_count: _,
            score: _,
            top_tile: _,      
            game_over: _,
        } = game;
        object::delete(id);
    }

    // Not clear why the top_tile is not being set in the contract properly. This is a temporary fix.
    public entry fun fix_game(game: &mut Game)  {
        game.top_tile = game_board::analyze_top_tile(&game.active_board);
    }

    // public entry fun pay_maintainer(maintainer: &mut GameMaintainer, ctx: &mut TxContext) {
    //     assert!(tx_context::sender(ctx) == maintainer.maintainer_address, ENotMaintainer);
    //     let amount = balance::value<SUI>(&maintainer.balance);
    //     assert!(amount > 0, ENoBalance);
    //     let payment = coin::take(&mut maintainer.balance, amount, ctx);
    //     transfer::public_transfer(payment, tx_context::sender(ctx));
    // }
    //
    // public entry fun change_maintainer(maintainer: &mut GameMaintainer, new_maintainer: address, ctx: &mut TxContext) {
    //     assert!(tx_context::sender(ctx) == maintainer.maintainer_address, ENotMaintainer);
    //     maintainer.maintainer_address = new_maintainer;
    // }
    //
    // public entry fun change_fee(maintainer: &mut GameMaintainer, new_fee: u64, ctx: &mut TxContext) {
    //     assert!(tx_context::sender(ctx) == maintainer.maintainer_address, ENotMaintainer);
    //     maintainer.fee = new_fee;
    // }
 
    // PUBLIC ACCESSOR FUNCTIONS //

    public fun id(game: &Game): ID {
        object::uid_to_inner(&game.id)
    }

    public fun player(game: &Game): &address {
        &game.player
    }

    public fun active_board(game: &Game): &GameBoard {
        &game.active_board
    }

    public fun top_tile(game: &Game): &u64 {
        let game_board = active_board(game);
        game_board::top_tile(game_board)
    }

    public fun score(game: &Game): &u64 {
        let game_board = active_board(game);
        game_board::score(game_board)
    }

    public fun move_count(game: &Game): &u64 {
        &game.move_count
    }

    // Friend functions

    // public(friend) fun create_maintainer(ctx: &mut TxContext): GameMaintainer {
    //     GameMaintainer {
    //         id: object::new(ctx),
    //         maintainer_address: sender(ctx),
    //         game_count: 0,
    //         fee: DEFAULT_FEE,
    //         balance: balance::zero<SUI>()
    //     }
    // }

    // public fun merge_and_split(
    //     coins: vector<Coin<SUI>>, amount: u64, ctx: &mut TxContext
    // ): (Coin<SUI>, Coin<SUI>) {
    //     let base = vector::pop_back(&mut coins);
    //     pay::join_vec(&mut base, coins);
    //     let coin_value = coin::value(&base);
    //     assert!(coin_value >= amount, coin_value);
    //     (coin::split(&mut base, amount, ctx), base)
    // }

    // public fun merge_coins(
    //     coins: vector<Coin<SUI>>, ctx: &mut TxContext
    // ): Coin<SUI> {
    //     let base = vector::pop_back(&mut coins);
    //     pay::join_vec(&mut base, coins);
    //     base
    // }
}