%lang starknet
from src.hole0 import SwingDirection, approach_tee, swing, _get_last_location
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
    swing(attempt_id=0, power=10, direction=SwingDirection(x=1, y=1, z=0))

    %{ expect_revert(error_message="Attempt ID does not exist") %}
    swing(attempt_id=-1, power=10, direction=SwingDirection(x=1, y=1, z=0))

    return ()
end

@external
func test_success_swing{syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*}():
    %{ stop_prank_callable = start_prank(123) %}
    approach_tee()
    swing(attempt_id=0, power=10, direction=SwingDirection(x=1, y=1, z=0))

    %{ stop_prank_callable() %}

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