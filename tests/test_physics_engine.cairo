%lang starknet
from src.physics_engine import _get_launch_angle
from src.structs import (
    SwingDirection,
    GolfClubEnum
)

# TEST - _get_launch_angle

@external
func test_success_get_launch_angle{range_check_ptr}():
    let MAX_NUM = 2 ** 251 + 17 * 2 ** 192
    tempvar unit_vector : SwingDirection = SwingDirection(x=4, y=0, z=2)
    let (angle) = _get_launch_angle(unit_vector)

    %{ 
        print(str(ids.angle))
        print(str(ids.MAX_NUM))
        print("Angle: " + str(ids.angle/ids.MAX_NUM) + " radians")
    %}

    # assert angle = MAX_NUM / 2

    return ()
end