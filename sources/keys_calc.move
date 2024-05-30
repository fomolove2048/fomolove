module fomolove2048::keys_calc {
    use sui::math::{sqrt_u128};

    const CACL_DECIMALS:u128 = 1000000000;

    //calculates how many keys would exist with given an amount of sui
    public fun keys(suis: u128): u128{
        return (sqrt_u128((suis/2000) * CACL_DECIMALS * 312500000 + 5624988281256103515625000000) - 74999921875000) * CACL_DECIMALS / 156250000
    }

    //calculates how much sui would be in contract given a number of keys
    public fun sui(keys: u128): u128{
        return (78125000 * keys * keys / (CACL_DECIMALS * CACL_DECIMALS) + 149999843750000 * keys / 2) *2000 /  (CACL_DECIMALS * CACL_DECIMALS)
    }

    //calculates number of keys received given X sui
    public fun keys_rec(cur_sui:u128, new_sui:u128): u128{
        return keys(cur_sui + new_sui) - keys(cur_sui)
    }

    //calculates amount of sui paid if you buy X keys
    public fun sui_rec(cur_keys:u128, buy_keys:u128): u128{
        return sui(cur_keys + buy_keys) - sui(cur_keys)
    }
}
