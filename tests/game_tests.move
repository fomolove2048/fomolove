
#[test_only]
module fomolove2048::game_tests {
    use fomolove2048::player;
    use sui::clock;
    use sui::coin;
    use sui::sui::SUI;
    use sui::test_scenario::{Self, Scenario};
    use sui::test_utils;
    use fomolove2048::game::{Self, Game};
    use fomolove2048::game_board::{Self, left, up};
    use fomolove2048::player::PlayMaintainer;
    use fomolove2048::season::{Self, GlobalConfig, Season};

    const ADMIN: address = @fomolove2048;
    const PLAYER: address = @0xCAFE;
    const OTHER: address = @0xA1C05;

    // fun create_game(scenario: &mut Scenario) {
    //     let ctx = test_scenario::ctx(scenario);
    //     // let ctx = tx_context::dummy();
    //     let clock = clock::create_for_testing(ctx);
    //
    //     let player_maintainer = test_scenario::take_shared<PlayMaintainer>(scenario);
    //
    //     let global = test_scenario::take_shared<GlobalConfig>(scenario);
    //
    //     season::create_season_entry(&mut global, &clock, ctx);
    //     let season_id = season::get_season_by_id(&global, 0);
    //     let season = test_scenario::take_shared_by_id<Season>(scenario, season_id);
    //
    //     game::start_game(&mut player_maintainer, &mut global, &mut season, 1, &clock, ctx);
    //
    //     test_scenario::return_shared(season);
    //     test_scenario::return_shared(global);
    //     test_scenario::return_shared(player_maintainer);
    //     clock::destroy_for_testing(clock);
    // }

    #[test]
    fun test_game_create() {
        let scenario_val = test_scenario::begin(ADMIN);
        let scenario = &mut scenario_val;

        let ctx = test_scenario::ctx(scenario);
        season::init_test(ctx);

        let ctx = test_scenario::ctx(scenario);
        player::init_test(ctx);

        let ctx = test_scenario::ctx(scenario);
        let owt = test_utils::create_one_time_witness<game::GAME>();
        game::init_test(owt, ctx);

        let ctx = test_scenario::ctx(scenario);
        let clock = clock::create_for_testing(ctx);

        let ctx = test_scenario::ctx(scenario);
        let test_coin = coin::mint_for_testing<SUI>(200*10000000000, ctx);

        //create a season
        test_scenario::next_tx(scenario, ADMIN);
        {
            let global = test_scenario::take_shared<GlobalConfig>(scenario);

            let ctx = test_scenario::ctx(scenario);
            season::create_season_entry(&mut global, &clock, ctx);

            test_scenario::return_shared(global);
        };

        //buy keys
        test_scenario::next_tx(scenario, PLAYER);
        {
            let player_maintainer = test_scenario::take_shared<PlayMaintainer>(scenario);
            let global = test_scenario::take_shared<GlobalConfig>(scenario);
            let season = test_scenario::take_shared<Season>(scenario);

            let ctx = test_scenario::ctx(scenario);

            season::buy_keys(
                &mut player_maintainer,
                &mut global,
                &mut season,
                test_coin,
                10 * 1000000000,
                1,
                0,
                &clock,
                ctx
            );

            test_scenario::return_shared(season);
            test_scenario::return_shared(global);
            test_scenario::return_shared(player_maintainer);
        };

        //start a game
        test_scenario::next_tx(scenario, PLAYER);
        {
            let player_maintainer = test_scenario::take_shared<PlayMaintainer>(scenario);
            let global = test_scenario::take_shared<GlobalConfig>(scenario);
            let season = test_scenario::take_shared<Season>(scenario);

            let ctx = test_scenario::ctx(scenario);
            game::start_game(&mut player_maintainer, &mut global, &mut season, &clock, ctx);

            test_scenario::return_shared(season);
            test_scenario::return_shared(global);
            test_scenario::return_shared(player_maintainer);
        };

        //move a game
        test_scenario::next_tx(scenario, PLAYER);
        {
            let game = test_scenario::take_from_sender<Game>(scenario);

            assert!(game::player(&game) == &PLAYER, 0);
            assert!(game::move_count(&game) == &0, 1);

            let game_board = game::active_board(&game);
            let empty_space_count = game_board::empty_space_count(game_board);
            assert!(empty_space_count == 14, empty_space_count);

            test_scenario::return_to_sender(scenario, game)
        };

        clock::destroy_for_testing(clock);
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_raw_gas() {
        let scenario_val = test_scenario::begin(ADMIN);
        let scenario = &mut scenario_val;

        let ctx = test_scenario::ctx(scenario);
        season::init_test(ctx);

        let ctx = test_scenario::ctx(scenario);
        player::init_test(ctx);

        let ctx = test_scenario::ctx(scenario);
        let owt = test_utils::create_one_time_witness<game::GAME>();
        game::init_test(owt, ctx);

        let ctx = test_scenario::ctx(scenario);
        let clock = clock::create_for_testing(ctx);

        let ctx = test_scenario::ctx(scenario);
        let test_coin = coin::mint_for_testing<SUI>(200*10000000000, ctx);

        //create a season
        test_scenario::next_tx(scenario, ADMIN);
        {
            let global = test_scenario::take_shared<GlobalConfig>(scenario);

            let ctx = test_scenario::ctx(scenario);
            season::create_season_entry(&mut global, &clock, ctx);

            test_scenario::return_shared(global);
        };

        //buy keys
        test_scenario::next_tx(scenario, PLAYER);
        {
            let player_maintainer = test_scenario::take_shared<PlayMaintainer>(scenario);
            let global = test_scenario::take_shared<GlobalConfig>(scenario);
            let season = test_scenario::take_shared<Season>(scenario);

            let ctx = test_scenario::ctx(scenario);

            season::buy_keys(
                &mut player_maintainer,
                &mut global,
                &mut season,
                test_coin,
                10 * 1000000000,
                1,
                0,
                &clock,
                ctx
            );

            test_scenario::return_shared(season);
            test_scenario::return_shared(global);
            test_scenario::return_shared(player_maintainer);
        };

        //start a game
        test_scenario::next_tx(scenario, PLAYER);
        {
            let player_maintainer = test_scenario::take_shared<PlayMaintainer>(scenario);
            let global = test_scenario::take_shared<GlobalConfig>(scenario);
            let season = test_scenario::take_shared<Season>(scenario);

            let ctx = test_scenario::ctx(scenario);
            game::start_game(&mut player_maintainer, &mut global, &mut season, &clock, ctx);

            test_scenario::return_shared(season);
            test_scenario::return_shared(global);
            test_scenario::return_shared(player_maintainer);
        };

        test_scenario::next_tx(scenario, PLAYER);
        {
            let player_maintainer = test_scenario::take_shared<PlayMaintainer>(scenario);
            let global = test_scenario::take_shared<GlobalConfig>(scenario);
            let season = test_scenario::take_shared<Season>(scenario);
            let game = test_scenario::take_from_sender<Game>(scenario);

            let ctx = test_scenario::ctx(scenario);
            game::make_move(&mut player_maintainer,  &mut season, &mut game, left(), &clock, ctx);

            test_scenario::return_to_sender(scenario, game);
            test_scenario::return_shared(season);
            test_scenario::return_shared(global);
            test_scenario::return_shared(player_maintainer);
        };

        clock::destroy_for_testing(clock);
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_make_move() {
        let scenario_val = test_scenario::begin(ADMIN);
        let scenario = &mut scenario_val;

        let ctx = test_scenario::ctx(scenario);
        season::init_test(ctx);

        let ctx = test_scenario::ctx(scenario);
        player::init_test(ctx);

        let ctx = test_scenario::ctx(scenario);
        let owt = test_utils::create_one_time_witness<game::GAME>();
        game::init_test(owt, ctx);

        let ctx = test_scenario::ctx(scenario);
        let clock = clock::create_for_testing(ctx);

        let ctx = test_scenario::ctx(scenario);
        let test_coin = coin::mint_for_testing<SUI>(200*10000000000, ctx);

        //create a season
        test_scenario::next_tx(scenario, ADMIN);
        {
            let global = test_scenario::take_shared<GlobalConfig>(scenario);

            let ctx = test_scenario::ctx(scenario);
            season::create_season_entry(&mut global, &clock, ctx);

            test_scenario::return_shared(global);
        };

        //buy keys
        test_scenario::next_tx(scenario, PLAYER);
        {
            let player_maintainer = test_scenario::take_shared<PlayMaintainer>(scenario);
            let global = test_scenario::take_shared<GlobalConfig>(scenario);
            let season = test_scenario::take_shared<Season>(scenario);

            let ctx = test_scenario::ctx(scenario);

            season::buy_keys(
                &mut player_maintainer,
                &mut global,
                &mut season,
                test_coin,
                10 * 1000000000,
                1,
                0,
                &clock,
                ctx
            );

            test_scenario::return_shared(season);
            test_scenario::return_shared(global);
            test_scenario::return_shared(player_maintainer);
        };

        //start a game
        test_scenario::next_tx(scenario, PLAYER);
        {
            let player_maintainer = test_scenario::take_shared<PlayMaintainer>(scenario);
            let global = test_scenario::take_shared<GlobalConfig>(scenario);
            let season = test_scenario::take_shared<Season>(scenario);

            let ctx = test_scenario::ctx(scenario);
            game::start_game(&mut player_maintainer, &mut global, &mut season, &clock, ctx);

            test_scenario::return_shared(season);
            test_scenario::return_shared(global);
            test_scenario::return_shared(player_maintainer);
        };

        test_scenario::next_tx(scenario, PLAYER);
        {
            let player_maintainer = test_scenario::take_shared<PlayMaintainer>(scenario);
            let global = test_scenario::take_shared<GlobalConfig>(scenario);
            let season = test_scenario::take_shared<Season>(scenario);
            let game = test_scenario::take_from_sender<Game>(scenario);

            let board = game::active_board(&game);
            let space_value = game_board::board_space_at(board, 1, 1);
            // assert!(space_value == 1, space_value);  ??????????????
            let space_value1 = game_board::board_space_at(board, 0, 0);
            assert!(space_value1 == 0, 1);

            let ctx = test_scenario::ctx(scenario);
            game::make_move(&mut player_maintainer,  &mut season, &mut game, left(), &clock, ctx);
            let ctx = test_scenario::ctx(scenario);
            game::make_move(&mut player_maintainer,  &mut season, &mut game, up(), &clock, ctx);

            assert!(game::move_count(&game) == &2, *game::move_count(&game));
            assert!(game::score(&game) == &4, *game::score(&game));
            assert!(game::top_tile(&game) == &2, (*game::top_tile(&game) as u64));

            board = game::active_board(&game);
            let space_value = game_board::board_space_at(board, 0, 0);
            assert!(space_value == 2, space_value);
            let space_value1 = game_board::board_space_at(board, 0, 1);
            assert!(space_value1 == 0, space_value1);

            test_scenario::return_to_sender(scenario, game);
            test_scenario::return_shared(season);
            test_scenario::return_shared(global);
            test_scenario::return_shared(player_maintainer);
        };

        clock::destroy_for_testing(clock);
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_burn_game() {
        let scenario_val = test_scenario::begin(ADMIN);
        let scenario = &mut scenario_val;

        let ctx = test_scenario::ctx(scenario);
        season::init_test(ctx);

        let ctx = test_scenario::ctx(scenario);
        player::init_test(ctx);

        let ctx = test_scenario::ctx(scenario);
        let owt = test_utils::create_one_time_witness<game::GAME>();
        game::init_test(owt, ctx);

        let ctx = test_scenario::ctx(scenario);
        let clock = clock::create_for_testing(ctx);

        let ctx = test_scenario::ctx(scenario);
        let test_coin = coin::mint_for_testing<SUI>(200*10000000000, ctx);

        //create a season
        test_scenario::next_tx(scenario, ADMIN);
        {
            let global = test_scenario::take_shared<GlobalConfig>(scenario);

            let ctx = test_scenario::ctx(scenario);
            season::create_season_entry(&mut global, &clock, ctx);

            test_scenario::return_shared(global);
        };

        //buy keys
        test_scenario::next_tx(scenario, PLAYER);
        {
            let player_maintainer = test_scenario::take_shared<PlayMaintainer>(scenario);
            let global = test_scenario::take_shared<GlobalConfig>(scenario);
            let season = test_scenario::take_shared<Season>(scenario);

            let ctx = test_scenario::ctx(scenario);

            season::buy_keys(
                &mut player_maintainer,
                &mut global,
                &mut season,
                test_coin,
                10 * 1000000000,
                1,
                0,
                &clock,
                ctx
            );

            test_scenario::return_shared(season);
            test_scenario::return_shared(global);
            test_scenario::return_shared(player_maintainer);
        };

        //start a game
        test_scenario::next_tx(scenario, PLAYER);
        {
            let player_maintainer = test_scenario::take_shared<PlayMaintainer>(scenario);
            let global = test_scenario::take_shared<GlobalConfig>(scenario);
            let season = test_scenario::take_shared<Season>(scenario);

            let ctx = test_scenario::ctx(scenario);
            game::start_game(&mut player_maintainer, &mut global, &mut season, &clock, ctx);

            test_scenario::return_shared(season);
            test_scenario::return_shared(global);
            test_scenario::return_shared(player_maintainer);
        };

        //move a game
        test_scenario::next_tx(scenario, PLAYER);
        {
            let game = test_scenario::take_from_sender<Game>(scenario);

            game::burn_game(game);
        };

        clock::destroy_for_testing(clock);
        test_scenario::end(scenario_val);
    }
}