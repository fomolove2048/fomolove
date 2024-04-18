module fomolove2048::season {
    use std::string::String;
    use std::vector;
    use sui::address;

    use sui::pay;
    use sui::transfer;
    use sui::sui::SUI;
    use sui::balance::{Self, Balance};
    use sui::table::{Self, Table, contains};
    use sui::object::{Self, ID, UID};
    use sui::tx_context::{Self, TxContext};
    use sui::clock::{Self, Clock};
    use sui::coin::{Self, Coin};

    use fomolove2048::player::{
        Self,
        PlayMaintainer,
        get_player_id,
        view_player_aff_id,
        update_aff_id
    };
    use fomolove2048::keys_calc::sui_rec;
    use fomolove2048::game::{Self, Game, GameMaintainer};
    use fomolove2048::rose;

    const ELowTile: u64 = 1000001;
    const ELowScore: u64 = 1000002;
    const EInvalidKeys: u64 = 1000003;
    const EInvalidSeason: u64 = 1000004;
    const EInvalidTeam: u64 = 1000005;
    const EInvalidPlayer: u64 = 1000006;
    const ENoEnoughKeys: u64 = 1000007;
    const EHaveTeam: u64 = 1000008;
    const ETooManyKeys: u64 = 1000009;
    const ESeasonIsNotStart: u64 = 1000010;
    const ESeasonIsEnded: u64 = 1000011;
    const EGameMintedRose: u64 = 1000012;
    const EGmaeIsNotCurrentSeason: u64 = 1000013;

    const DEFAULT_WHITE_POT: u64 = 50;
    const DEFAULT_RED_POT: u64 = 20;
    const DEFAULT_WHITE_DIVIDEND: u64 = 30;
    const DEFAULT_RED_DIVIDEND: u64 = 60;
    const DEFAULT_REFERRAL_REWARD: u64 = 15;
    const DEFAULT_AIRDROP: u64 = 2;
    const DEFAULT_PLATFORM: u64 = 3;

    const POT_TO_WINNER_PRIZE_RATE: u64 = 48;
    const POT_TO_NEXT_SEASON_POT_RATE: u64 = 2;
    const POT_TO_PLATFORM_RATE: u64 = 10;
    const POT_TO_WINNER_TEAM_KEYS_HOLDER_WHITE: u64 = 25;
    const POT_TO_WINNER_TEAM_ROSE_HOLDER_WHITE: u64 = 15;  //only winner rose holder
    const POT_TO_WINNER_TEAM_KEYS_HOLDER_RED: u64 = 35;
    const POT_TO_WINNER_TEAM_ROSE_HOLDER_RED: u64 = 5;

    const DEFAULT_SEASON_TIMER: u64 = 24 * 60 * 60 * 1000;
    const ADD_TIMER_PER_KEY: u64 = 30 * 1000;

    const TEAM_WHITE: u64 = 1;
    const TEAM_RED: u64 = 2;

    #[test_only]
    friend fomolove2048::season_tests;

    struct Season has key, store {
        id: UID,
        season_id: u64,
        sui_cur: u64,        // total sui in this season
        keys_cur: u64,      // total keys in this season
        rose_cur: u64,      // total minted rose in this season
        start_time: u64,
        end_time: u64,
        ended: bool,
        winner_team: u64,
        winner_player: u64,
        mask: u64,         // for calculating dividend
        pot: Balance<SUI>,  // total pot in this season
        dividend: Balance<SUI>,  // total dividend pot in this season
        airdrop: Balance<SUI>,  // total airdrop pot in this season
        leaderboard: Leaderboard,
        player_infos: Table<u64, PlayInfoInSeason>, // player info in this season
        team_infos: Table<u64, TeamInfoInSeason>,  // team info in this season
        sn_players: Table<u64, address>, // sn to player address
        player_sn: Table<address, u64>, // player address to sn
        games_minted_rose: vector<ID>, // games minted rose
        airdrop_list: vector<u64>, // airdrop list
    }

    struct Leaderboard has store, copy, drop {
        max_leaderboard_game_count: u64,
        top_games: vector<TopGame>,
        winner_game: TopGame,
        min_tile: u64,
        min_score: u64
    }

    struct PlayInfoInSeason has store, copy, drop {
        team: u64,        // the team of player
        sui_cur: u64,     // player spend sui in this season
        keys_cur: u64,    // player buy keys in this season
        rose_cur: u64,    // player minted rose in this season
        game_count: u64,  // player play game count in this season
        mask: u64,         // for calculating dividend
    }

    struct TeamInfoInSeason has store {
        keys_holder_pot: Balance<SUI>,   // team pot for keys holder
        rose_holder_pot: Balance<SUI>,   // team pot for rose holder
        // player_info: Table<u64, PlayInfoInTeam>,
        rose_holder: vector<u64>,     // rose holder list
        pot_per_key: u64,   // reward per key
        pot_per_rose: u64,  // reward per rose
        sui_cur: u64,       // spend sui in this team
        keys_cur: u64,      // buy keys in this team
        rose_cur: u64,      // minted rose in this team
        game_count: u64,    // play game count in this team
    }
    // struct PlayInfoInTeam has store, copy, drop {
    //     sui_cur: u64,
    //     keys_cur: u64,
    //     rose_cur: u64,
    //     game_count: u64,
    // }

    struct PlayerVaults has store {
        win_vault: Balance<SUI>,          // player winning prize
        affiliate_vault: Balance<SUI>,    // player affiliate earning
    }

    struct GlobalConfig has key {
        id: UID,
        maintainer: address,
        game_count: u64,
        platform: Balance<SUI>,          // platform earning
        season_infos: Table<u64, ID>,
        player_vaults: Table<u64, PlayerVaults>,
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
            maintainer: sender,
            game_count: 0u64,
            platform: balance::zero<SUI>(),
            season_infos: table::new<u64, ID>(ctx),
            player_vaults: table::new<u64, PlayerVaults>(ctx)
        };

        transfer::share_object(global);
    }

    // ENTRY FUNCTIONS //

    fun create_season(
        global:&mut GlobalConfig,
        init_pot: Coin<SUI>,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        let current_time = clock::timestamp_ms(clock);
        let season_id = table::length(&global.season_infos) + 1;

        let temp_address = address::from_bytes(b"temp");

        let leaderboard = Leaderboard {
            max_leaderboard_game_count: 50,
            top_games: vector<TopGame>[],
            winner_game: TopGame {
                game_id: object::id_from_address(temp_address),
                leader_address: temp_address,
                top_tile: 0,
                score: 0
            },
            min_tile: 0,
            min_score: 0
        };

        let season = Season {
            id: object::new(ctx),
            season_id,
            sui_cur: 0u64,
            keys_cur: 0u64,
            rose_cur: 0u64,
            start_time: current_time,
            end_time: current_time + DEFAULT_SEASON_TIMER,
            ended: false,
            winner_team: 0u64,
            winner_player: 0u64,
            mask: 0u64,
            pot: coin::into_balance(init_pot),
            dividend: balance::zero<SUI>(),
            airdrop: balance::zero<SUI>(),
            leaderboard,
            player_infos: table::new<u64, PlayInfoInSeason>(ctx),
            team_infos: table::new<u64, TeamInfoInSeason>(ctx),
            sn_players: table::new<u64, address>(ctx),
            player_sn: table::new<address, u64>(ctx),
            games_minted_rose: vector<ID>[],
            airdrop_list: vector<u64>[],
        };

        let team_info_white = TeamInfoInSeason{
            keys_holder_pot: balance::zero<SUI>(),
            rose_holder_pot: balance::zero<SUI>(),
            // player_info: table::new<u64, PlayInfoInTeam>(ctx),
            rose_holder: vector<u64>[],
            pot_per_key: 0u64,
            pot_per_rose: 0u64,
            sui_cur: 0u64,
            keys_cur: 0u64,
            rose_cur: 0u64,
            game_count: 0u64,
        };
        table::add(&mut season.team_infos, TEAM_WHITE, team_info_white);

        let team_info_red = TeamInfoInSeason{
            keys_holder_pot: balance::zero<SUI>(),
            rose_holder_pot: balance::zero<SUI>(),
            // player_info: table::new<u64, PlayInfoInTeam>(ctx),
            rose_holder: vector<u64>[],
            pot_per_key: 0u64,
            pot_per_rose: 0u64,
            sui_cur: 0u64,
            keys_cur: 0u64,
            rose_cur: 0u64,
            game_count: 0u64,
        };
        table::add(&mut season.team_infos, TEAM_RED, team_info_red);

        let season_object_id = object::uid_to_inner(&season.id);
        table::add(&mut global.season_infos, season_id, season_object_id);

        transfer::share_object(season);
    }

    public entry fun register_name(
        global: &mut GlobalConfig,
        maintainer: &mut PlayMaintainer,
        fee: vector<Coin<SUI>>,
        name: String,
        aff_id: u64,
        ctx: &mut TxContext
    ) {
        player::register_name(maintainer, fee, name, aff_id, ctx);

        let player_vaults = PlayerVaults {
            win_vault: balance::zero<SUI>(),
            affiliate_vault: balance::zero<SUI>(),
        };

        let player_id = get_player_id(maintainer, &tx_context::sender(ctx));
        table::add(&mut global.player_vaults, player_id, player_vaults);
    }

    public entry fun buy_keys(
        player_maintainer: &mut PlayMaintainer,
        global: &mut GlobalConfig,
        season: &mut Season,
        fee: vector<Coin<SUI>>,
        keys: u64,
        team: u64,
        affiliate: u64,
        clock: &Clock,
        ctx: &mut TxContext
    ){
        let player = tx_context::sender(ctx);
        let current_time = clock::timestamp_ms(clock);
        assert!(season.ended == false, ESeasonIsEnded);
        assert!(current_time >= season.start_time, ESeasonIsNotStart);

        if (current_time > season.end_time){
            end_season(global, season, clock, ctx);
            let (zero, remainder) = merge_and_split(fee, 0, ctx);
            transfer::public_transfer(zero, player);
            transfer::public_transfer(remainder, player);
            return
        };

        assert!(keys >= 1 * 10^9 && keys <= 100 * 10^9 && keys % 10^9 == 0, EInvalidKeys);
        assert!(contains(&global.season_infos, season.season_id), EInvalidSeason);

        //get player id, create player vaults if not exist
        let player_id = get_player_id(player_maintainer, &player);
        if (!contains(&global.player_vaults, player_id)){
            let player_info = PlayerVaults{
                win_vault: balance::zero<SUI>(),
                affiliate_vault: balance::zero<SUI>(),
            };
            table::add(&mut global.player_vaults, player_id, player_info);
        };

        //handle sui
        let keys_paid = sui_rec((season.keys_cur as u128), (keys as u128));
        let (paid, remainder) = merge_and_split(fee, (keys_paid as u64), ctx);
        let paid_value = coin::value(&paid);
        // coin::put(&mut season.balance, paid);
        transfer::public_transfer(remainder, player);

        //manage affiliate residuals
        // let affiliate_id = view_player_id_by_address(player_maintainer, affiliate);
        let affiliate_id = affiliate;
        let old_affiliate_id = view_player_aff_id(player_maintainer, player_id);
        if ((affiliate_id == 0) || (affiliate_id == player_id)){
            affiliate_id = old_affiliate_id;
        } else if (affiliate_id != old_affiliate_id){
            update_aff_id(player_maintainer, player_id, affiliate_id);
        };

        // update timer
        if (current_time + DEFAULT_SEASON_TIMER >= season.end_time + keys * ADD_TIMER_PER_KEY){
            season.end_time = season.end_time + keys * ADD_TIMER_PER_KEY;
        } else {
            season.end_time = current_time + DEFAULT_SEASON_TIMER;
        };

        //update season info
        season.keys_cur = season.keys_cur + keys;
        season.sui_cur = season.sui_cur + paid_value;

        //update player sn
        if (!contains(&season.player_sn, player)){
            let sn = table::length(&season.sn_players) + 1;
            table::add(&mut season.sn_players, sn, player);
            table::add(&mut season.player_sn, player, sn);
        };

        //update player info
        if (!contains(&season.player_infos, player_id)){
            //add player info in this season
            let player_info = PlayInfoInSeason{
                team: 0u64,
                sui_cur: 0u64,
                keys_cur: 0u64,
                rose_cur: 0u64,
                game_count: 0u64,
                mask: 0u64,
            };
            table::add(&mut season.player_infos, player_id, player_info);
        };

        let player_info = table::borrow_mut(&mut season.player_infos, player_id);
        player_info.sui_cur = player_info.sui_cur + paid_value;
        if (season.sui_cur <= 20000 * 10^9 + paid_value){
            assert!(player_info.sui_cur <= 2000 * 10^9, ETooManyKeys);
        };
        player_info.keys_cur = player_info.keys_cur + keys;
        assert!(player_info.team == 0 || player_info.team == team, EHaveTeam);
        player_info.team = team;

        //if season is actived, dividend
        allocation_entry_funds(global, season, paid, keys, player_id, affiliate_id, team, ctx);
    }

    public entry fun withdraw_earnings(
        global: &mut GlobalConfig,
        season: &mut Season,
        player_id: u64,
        ctx: &mut TxContext
    ){
        let sender = tx_context::sender(ctx);

        let dividend_earning = calculates_dividend_earning(season, player_id);
        let winner_team_keys_earning = calculates_winner_team_keys_earning(season, player_id);
        let winner_team_rose_earning = calculates_winner_team_rose_earning(season, player_id);

        //transfer dividend to player
        transfer::public_transfer(
            coin::take(&mut season.dividend, dividend_earning, ctx),
            sender
        );
        let player_info = table::borrow_mut(&mut season.player_infos, player_id);
        player_info.mask = player_info.mask + dividend_earning;

        //transfer winner team keys earning to player
        let keys_holder_pot = &mut table::borrow_mut(&mut season.team_infos, player_info.team).keys_holder_pot;
        transfer::public_transfer(
            coin::take(keys_holder_pot, winner_team_keys_earning, ctx),
            sender
        );

        //transfer winner team rose earning to player
        let rose_holder_pot = &mut table::borrow_mut(&mut season.team_infos, player_info.team).rose_holder_pot;
        transfer::public_transfer(
            coin::take(rose_holder_pot, winner_team_rose_earning, ctx),
            sender
        );

        let player_vault = table::borrow_mut(&mut global.player_vaults, player_id);
        //transfer affiliate earning to player
        transfer::public_transfer(
            coin::from_balance(balance::withdraw_all(&mut player_vault.affiliate_vault), ctx),
            sender
        );

        //transfer player winning prize to player
        transfer::public_transfer(
            coin::from_balance(balance::withdraw_all(&mut player_vault.win_vault), ctx),
            sender
        );

    }

    public entry fun airdrop_game(
        maintainer: &mut GameMaintainer,
        player_maintainer: &mut PlayMaintainer,
        global: &mut GlobalConfig,
        season: &mut Season,
        airdrop_player: address,
        team: u64,
        clock: &Clock,
        ctx: &mut TxContext
    ){
        let player_id = get_player_id(player_maintainer, &airdrop_player);
        if (!contains(&global.player_vaults, player_id)){
            let player_info = PlayerVaults{
                win_vault: balance::zero<SUI>(),
                affiliate_vault: balance::zero<SUI>(),
            };
            table::add(&mut global.player_vaults, player_id, player_info);
        };

        //get player info in team
        if (!contains(&season.player_infos, player_id)){
            //add player info in this season
            let player_info = PlayInfoInSeason{
                team,
                sui_cur: 0u64,
                keys_cur: 0u64,
                rose_cur: 0u64,
                game_count: 0u64,
                mask: 0u64,
            };
            table::add(&mut season.player_infos, player_id, player_info);
        };

        game::create_airdrop_game(maintainer, vector[], airdrop_player, clock, ctx);
    }

    public entry fun start_game(
        maintainer: &mut GameMaintainer,
        player_maintainer: &mut PlayMaintainer,
        global: &mut GlobalConfig,
        season: &mut Season,
        team: u64,
        clock: &Clock,
        ctx: &mut TxContext
    ){
        let player = tx_context::sender(ctx);
        let player_id = get_player_id(player_maintainer, &player);

        //get team info
        let team_info = table::borrow_mut(&mut season.team_infos, team);

        //get player info in team
        assert!(contains(&season.player_infos, player_id), EInvalidPlayer);
        let player_info = table::borrow_mut(&mut season.player_infos, player_id);

        assert!(player_info.keys_cur/10^9 - player_info.game_count >= 1, ENoEnoughKeys);
        game::create(maintainer, vector[], clock, ctx);
        global.game_count = global.game_count + 1;
        player_info.game_count = player_info.game_count + 1;
        team_info.game_count = team_info.game_count + 1;
    }

    public entry fun submit_game(game: &Game, season: &mut Season) {
        let top_tile = *game::top_tile(game);
        let score = *game::score(game);
        let leaderboard = &mut season.leaderboard;

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

    public entry fun mint_rose(
        player_maintainer: &mut PlayMaintainer,
        game: &Game,
        season: &mut Season,
        clock: &Clock,
        ctx: &mut TxContext
    ){
        //game time
        assert!(*game::game_created_at(game) >= season.start_time, EGmaeIsNotCurrentSeason);
        assert!(clock::timestamp_ms(clock) <= season.end_time, ESeasonIsEnded);

        let game_id = game::id(game);
        assert!(!vector::contains(&season.games_minted_rose, &game_id), EGameMintedRose);
        vector::push_back(&mut season.games_minted_rose, game_id);

        let game_player = *game::player(game);
        let player = tx_context::sender(ctx);
        assert!(game_player == player, EInvalidPlayer);

        let player_id = get_player_id(player_maintainer, &player);
        assert!(contains(&season.player_infos, player_id), EInvalidPlayer);
        let player_info = table::borrow_mut(&mut season.player_infos, player_id);
        rose::mint_to_sender(player_info.team, clock, ctx);

        assert!(contains(&season.team_infos, player_info.team), EInvalidTeam);
        let team_info = table::borrow_mut(&mut season.team_infos, player_info.team);

        let leaderboard = &mut season.leaderboard;
        leaderboard.winner_game = TopGame {
            game_id,
            leader_address: player,
            score: *game::score(game),
            top_tile: *game::top_tile(game)
        };
        season.winner_player = player_id;
        season.winner_team = player_info.team;
        season.rose_cur = season.rose_cur + 1;
        player_info.rose_cur = player_info.rose_cur + 1;
        team_info.rose_cur = team_info.rose_cur + 1;
    }

    // INTERNAL FUNCTIONS //
    fun end_season(
        global: &mut GlobalConfig,
        season: &mut Season,
        clock: &Clock,
        ctx: &mut TxContext
    ){
        let winner_team = season.winner_team;
        let winner_player = season.winner_player;

        let season_pot_value = balance::value(&season.pot);

        let winner_prize = coin::take<SUI>(
            &mut season.pot,
            season_pot_value * POT_TO_WINNER_PRIZE_RATE / 100,
            ctx
        );
        let next_season_pot = coin::take<SUI>(
            &mut season.pot,
            season_pot_value * POT_TO_NEXT_SEASON_POT_RATE / 100,
            ctx
        );
        let platform = coin::take<SUI>(
            &mut season.pot,
            season_pot_value * POT_TO_PLATFORM_RATE / 100,
            ctx
        );

        //get team info
        let team_info = table::borrow_mut(&mut season.team_infos, winner_team);
        let keys_holder_prize;
        let rose_holder_prize;
        if (winner_team == TEAM_WHITE){
            keys_holder_prize = coin::take<SUI>(
                &mut season.pot,
                season_pot_value * POT_TO_WINNER_TEAM_KEYS_HOLDER_WHITE / 100,
                ctx
            );
            rose_holder_prize = coin::take<SUI>(
                &mut season.pot,
                season_pot_value * POT_TO_WINNER_TEAM_ROSE_HOLDER_WHITE / 100,
                ctx
            );
        } else {
            keys_holder_prize = coin::take<SUI>(
                &mut season.pot,
                season_pot_value * POT_TO_WINNER_TEAM_KEYS_HOLDER_RED / 100,
                ctx
            );
            rose_holder_prize = coin::take<SUI>(
                &mut season.pot,
                season_pot_value * POT_TO_WINNER_TEAM_ROSE_HOLDER_RED / 100,
                ctx
            );
        };

        //to winner player
        let winner_vault = table::borrow_mut(&mut global.player_vaults, winner_player);
        coin::put(&mut winner_vault.win_vault, winner_prize);

        //to platform
        coin::put(&mut global.platform, platform);

        let winner_info = table::borrow_mut(&mut season.player_infos, winner_player);
        let winner_hold_keys = winner_info.keys_cur;
        //to keys holder
        team_info.pot_per_key = coin::value(&keys_holder_prize) * 1000 / (team_info.keys_cur - winner_hold_keys);
        coin::put(&mut team_info.keys_holder_pot, keys_holder_prize);

        //to rose holder
        let winner_hold_rose = winner_info.rose_cur;
        team_info.pot_per_rose = coin::value(&rose_holder_prize) * 1000 / (team_info.rose_cur - winner_hold_rose);
        coin::put(&mut team_info.rose_holder_pot, rose_holder_prize);

        //to next season
        create_season(global, next_season_pot, clock, ctx);

        season.ended = true;
    }

    fun allocation_entry_funds(
        global: &mut GlobalConfig,
        season: &mut Season,
        paid: Coin<SUI>,
        keys: u64,
        player_id: u64,
        affiliate_id: u64,
        team: u64,
        ctx: &mut TxContext
    ) {
        //verify team WHITE or RED
        assert!(team == TEAM_WHITE || team == TEAM_RED, EInvalidTeam);

        //dividend
        let paid_amount = coin::value(&paid);
        let team_info = table::borrow_mut(&mut season.team_infos, team);

        //update team info
        team_info.sui_cur = team_info.sui_cur + paid_amount;
        team_info.keys_cur = team_info.keys_cur + keys;

        //add player to team
        // if (!contains(&team_info.player_info, player_id)){
        //     let player_info = PlayInfoInTeam{
        //         sui_cur: 0u64,
        //         keys_cur: 0u64,
        //         game_count: 0u64,
        //         rose_cur: 0u64,
        //     };
        //     table::add(&mut team_info.player_info, player_id, player_info);
        // };
        // let player_info = table::borrow_mut(&mut team_info.player_info, player_id);
        // player_info.sui_cur = player_info.sui_cur + paid_amount;
        // player_info.keys_cur = player_info.keys_cur + keys;

        let (
            pot,
            dividend,
            referral_reward,
            airdrop,
            _platform
        ) = get_dividend_amount(paid_amount, team);

        //to referral
        let affiliater = table::borrow_mut(&mut global.player_vaults, affiliate_id);
        coin::put(&mut affiliater.affiliate_vault, coin::split(&mut paid, referral_reward, ctx));

        coin::put(&mut season.pot, coin::split(&mut paid, pot, ctx));
        coin::put(&mut season.dividend, coin::split(&mut paid, dividend, ctx));
        coin::put(&mut season.airdrop, coin::split(&mut paid, airdrop, ctx));

        coin::put(&mut global.platform, paid);

        //update masks
        update_masks(season, dividend, keys, player_id);
    }

    fun update_masks(
        season: &mut Season,
        dividend: u64,
        keys: u64,
        player_id: u64,
    ){
        // calc profit per key & round mask based on this buy:  (dust goes to pot)
        let profit_per_key = dividend * 1000 / season.keys_cur;
        season.mask = season.mask + profit_per_key;

        // calculate player earning from their own buy (only based on the keys
        // they just bought).  & update player earnings mask
        let earn_player = profit_per_key * keys / 1000;
        let player_info = table::borrow_mut(&mut season.player_infos, player_id);
        player_info.mask = ((player_info.mask * keys / 1000) - earn_player) + player_info.mask;
    }

    fun get_dividend_amount(
        paid_amount: u64,
        team: u64
    ) : (u64, u64, u64, u64, u64) {

        let pot = paid_amount * DEFAULT_RED_POT;
        let dividend = paid_amount * DEFAULT_RED_DIVIDEND;
        let referral_reward = paid_amount * DEFAULT_REFERRAL_REWARD;
        let airdrop = paid_amount * DEFAULT_AIRDROP;
        let platform = paid_amount * DEFAULT_PLATFORM;

        if (team == TEAM_WHITE){
            pot = paid_amount * DEFAULT_WHITE_POT;          //50%
            dividend = paid_amount * DEFAULT_WHITE_DIVIDEND;  //30%
            referral_reward = paid_amount * DEFAULT_REFERRAL_REWARD; //15%
            airdrop = paid_amount * DEFAULT_AIRDROP;            //2%
            platform = paid_amount * DEFAULT_PLATFORM;           //3%
        };

        (pot/100, dividend/100, referral_reward/100, airdrop/100, platform/100)
    }

    fun calculates_dividend_earning(
        season: &Season,
        player_id: u64,
    ): u64{

        let play_info = table::borrow(&season.player_infos, player_id);
        return season.mask * play_info.keys_cur / 1000 - play_info.mask
    }

    fun calculates_winner_team_keys_earning(
        season: &Season,
        player_id: u64,
    ): u64{
        let play_info = table::borrow(&season.player_infos, player_id);
        let team = play_info.team;

        if ((team != season.winner_team) || (!season.ended)){
            return 0
        } else {
            return table::borrow(&season.team_infos, team).pot_per_key * play_info.keys_cur
        }
    }

    fun calculates_winner_team_rose_earning(
        season: &Season,
        player_id: u64,
    ): u64{
        let play_info = table::borrow(&season.player_infos, player_id);
        let team = play_info.team;

        if ((team != season.winner_team) || (!season.ended)){
            return 0
        } else {
            return table::borrow(&season.team_infos, team).pot_per_rose * play_info.rose_cur
        }
    }

    // PUBLIC ACCESSOR FUNCTIONS //
    public fun get_address_by_sn(season: &Season, sn: u64): address {
        *table::borrow(&season.sn_players, sn)
    }

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

    public fun merge_and_split(
        coins: vector<Coin<SUI>>, amount: u64, ctx: &mut TxContext
    ): (Coin<SUI>, Coin<SUI>) {
        let base = vector::pop_back(&mut coins);
        pay::join_vec(&mut base, coins);
        let coin_value = coin::value(&base);
        assert!(coin_value >= amount, coin_value);
        (coin::split(&mut base, amount, ctx), base)
    }

    // TEST FUNCTIONS //

    // #[test_only]
    // use sui::test_scenario::{Self, Scenario};
    //
    // #[test_only]
    // public fun blank_leaderboard(scenario: &mut Scenario, max_leaderboard_game_count: u64, min_tile: u64, min_score: u64) {
    //     let ctx = test_scenario::ctx(scenario);
    //     let leaderboard = Leaderboard {
    //         id: object::new(ctx),
    //         max_leaderboard_game_count,
    //         top_games: vector<TopGame>[],
    //         min_tile,
    //         min_score
    //     };
    //
    //     transfer::share_object(leaderboard)
    // }

    // #[test_only]
    // public fun top_game(scenario: &mut Scenario, leader_address: address, top_tile: u64, score: u64): TopGame {
    //     let ctx = test_scenario::ctx(scenario);
    //     let object = object::new(ctx);
    //     let game_id = object::uid_to_inner(&object);
    //     sui::test_utils::destroy<sui::object::UID>(object);
    //     TopGame {
    //         game_id,
    //         leader_address,
    //         top_tile,
    //         score
    //     }
    // }
}