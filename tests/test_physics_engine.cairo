%lang starknet
from starkware.cairo.common.math import (
    sqrt,
    sign,
    signed_div_rem,
    unsigned_div_rem
)
from src.physics_engine import (
    atan,
    sin,
    FP,
    RANGE_CHECK_BOUND
)
from src.structs import (
    SwingDirection,
    GolfClubEnum
)

# @external
# func test_sandbox{range_check_ptr}():
#     let (sqrt3) = sqrt(3)
#     let (sqrt3_3, _) = signed_div_rem(sqrt3 * FP, 3, RANGE_CHECK_BOUND)
    
#     %{
#         print(str(ids.sqrt3_3))
#     %}

#     return ()
# end

# TEST - sin

@external
func test_success_sin_angle{range_check_ptr}():
    let number = 1 * 10**12
    let (angle) = sin(number)

    %{ 
        print(str(ids.angle))
    %}

    assert angle = 841470984809

    return ()
end

@external
func test_success_sin_angle2{range_check_ptr}():
    alloc_locals
    let number = -45 * 10**11
    let (local angle) = sin(number)
    let (local angle_fp, _) = signed_div_rem(angle, FP, RANGE_CHECK_BOUND)
    let (angle_sign) = sign(angle)

    %{ 
        print(str(ids.angle_sign))
        print(str(ids.angle_fp))
        print(str(ids.angle))
    %}
    # let (expected, _) = unsigned_div_rem(
    # assert angle = -97753011766

    return ()
end

# TEST - atan

# @external
# func test_success_atan_angle{range_check_ptr}():
#     let number = 1
#     # let (number, _) = signed_div_rem(161977519054 * FP, 10 ** 11, RANGE_CHECK_BOUND)
#     let (angle) = atan(number)
#     let (angle_fp, _) = signed_div_rem(angle, FP, RANGE_CHECK_BOUND)

#     %{ 
#         print(str(ids.angle))
#         print(str(ids.angle_fp))
#     %}

#     # assert angle = 45

#     return ()
# end