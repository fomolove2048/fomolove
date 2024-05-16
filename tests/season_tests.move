
#[test_only]
module fomolove2048::season_tests {
    // use sui::clock;
    // use sui::test_scenario::{Self, Scenario};
    //
    // use fomolove2048::player::PlayMaintainer;
    // use fomolove2048::season::{Self, GlobalConfig, Season};
    // use fomolove2048::game::{Self};
    //
    // const PLAYER: address = @0xCAFE;
    //
    // fun create_game(scenario: &mut Scenario) {
    //     // let ctx = test_scenario::ctx(scenario);
    //     // let ctx = tx_context::dummy();
    //     let clock = clock::create_for_testing(test_scenario::ctx(scenario));
    //
    //     let player_maintainer = test_scenario::take_shared<PlayMaintainer>(scenario);
    //
    //     let global = test_scenario::take_shared<GlobalConfig>(scenario);
    //
    //     season::create_season_entry(&mut global, &clock, test_scenario::ctx(scenario));
    //     let season_id = season::get_season_by_id(&global, 0);
    //     let season = test_scenario::take_shared_by_id<Season>(scenario, season_id);
    //
    //     game::start_game(&mut player_maintainer, &mut global, &mut season, 1, &clock, test_scenario::ctx(scenario));
    //
    //     test_scenario::return_shared(season);
    //     test_scenario::return_shared(global);
    //     test_scenario::return_shared(player_maintainer);
    //     clock::destroy_for_testing(clock);
    // }

    // fun make_move_if_valid(game: &mut Game, direction: u64, ctx: &mut TxContext) {
    //     let board = game::active_board(game);
    //     let spaces = *packed_spaces(board);
    //     let (new_spaces, _, _) = move_spaces(spaces, direction);
    //
    //     if (spaces != new_spaces) {
    //         game::make_move(game, direction, ctx);
    //     };
    // }

}