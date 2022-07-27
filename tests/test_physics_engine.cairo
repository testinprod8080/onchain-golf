%lang starknet
from starkware.cairo.common.math import (
    sqrt,
    sign,
    signed_div_rem,
    unsigned_div_rem
)
from src.physics_engine import (
    get_new_location,
    mul,
    FP,
    RANGE_CHECK_BOUND
)
from src.structs import (
    SwingDirection,
    GolfClubEnum
)

# TEST - mul

@external
func test_success_mul{range_check_ptr}():
    alloc_locals
    # arrange
    let gravity = -98 * FP / 10
    let mu = 27 * FP / 100

    # act
    let (a_x) = mul(mu, gravity)

    # assert
    let expected = -2646000000000
    assert a_x = expected

    return ()
end