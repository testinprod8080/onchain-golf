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
const ONE = 1 * FP
const PI = 3141590000000
const HALF_PI = 1570795000000
# const PI = 7244019458077122842 # TODO verify this
# const HALF_PI = 3622009729038561421 # TODO verify this

# TODO Try these
# how long to stop? v_f = v_0 + a * t
#   where v_f = 0, v = P / F
# how far til stops? v_f^2 = v_0 + 2 * a_x * dist
#   where v_f = 0, v = P / F
# a_x = mu * g
#   where mu = friction coefficient, g = gravity

# TODO refactor as @contract_interface
func get_new_location{range_check_ptr}(
        last_loc : Location,
        swing_power : felt,
        swing_force : felt,
        unit_vector : SwingDirection
    ) -> (new_loc : Location):

    alloc_locals

    # physics engine is for Earth-like physics on flat land
    # distance base unit is millimeters (mm)
    let gravity = -9800 # mm/s^2 to be integer

    # get angle of launch from ground
    # side view
    # z
    # |  o    
    # | /
    # |/T _ _ _ hypotenuse of x and y
    # tan(T) = opposite / adjacent
    let (adjacent_side) = sqrt((unit_vector.x * unit_vector.x) + (unit_vector.y * unit_vector.y))
    let (local launch_angle) = atan( unit_vector.z / adjacent_side ) # radians
    let (cos_launch_angle) = cos(launch_angle)
    let (sin_launch_angle) = sin(launch_angle)

    # get velocity magnitude
    # v = P / F
    let velocity_magnitude = swing_power / swing_force

    # get velocity z-component
    # v_z = v * sin(T)
    let init_velocity_z = velocity_magnitude * sin_launch_angle
    
    # get yaw angle
    # view from above where player aims down x-axis by default
    # y
    # |  o    
    # | /
    # |/a _ _ _ x
    # tan(a) = opposite / adjacent
    let (local yaw_angle) = atan( unit_vector.y / unit_vector.x ) # radians
    let (cos_yaw_angle) = cos(yaw_angle)
    let (sin_yaw_angle) = sin(yaw_angle)

    # get velocity x and y components
    # v_x = v_adj * cos(a)
    let v_adj = velocity_magnitude * cos_launch_angle
    let init_velocity_x = v_adj * cos_yaw_angle
    let init_velocity_y = v_adj * sin_yaw_angle

    # get time to reach ending position
    # z1 = v0_z * t * sin(theta) + 0.5 * a * t^2
    # z1 = 0 for flat land with no bounces
    let time_of_flight = 2 * init_velocity_z * sin_launch_angle / gravity

    # calculate ending position
    # x1 = x0 + v0_x * t
    let x = last_loc.x + init_velocity_x * time_of_flight
    let y = last_loc.y + init_velocity_y * time_of_flight

    return (Location(x=x, y=y, z=0))
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

func assert_inbound{range_check_ptr}(x : felt):
    assert_le(x, RANGE_CHECK_BOUND)
    assert_le(-RANGE_CHECK_BOUND, x)
    return ()
end

# Helper function to calculate Taylor series for sin
func recursive_sin{range_check_ptr} (
        x : felt, 
        i : felt, 
        acc : felt
    ) -> (res : felt):
    alloc_locals

    if i == -1:
        return (acc)
    end

    let (num) = mul(x, x)
    tempvar divisor = (2 * i + 2) * (2 * i + 3) * FP
    let (t) = div(num, divisor)
    let (t_acc) = mul(t, acc)
    let (next) = recursive_sin(x, i - 1, ONE - t_acc)
    return (next)
end

func sin{range_check_ptr}(
        x : felt
    ) -> (res : felt):
    alloc_locals

    let (_sign1) = sign(x) # extract sign
    let (abs1) = abs_value(x)
    let (_, x1) = unsigned_div_rem(abs1, 2 * PI)
    let (rem, x2) = unsigned_div_rem(x1, PI)
    local _sign2 = 1 - (2 * rem)
    let (acc) = recursive_sin(x2, 6, ONE)
    let (res2) = mul(x2, acc)
    local res = res2 * _sign1 * _sign2
    assert_inbound(res)
    return (res)
end

func cos{range_check_ptr}(
        x : felt
    ) -> (res : felt):
    tempvar shifted = HALF_PI - x
    let (res) = sin(shifted)
    return (res)
end

func atan{range_check_ptr}(
        x : felt
    ) -> (res : felt):
    alloc_locals

    # const sqrt3_3 = 1331279082078542925 # sqrt(3) / 3
    # const pi_6 = 1207336576346187140 # pi / 6
    # const p_7 = 1614090106449585766 # 0.7
    const sqrt3_3 = 333333333333 # sqrt(3) / 3
    const pi_6 = 523598333333333333333333 # pi / 6
    const p_7 = 7000000000000 # 0.7
    
    # Calculate on positive values and re-assign later
    let (_sign) = sign(x)
    let (abs_x) = abs_value(x)

    # Invert value when x > 1
    let (_invert) = is_le(ONE, abs_x)
    local x1a_num = abs_x * (1 - _invert) + _invert * ONE
    tempvar x1a_div = abs_x * _invert + ONE - ONE * _invert
    let (x1a) = div(x1a_num, x1a_div)

    # Account for lack of precision in polynomaial when x > 0.7
    let (_shift) = is_le(p_7, x1a)
    local b = sqrt3_3 * _shift + ONE - _shift * ONE
    local x1b_num = x1a - b
    let (x1b_div_2) = mul(x1a, b)
    tempvar x1b_div = ONE + x1b_div_2
    let (x1b) = div(x1b_num, x1b_div)
    local x1 = x1a * (1 - _shift) + x1b * _shift

    # 6.769e-8 maximum error
    const a1 = -156068910203
    const a2 = 2305874223272159097
    const a3 = -1025642721113314
    const a4 = -755722092556455027
    const a5 = -80090004380535356
    const a6 = 732863004158132014
    const a7 = -506263448524254433
    const a8 = 114871904819177193
    
    let (r8) = mul(a8, x1)
    let (r7) = mul(r8 + a7, x1)
    let (r6) = mul(r7 + a6, x1)
    let (r5) = mul(r6 + a5, x1)
    let (r4) = mul(r5 + a4, x1)
    let (r3) = mul(r4 + a3, x1)
    let (r2) = mul(r3 + a2, x1)
    tempvar z1 = r2 + a1

    # Adjust for sign change, inversion, and shift
    tempvar z2 = z1 + (pi_6 * _shift)
    tempvar z3 = (z2 - (HALF_PI * _invert)) * (1 - _invert * 2)
    local res = z3 * _sign
    assert_inbound(res)
    return (res)
end