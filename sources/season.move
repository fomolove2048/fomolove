module fomolove2048::season {
    use std::vector;
    use fomolove2048::keys_calc::sui_rec;
    use sui::coin;
    use sui::coin::Coin;
    use sui::balance;
    use sui::clock::Clock;
    use sui::clock;
    use sui::table;
    use sui::tx_context;
    use sui::sui::SUI;
    use sui::balance::Balance;
    use sui::table::{Table, contains};

    use sui::object::{Self, ID, UID};
    use sui::tx_context::{TxContext};
    use sui::transfer;

    use fomolove2048::game::{Self, Game, merge_coins, merge_and_split};

    const ENotALeader: u64 = 1000000;
    const ELowTile: u64 = 1000001;
    const ELowScore: u64 = 1000002;

    const DEFAULT_WHITE_POT: u64 = 50;
    const DEFAULT_RED_POT: u64 = 20;
    const DEFAULT_WHITE_DIVIDEND: u64 = 30;
    const DEFAULT_RED_DIVIDEND: u64 = 60;
    const DEFAULT_REFERRAL_REWARD: u64 = 15;
    const DEFAULT_AIRDROP: u64 = 2;
    const DEFAULT_PLATFORM: u64 = 3;

    const DEFAULT_SEASON_TIMER: u64 = 24 * 60 * 60 * 1000;
    const DEFAULT_GAME_FEE: u64 = 2 * 10 ** 9;

    const TEAM_WHITE: u64 = 1;
    const TEAM_RED: u64 = 2;

    #[test_only]
    friend fomolove2048::leaderboard_tests;

    struct Season has key, store {
        id: UID,
        season_id: u64,
        sui_cur: u64,
        keys_cur: u64,
        start_time: u64,
        end_time: u64,
        ended: bool,
        winner_team: u64,
        winner_player: u64,
        balance: Balance<SUI>,
        leaderboard: Leaderboard,
        playerInfoInSeason: Table<u64, PlayInfoInSeason>
    }

    struct Leaderboard has key, store {
        max_leaderboard_game_count: u64,
        top_games: vector<TopGame>,
        min_tile: u64,
        min_score: u64
    }

    struct PlayInfoInSeason has store, copy, drop {
        sui_cur: u64,
        keys_cur: u64,
    }

    struct PlayerInfo has key, store {
        id: UID,
        win_vault: Balance<SUI>,
        general_vault: Balance<SUI>,
        affiliate_vault: Balance<SUI>,
    }

    struct GlobalConfig has key {
        id: UID,
        game_fee: u64,
        season_infos: Table<u64, ID>,
        player_infos: Table<address, ID>,
    }

    struct ManageCap has key, store {
        id: UID,
    }

    struct TopGame has store, copy, drop {
        game_id: ID,
        leader_address: address,
        top_tile: u64,
        score: u64
    }

    fun init(ctx: &mut TxContext) {
        let sender = tx_context::sender(ctx);

        let global = GlobalConfig{
            id: object::new(ctx),
            game_fee: DEFAULT_GAME_FEE,
            season_infos: table::new<u64, ID>(ctx),
            player_infos: table::new<address, ID>(ctx)
        };

        let manage_cap = ManageCap{
            id: object::new(ctx),
        };

        transfer::share_object(global);
        transfer::public_transfer(manage_cap, sender);
    }

    // ENTRY FUNCTIONS //

    public entry fun create_season(
        global:&mut GlobalConfig,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        let current_time = clock::timestamp_ms(clock);
        let season_id = table::length(&global.season_infos) + 1;

        let leaderboard = Leaderboard {
            max_leaderboard_game_count: 50,
            top_games: vector<TopGame>[],
            min_tile: 0,
            min_score: 0
        };

        let season = Season {
            id: object::new(ctx),
            season_id,
            sui_cur: 0u64,
            keys_cur: 0u64,
            start_time: current_time,
            end_time: current_time + DEFAULT_SEASON_TIMER,
            ended: false,
            winner_team: 0u64,
            winner_player: 0u64,
            balance: balance::zero<SUI>(),
            leaderboard,
            playerInfoInSeason: table::new<u64, PlayInfoInSeason>(ctx)
        };

        let season_object_id = object::uid_to_inner(&season.id);
        table::add(&mut global.season_infos, season_id, season_object_id);

        transfer::share_object(leaderboard);
    }


    public(friend) entry fun buy_game(
        global: &mut GlobalConfig,
        season: &mut Season,
        fee: vector<Coin<SUI>>,
        keys: u64,
        team: u64,
        ctx: &mut TxContext
    ){
        assert!(keys >= 1 * 10^9 && keys <= 100 * 10^9, EInvalidKeys);
        assert!(contains(&global.season_infos, season.season_id), EInvalidSeason);
        let keys_paid = sui_rec((season.keys_cur as u128), (keys as u128));
        let (paid, remainder) = merge_and_split(fee, (keys_paid as u64), ctx);

        coin::put(&mut season.balance, paid);
        transfer::public_transfer(remainder, tx_context::sender(ctx));

        let player = tx_context::sender(ctx);
        let uid = object::new(ctx);
        //get player id

        //manage affiliate residuals

        //verify team WHITE or RED

        //if season is actived, dividend

        //else close the season and create a new season and reback paid


    }

    fun dividend(){

        // early round eth limiter

        // mint the new keys

        // update timer

        //dividend

        //update keys and suis

        //update season

    }

    public entry fun finish_game(){
        //set winner
    }

    public entry fun submit_game(game: &mut Game8192, leaderboard: &mut Leaderboard) {
        let top_tile = *game::top_tile(game);
        let score = *game::score(game);

        assert!(top_tile >= leaderboard.min_tile, ELowTile);
        assert!(score > leaderboard.min_score, ELowScore);

        let leader_address = *game::player(game);
        let game_id = game::id(game);

        let top_game = TopGame {
            game_id,
            leader_address,
            score: *game::score(game),
            top_tile: *game::top_tile(game)
        };

        add_top_game_sorted(leaderboard, top_game);
    }

    // PUBLIC ACCESSOR FUNCTIONS //

    public fun game_count(leaderboard: &Leaderboard): u64 {
        vector::length(&leaderboard.top_games)
    }

    public fun top_games(leaderboard: &Leaderboard): &vector<TopGame> {
        &leaderboard.top_games
    }

    public fun top_game_at(leaderboard: &Leaderboard, index: u64): &TopGame {
        vector::borrow(&leaderboard.top_games, index)
    }

    public fun top_game_at_has_id(leaderboard: &Leaderboard, index: u64, game_id: ID): bool {
        let top_game = top_game_at(leaderboard, index);
        top_game.game_id == game_id
    }

    public fun top_game_game_id(top_game: &TopGame): ID {
        top_game.game_id
    }

    public fun top_game_top_tile(top_game: &TopGame): &u64 {
        &top_game.top_tile
    }

    public fun top_game_score(top_game: &TopGame): &u64 {
        &top_game.score
    }

    public fun min_tile(leaderboard: &Leaderboard): &u64 {
        &leaderboard.min_tile
    }

    public fun min_score(leaderboard: &Leaderboard): &u64 {
        &leaderboard.min_score
    }

    fun add_top_game_sorted(leaderboard: &mut Leaderboard, top_game: TopGame) {
        let top_games = leaderboard.top_games;
        let top_games_length = vector::length(&top_games);

        let index = 0;
        while (index < top_games_length) {
            let current_top_game = vector::borrow(&top_games, index);
            if (top_game.game_id == current_top_game.game_id) {
                vector::swap_remove(&mut top_games, index);
                break
            };
            index = index + 1;
        };

        vector::push_back(&mut top_games, top_game);

        top_games = merge_sort_top_games(top_games); 
        top_games_length = vector::length(&top_games);

        if (top_games_length > leaderboard.max_leaderboard_game_count) {
            vector::pop_back(&mut top_games);
            top_games_length  = top_games_length - 1;
        };

        if (top_games_length >= leaderboard.max_leaderboard_game_count) {
            let bottom_game = vector::borrow(&top_games, top_games_length - 1);
            leaderboard.min_tile = bottom_game.top_tile;
            leaderboard.min_score = bottom_game.score;
        };

        leaderboard.top_games = top_games;
    }

    public(friend) fun merge_sort_top_games(top_games: vector<TopGame>): vector<TopGame> {
        let top_games_length = vector::length(&top_games);
        if (top_games_length == 1) {
            return top_games
        };

        let mid = top_games_length / 2;

        let right = vector<TopGame>[];
        let index = 0;
        while (index < mid) {
            vector::push_back(&mut right, vector::pop_back(&mut top_games));
            index = index + 1;
        };

        let sorted_left = merge_sort_top_games(top_games);
        let sorted_right = merge_sort_top_games(right);
        merge(sorted_left, sorted_right)
    }

    public(friend) fun merge(left: vector<TopGame>, right: vector<TopGame>): vector<TopGame> {
        vector::reverse(&mut left);
        vector::reverse(&mut right);

        let result = vector<TopGame>[];
        while (!vector::is_empty(&left) && !vector::is_empty(&right)) {
            let left_item = vector::borrow(&left, vector::length(&left) - 1);
            let right_item = vector::borrow(&right, vector::length(&right) - 1);

            if (left_item.top_tile > right_item.top_tile) {
                vector::push_back(&mut result, vector::pop_back(&mut left));
            } else if (left_item.top_tile < right_item.top_tile) {
                vector::push_back(&mut result, vector::pop_back(&mut right));
            } else {
                if (left_item.score > right_item.score) {
                    vector::push_back(&mut result, vector::pop_back(&mut left));
                } else {
                    vector::push_back(&mut result, vector::pop_back(&mut right));
                }
            };
        };

        vector::reverse(&mut left);
        vector::reverse(&mut right);
        
        vector::append(&mut result, left);
        vector::append(&mut result, right);
        result
    }
    

    // TEST FUNCTIONS //

    #[test_only]
    use sui::test_scenario::{Self, Scenario};

    #[test_only]
    public fun blank_leaderboard(scenario: &mut Scenario, max_leaderboard_game_count: u64, min_tile: u64, min_score: u64) {
        let ctx = test_scenario::ctx(scenario);
        let leaderboard = Leaderboard {
            id: object::new(ctx),
            max_leaderboard_game_count,
            top_games: vector<TopGame>[],
            min_tile,
            min_score
        };

        transfer::share_object(leaderboard)
    }

    #[test_only]
    public fun top_game(scenario: &mut Scenario, leader_address: address, top_tile: u64, score: u64): TopGame {
        let ctx = test_scenario::ctx(scenario);
        let object = object::new(ctx);
        let game_id = object::uid_to_inner(&object);
        sui::test_utils::destroy<sui::object::UID>(object);
        TopGame {
            game_id,
            leader_address,
            top_tile,
            score
        }
    }
}