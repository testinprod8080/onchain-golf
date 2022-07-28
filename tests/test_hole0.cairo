%lang starknet
from src.hole0 import (
    SwingDirection, 
    get_attempt_info, 
    get_hole_location, 
    approach_tee, 
    swing,
    _get_last_location
)
from src.structs import GolfClubEnum
from starkware.cairo.common.cairo_builtins import HashBuiltin

# TEST - approach_tee

@external
func test_add_attempts{syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*}():
    %{ stop_prank_callable = start_prank(123) %}
    approach_tee()
    let (attempt_cnt) = approach_tee()
    assert attempt_cnt = 2

    %{ stop_prank_callable() %}

    return ()
end

# TEST - swing

@external
func test_fail_attempt_id_dne{syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*}():
    %{ expect_revert(error_message="Attempt ID does not exist") %}
    swing(attempt_id=0, golf_club=GolfClubEnum.DRIVER, swing_force=10, direction=SwingDirection(x=1, y=1, z=0))

    %{ expect_revert(error_message="Attempt ID does not exist") %}
    swing(attempt_id=-1, golf_club=GolfClubEnum.DRIVER, swing_force=10, direction=SwingDirection(x=1, y=1, z=0))

    return ()
end

@external
func test_success_swing{syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*}():
    %{ stop_prank_callable = start_prank(123) %}
    approach_tee()

    let (new_loc) = swing(
        attempt_id=0, 
        golf_club=GolfClubEnum.DRIVER, 
        swing_force=20, 
        direction=SwingDirection(x=1, y=0, z=0))

    %{ stop_prank_callable() %}

    assert new_loc.x = 472411186696900
    assert new_loc.y = 0
    assert new_loc.z = 0

    return ()
end

@external
func test_success_in_the_hole{syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*}():
    alloc_locals

    %{ stop_prank_callable = start_prank(123) %}

    # act
    approach_tee()
    swing(
        attempt_id=0, 
        golf_club=GolfClubEnum.DRIVER, 
        swing_force=20, 
        direction=SwingDirection(x=1, y=0, z=0))
    swing(
        attempt_id=0, 
        golf_club=GolfClubEnum.DRIVER, 
        swing_force=20, 
        direction=SwingDirection(x=1, y=0, z=0))
    swing(
        attempt_id=0, 
        golf_club=GolfClubEnum.DRIVER, 
        swing_force=20, 
        direction=SwingDirection(x=1, y=0, z=0))

    %{ stop_prank_callable() %}

    # assert
    let (local swings_arr_len, local swings_arr) = get_attempt_info(attempt_id=0)
    let swings = &swings_arr[2]
    let (hole_loc) = get_hole_location()
    let swing_loc_sum = swings.x + swings.y + swings.z
    let hole_loc_sum = hole_loc.x + hole_loc.y + hole_loc.z
    assert swings.x = hole_loc.x
    assert swings.y = hole_loc.y
    assert swings.z = hole_loc.z

    return ()
end

# TEST - _get_last_location

@external
func test_success_last_loc_is_tee{syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*}():
    approach_tee()
    let (last_loc) = _get_last_location(player_addr=1234, attempt_id=0, swing_cnt=0)
    assert last_loc.x = 0
    assert last_loc.y = 0

    return ()
end