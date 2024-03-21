module fomolove2048::keys_calc {
    use sui::math::{sqrt_u128};

    friend fomolove2048::season;

    const CACL_DECIMALS:u128 = 10^18;

    //calculates how many keys would exist with given an amount of sui
    public(friend) fun keys(suis: u128): u128{
        return (sqrt_u128(suis * 312500000 + 74999921875000) - 74999921875000) * CACL_DECIMALS / 156250000
    }

    //calculates how much sui would be in contract given a number of keys
    public(friend) fun sui(keys: u128): u128{
        return (78125000 * sqrt_u128(keys) + 149999843750000 * keys * CACL_DECIMALS / 2) / sqrt_u128(CACL_DECIMALS)
    }

    //calculates number of keys received given X sui
    public(friend) fun keys_rec(cur_sui:u128, new_sui:u128): u128{
        return keys(cur_sui + new_sui) - keys(cur_sui)
    }

    //calculates amount of sui paid if you buy X keys
    public(friend) fun sui_rec(cur_keys:u128, buy_keys:u128): u128{
        return sui(cur_keys + buy_keys) - sui(cur_keys)
    }
}
