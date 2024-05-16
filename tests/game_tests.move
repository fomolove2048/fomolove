
#[test_only]
module fomolove2048::game_tests {
    use sui::clock;
    use sui::test_scenario::{Self, Scenario};
    use fomolove2048::game::{Self, Game};
    use fomolove2048::game_board::{Self, left, up};
    use fomolove2048::player::PlayMaintainer;
    use fomolove2048::season::{Self, GlobalConfig, Season};

    const PLAYER: address = @0xCAFE;
    const OTHER: address = @0xA1C05;

    fun create_game(scenario: &mut Scenario) {
        let ctx = test_scenario::ctx(scenario);
        // let ctx = tx_context::dummy();
        let clock = clock::create_for_testing(ctx);

        let player_maintainer = test_scenario::take_shared<PlayMaintainer>(scenario);

        let global = test_scenario::take_shared<GlobalConfig>(scenario);

        season::create_season_entry(&mut global, &clock, ctx);
        let season_id = season::get_season_by_id(&global, 0);
        let season = test_scenario::take_shared_by_id<Season>(scenario, season_id);

        game::start_game(&mut player_maintainer, &mut global, &mut season, 1, &clock, ctx);

        test_scenario::return_shared(season);
        test_scenario::return_shared(global);
        test_scenario::return_shared(player_maintainer);
        clock::destroy_for_testing(clock);
    }

    fun test_game_create() {
        let scenario = test_scenario::begin(PLAYER);
        {
            create_game(&mut scenario);
        };

        test_scenario::next_tx(&mut scenario, PLAYER);
        {
            let game = test_scenario::take_from_sender<Game>(&mut scenario);
            
            assert!(game::player(&game) == &PLAYER, 0);
            assert!(game::move_count(&game) == &0, 1);

            let game_board = game::active_board(&game);
            let empty_space_count = game_board::empty_space_count(game_board);
            assert!(empty_space_count == 14, empty_space_count);

            test_scenario::return_to_sender(&mut scenario, game)
        };

        test_scenario::end(scenario);
    }

    #[test]
    fun test_raw_gas() {
        let scenario = test_scenario::begin(PLAYER);
        {
            create_game(&mut scenario);
        };

        test_scenario::next_tx(&mut scenario, PLAYER);
        {
            let ctx = test_scenario::ctx(&mut scenario);
            let game = test_scenario::take_from_sender<Game>(&mut scenario);

            let player_maintainer = test_scenario::take_shared<PlayMaintainer>(&mut scenario);

            let global = test_scenario::take_shared<GlobalConfig>(&mut scenario);
            let season_id = season::get_season_by_id(&global, 0);
            let season = test_scenario::take_shared_by_id<Season>(&mut scenario, season_id);
            let clock = clock::create_for_testing(ctx);
            
            game::make_move(&mut player_maintainer,  &mut season, &mut game, left(), &clock, ctx);

            clock::destroy_for_testing(clock);
            test_scenario::return_shared(season);
            test_scenario::return_shared(global);
            test_scenario::return_shared(player_maintainer);
            test_scenario::return_to_sender(&mut scenario, game);
        };

        test_scenario::end(scenario);
    }

    #[test]
    fun test_make_move() {
        let scenario = test_scenario::begin(PLAYER);
        {
            create_game(&mut scenario);
        };

        test_scenario::next_tx(&mut scenario, PLAYER);
        {
            let ctx = test_scenario::ctx(&mut scenario);
            let game = test_scenario::take_from_sender<Game>(&mut scenario);

            let player_maintainer = test_scenario::take_shared<PlayMaintainer>(&mut scenario);
            let global = test_scenario::take_shared<GlobalConfig>(&mut scenario);
            let season_id = season::get_season_by_id(&global, 0);
            let season = test_scenario::take_shared_by_id<Season>(&mut scenario, season_id);
            let clock = clock::create_for_testing(ctx);

            let board = game::active_board(&game);
            let space_value = game_board::board_space_at(board, 1, 1);
            assert!(space_value == 1, space_value);
            let space_value1 = game_board::board_space_at(board, 0, 0);
            assert!(space_value1 == 0, 1);

            game::make_move(&mut player_maintainer,  &mut season, &mut game, left(), &clock, ctx);
            game::make_move(&mut player_maintainer,  &mut season, &mut game, up(), &clock, ctx);

            assert!(game::move_count(&game) == &2, *game::move_count(&game));
            assert!(game::score(&game) == &4, *game::score(&game));
            assert!(game::top_tile(&game) == &2, (*game::top_tile(&game) as u64));

            board = game::active_board(&game);
            let space_value = game_board::board_space_at(board, 0, 0);
            assert!(space_value == 2, space_value);
            let space_value1 = game_board::board_space_at(board, 0, 1);
            assert!(space_value1 == 0, space_value1);

            clock::destroy_for_testing(clock);
            test_scenario::return_shared(season);
            test_scenario::return_shared(global);
            test_scenario::return_shared(player_maintainer);
            test_scenario::return_to_sender(&mut scenario, game);
        };

        test_scenario::end(scenario);
    }

    #[test]
    fun test_burn_game() {
        let scenario = test_scenario::begin(PLAYER);
        {
            create_game(&mut scenario);
        };

        test_scenario::next_tx(&mut scenario, PLAYER);
        {
            let game = test_scenario::take_from_sender<Game>(&mut scenario);
            game::burn_game(game);
        };

        test_scenario::end(scenario);
    }
}