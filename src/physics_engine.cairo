%lang starknet
from starkware.cairo.common.math_cmp import is_le
from starkware.cairo.common.math import (
    sqrt, 
    abs_value,
    signed_div_rem,
    unsigned_div_rem,
    assert_le,
    sign
)
from src.structs import (
    Location, 
    SwingDirection
)

const FP = 10 ** 12
const RANGE_CHECK_BOUND = 2 ** 125

# TODO refactor as @contract_interface
# @notice contains physics engine to calculate new location of ball
# @dev 
func get_new_location{range_check_ptr}(
        last_loc : Location,
        swing_power : felt,
        swing_force : felt,
        unit_vector : SwingDirection
    ) -> (new_loc : Location):

    alloc_locals

    # based on -9.8 m/s^2 Earth gravity
    # to keep cairo math simple, deceleration is a positive number
    let gravity = 98 * FP / 10

    # ground friction coefficient
    let mu = 27 * FP / 100

    # acceleration
    let (local a_x) = mul(mu, gravity)

    # P = Fv
    #   where P is power, F is force
    let (v_init) = div(swing_power, swing_force)

    # v_f^2 = v_init^2 + 2 * a_x * dist
    #   where v_f = 0, v_init = P / F
    let denominator = 2 * a_x
    let (numerator) = mul(v_init, v_init)
    let (dist) = div(numerator, denominator)

    # get final position
    let x_final = last_loc.x + dist

    return (Location(x=x_final, y=0, z=0))
end

func mul{range_check_ptr}(
        a : felt,
        b : felt
    ) -> (c : felt):
    let (c, _) = signed_div_rem(a * b, FP, RANGE_CHECK_BOUND)
    return (c)
end

func div{range_check_ptr} (
        a : felt,
        b : felt
    ) -> (c : felt):
    let (c, _) = signed_div_rem(a * FP, b, RANGE_CHECK_BOUND)
    return (c)
end