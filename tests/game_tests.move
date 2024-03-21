
#[test_only]
module fomolove2048::game_tests {
    use sui::test_scenario::{Self, Scenario};
    use sui::sui::SUI;
    use sui::coin::{Self};

    use fomolove2048::game::{Self, Game8192, Game8192Maintainer};
    use fomolove2048::game_board::{Self, left, up};

    const PLAYER: address = @0xCAFE;
    const OTHER: address = @0xA1C05;

    fun create_game(scenario: &mut Scenario) {
        let ctx = test_scenario::ctx(scenario);

        let maintainer = game::create_maintainer(ctx);

        let coins = vector[
            coin::mint_for_testing<SUI>(150_000_000, ctx),
            coin::mint_for_testing<SUI>(30_000_000, ctx),
            coin::mint_for_testing<SUI>(40_000_000, ctx)
        ];

        game::create(&mut maintainer, coins, ctx);

        sui::test_utils::destroy<Game8192Maintainer>(maintainer);
    }

    fun test_game_create() {
        let scenario = test_scenario::begin(PLAYER);
        {
            create_game(&mut scenario);
        };

        test_scenario::next_tx(&mut scenario, PLAYER);
        {
            let game = test_scenario::take_from_sender<Game8192>(&mut scenario);
            
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
            let game = test_scenario::take_from_sender<Game8192>(&mut scenario);
            
            game::make_move(&mut game, left(), test_scenario::ctx(&mut scenario));

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
            let game = test_scenario::take_from_sender<Game8192>(&mut scenario);
            
            let board = game::active_board(&game);
            let space_value = game_board::board_space_at(board, 1, 1);
            assert!(space_value == 1, space_value);
            let space_value1 = game_board::board_space_at(board, 0, 0);
            assert!(space_value1 == 0, 1);

            game::make_move(&mut game, left(), test_scenario::ctx(&mut scenario));
            game::make_move(&mut game, up(), test_scenario::ctx(&mut scenario));

            assert!(game::move_count(&game) == &2, *game::move_count(&game));
            assert!(game::score(&game) == &4, *game::score(&game));
            assert!(game::top_tile(&game) == &2, (*game::top_tile(&game) as u64));

            board = game::active_board(&game);
            let space_value = game_board::board_space_at(board, 0, 0);
            assert!(space_value == 2, space_value);
            let space_value1 = game_board::board_space_at(board, 0, 1);
            assert!(space_value1 == 0, space_value1);
            
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
            let game = test_scenario::take_from_sender<Game8192>(&mut scenario);
            game::burn_game(game);
        };

        test_scenario::end(scenario);
    }
}