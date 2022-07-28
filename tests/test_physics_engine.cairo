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
    GolfClubEnum,
    Location
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

# TEST - get_new_location

@external
func test_success_new_loc{range_check_ptr}():
    alloc_locals
    # arrange
    let init_location = Location(x=0, y=0, z=0)
    let swing_power = 1000
    let swing_force = 200
    let unit_vector = SwingDirection(x=1, y=0, z=0)

    # act
    let (new_location) = get_new_location(
        last_loc=init_location, 
        swing_power=swing_power,
        swing_force=swing_force,
        unit_vector=unit_vector)

    # assert
    let expected = 4724111866969
    assert new_location.x = expected

    return ()
end