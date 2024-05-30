
#[test_only]
module fomolove2048::season_tests {
    use std::string::utf8;
    use sui::balance;
    use sui::clock;
    use sui::coin;
    use sui::coin::Coin;
    use sui::sui::SUI;
    use sui::test_scenario::{Self};
    use sui::test_utils;

    use fomolove2048::season::{Self, GlobalConfig, Season};
    use fomolove2048::player::{Self, PlayMaintainer};

    const ADMIN: address = @fomolove2048;
    const PLAYER: address = @0x11;
    const PLAYER2: address = @0x12;

    #[test]
    fun test_season_create() {
        let scenario_val = test_scenario::begin(ADMIN);
        let scenario = &mut scenario_val;

        let ctx = test_scenario::ctx(scenario);
        season::init_test(ctx);

        let ctx = test_scenario::ctx(scenario);
        player::init_test(ctx);

        let ctx = test_scenario::ctx(scenario);
        let clock = clock::create_for_testing(ctx);

        let ctx = test_scenario::ctx(scenario);
        let test_coin = coin::mint_for_testing<SUI>(200*1000000000, ctx);

        let ctx = test_scenario::ctx(scenario);
        let test_coin2 = coin::mint_for_testing<SUI>(2000*1000000000, ctx);

        let ctx = test_scenario::ctx(scenario);
        let test_coin3 = coin::mint_for_testing<SUI>(20000*1000000000, ctx);
        //create a season
        test_scenario::next_tx(scenario, ADMIN);
        {
            let global = test_scenario::take_shared<GlobalConfig>(scenario);

            let ctx = test_scenario::ctx(scenario);
            season::create_season_entry(&mut global, &clock, ctx);

            test_scenario::return_shared(global);
        };

        //read a season
        test_scenario::next_tx(scenario, PLAYER);
        {
            let global = test_scenario::take_shared<GlobalConfig>(scenario);

            let season_id = season::get_season_by_id(&global, 1);
            let season = test_scenario::take_shared_by_id<Season>(scenario, season_id);

            let (winner_team, winner_player, winner_prize) = season::season_winner(&season);

            assert!(winner_team == 0, 1);
            assert!(winner_player == 0, 2);
            assert!(winner_prize == 0, 3);

            test_scenario::return_shared(season);
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
                1 * 1000000000,
                1,
                0,
                &clock,
                ctx
            );

            test_scenario::return_shared(season);
            test_scenario::return_shared(global);
            test_scenario::return_shared(player_maintainer);
        };

        //check keys
        test_scenario::next_tx(scenario, PLAYER);
        {
            let cur_keys = fomolove2048::keys_calc::keys(100000*1000000000);
            std::debug::print(&cur_keys);

            cur_keys = fomolove2048::keys_calc::keys(150000000);
            std::debug::print(&cur_keys);

            let cur_sui = fomolove2048::keys_calc::sui(1*1000000000);
            std::debug::print(&cur_sui);


            cur_keys = fomolove2048::keys_calc::keys(0);
            std::debug::print(&cur_keys);

            std::debug::print(&(fomolove2048::keys_calc::sui_rec(0*000000000, 2*1000000000) as u64));
            std::debug::print(&fomolove2048::keys_calc::sui_rec(0*000000000, 10000*1000000000));
            std::debug::print(&fomolove2048::keys_calc::sui_rec(0*000000000, 100000*1000000000));
            std::debug::print(&fomolove2048::keys_calc::sui_rec(0*000000000, 1000000*1000000000));
        };

        //PLAYER2 buy keys
        test_scenario::next_tx(scenario, PLAYER2);
        {
            let player_maintainer = test_scenario::take_shared<PlayMaintainer>(scenario);
            let global = test_scenario::take_shared<GlobalConfig>(scenario);
            let season = test_scenario::take_shared<Season>(scenario);

            let ctx = test_scenario::ctx(scenario);

            season::buy_keys(
                &mut player_maintainer,
                &mut global,
                &mut season,
                test_coin2,
                2 * 1000000000,
                1,
                1,
                &clock,
                ctx
            );

            test_scenario::return_shared(season);
            test_scenario::return_shared(global);
            test_scenario::return_shared(player_maintainer);
        };

        //withdraw_earnings
        test_scenario::next_tx(scenario, PLAYER2);
        {
            let player_maintainer = test_scenario::take_shared<PlayMaintainer>(scenario);
            let global = test_scenario::take_shared<GlobalConfig>(scenario);
            let season = test_scenario::take_shared<Season>(scenario);

            let ctx = test_scenario::ctx(scenario);

            season::withdraw_earnings(
                &mut player_maintainer,
                &mut global,
                &mut season,
                ctx
            );

            test_scenario::return_shared(season);
            test_scenario::return_shared(global);
            test_scenario::return_shared(player_maintainer);
            clock::increment_for_testing(&mut clock, 24*60*60*20000000000);
        };

        //PLAYER2 buy keys
        test_scenario::next_tx(scenario, PLAYER2);
        {
            let player_maintainer = test_scenario::take_shared<PlayMaintainer>(scenario);
            let global = test_scenario::take_shared<GlobalConfig>(scenario);
            let season = test_scenario::take_shared<Season>(scenario);
            // let coin_player2 = test_scenario::take_from_address<Coin<SUI>>(scenario, PLAYER2);

            let ctx = test_scenario::ctx(scenario);

            season::buy_keys(
                &mut player_maintainer,
                &mut global,
                &mut season,
                test_coin3,
                10 * 1000000000,
                1,
                1,
                &clock,
                ctx
            );

            test_scenario::return_shared(season);
            test_scenario::return_shared(global);
            test_scenario::return_shared(player_maintainer);
        };

        // coin::burn_for_testing(test_coin);
        clock::destroy_for_testing(clock);
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_register_name() {
        let scenario_val = test_scenario::begin(ADMIN);
        let scenario = &mut scenario_val;

        let ctx = test_scenario::ctx(scenario);
        season::init_test(ctx);

        let ctx = test_scenario::ctx(scenario);
        player::init_test(ctx);

        let ctx = test_scenario::ctx(scenario);
        let clock = clock::create_for_testing(ctx);

        let ctx = test_scenario::ctx(scenario);
        let test_coin = coin::mint_for_testing<SUI>(200*1000000000, ctx);

        //create a season
        test_scenario::next_tx(scenario, PLAYER);
        {
            let player_maintainer = test_scenario::take_shared<PlayMaintainer>(scenario);
            let global = test_scenario::take_shared<GlobalConfig>(scenario);

            let ctx = test_scenario::ctx(scenario);
            season::register_name(
                &mut player_maintainer,
                &mut global,
                test_coin,
                utf8(b"test"),
                0,
                ctx
            );

            test_scenario::return_shared(player_maintainer);
            test_scenario::return_shared(global);
        };

        //read a season
        test_scenario::next_tx(scenario, PLAYER);
        {
            let player_maintainer = test_scenario::take_shared<PlayMaintainer>(scenario);
            assert!(player::view_player_id_by_address(&player_maintainer,PLAYER) == 1, 1);
            assert!(player::view_player_address_by_id(&player_maintainer,1) == PLAYER, 2);
            assert!(player::view_player_id_by_name(&player_maintainer,utf8(b"test")) == 1, 3);
            assert!(player::view_player_aff_id(&player_maintainer,1) == 0, 1);
            assert!(player::view_player_name_list(&player_maintainer,1) == vector[utf8(b"test")], 4);
            assert!(player::view_player_actived_name_by_player_id(&player_maintainer,1) == utf8(b"test"), 5);
            assert!(player::view_player_actived_name_by_player_address(&player_maintainer,PLAYER) == utf8(b"test"), 6);
            assert!(player::get_player_id(&mut player_maintainer, &PLAYER) == 1, 7);
            assert!(player::get_player_id(&mut player_maintainer, &PLAYER2) == 2, 8);

            let coin_admin = test_scenario::take_from_address<Coin<SUI>>(scenario, ADMIN);

            assert!(coin::value(&coin_admin) == 20*1000000000, 9);

            test_scenario::return_to_address(ADMIN, coin_admin);
            test_scenario::return_shared(player_maintainer);
        };

        clock::destroy_for_testing(clock);
        test_scenario::end(scenario_val);
    }


}