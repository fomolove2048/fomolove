
#[test_only]
module fomolove2048::season_tests {
    use std::option;
    use std::vector;
    use sui::clock;

    use sui::object::ID;
    use sui::sui::SUI;
    use sui::coin::{Self};
    use sui::tx_context::{TxContext};
    use sui::test_scenario::{Self, Scenario};

    use fomolove2048::game_board::{packed_spaces, move_spaces, left, up, right, down};

    use fomolove2048::season::{Self, GlobalConfig, Season};
    use fomolove2048::game::{Self, Game, GameMaintainer};
    
    const PLAYER: address = @0xCAFE;

    fun create_game(scenario: &mut Scenario) {
        let ctx = test_scenario::ctx(scenario);
        let clock = clock::create_for_testing(ctx);

        let maintainer = game::create_maintainer(ctx);

        let coins = vector[
            coin::mint_for_testing<SUI>(150_000_000, ctx),
            coin::mint_for_testing<SUI>(30_000_000, ctx),
            coin::mint_for_testing<SUI>(40_000_000, ctx)
        ];

        game::create(&mut maintainer, coins, &clock, ctx);

        sui::test_utils::destroy<GameMaintainer>(maintainer);
        clock::destroy_for_testing(clock);
    }

    fun make_move_if_valid(game: &mut Game, direction: u64, ctx: &mut TxContext) {
        let board = game::active_board(game);
        let spaces = *packed_spaces(board);
        let (new_spaces, _, _) = move_spaces(spaces, direction);

        if (spaces != new_spaces) {
            game::make_move(game, direction, ctx);
        };
    }

}