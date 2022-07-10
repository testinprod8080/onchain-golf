%lang starknet
from src.hole0 import ShotDirection, approach_tee, swing, _assert_valid_attempt
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
func test_swing{syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*}():
    %{ stop_prank_callable = start_prank(123) %}
    approach_tee()
    swing(attempt_id=0, power=10, direction=ShotDirection(x=1, y=1, z=0))

    %{ stop_prank_callable() %}

    return ()
end

# TEST - _assert_valid_attempt

@external
func test_attempt_id_dne{syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*}():
    %{ expect_revert(error_message="Attempt ID does not exist") %}
    _assert_valid_attempt(0, 10)

    return ()
end
