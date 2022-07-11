%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_lt, assert_le, assert_not_zero
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.alloc import alloc
from src.structs import Location, SwingDirection, PlayerAttempt, AttemptInfo, PlayerSwing

##############
# STORAGE VARS
##############

@storage_var
func hole_location() -> (loc : Location):
end

@storage_var
func tee_location() -> (loc : Location):
end

@storage_var
func players(address : felt) -> (attempt_cnt : felt):
end

@storage_var
func attempts(player_attempt : PlayerAttempt) -> (info : AttemptInfo):
end

@storage_var
func swings(player_swing : PlayerSwing) -> (end_loc : Location):
end

@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    tee_location.write(Location(x=0, y=0, z=0))
    hole_location.write(Location(x=10, y=10, z=10))
    return ()
end

# @view
# func get_attempts{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
#         player_addr : felt
#     ) -> (
#         len : felt,
#         arr : AttemptInfo*):
#     alloc_locals

#     let (attempt_arr : AttemptInfo*) = alloc()

#     let (attempt_cnt) = players.read(address=player_addr)

#     let (arr_len, attempt_arr) = _recurse_get_attempts(len=attempt_cnt, index=0, 

#     let (attempt) = attempts.read(PlayerAttempt(addr=player_addr, attempt_id=attempt_id))

#     return (
# end

@external
func approach_tee{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    ) -> (attempt_cnt : felt):
    let (caller_addr) = get_caller_address()
    let (attempt_cnt) = players.read(address=caller_addr)
    players.write(caller_addr, attempt_cnt + 1)

    return (attempt_cnt + 1)
end

@external
func swing{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        attempt_id : felt,
        power : felt,
        direction : SwingDirection
    ) -> ():
    alloc_locals

    let (local caller_addr : felt) = get_caller_address()

    # Assert attempt id is valid
    let (attempt_cnt) = players.read(address=caller_addr)
    with_attr error_message("Attempt ID does not exist"):
        assert_le(0, attempt_id)
        assert_lt(attempt_id, attempt_cnt)
    end

    # Assert attempt is not finished
    let player_attempt_key = PlayerAttempt(addr=caller_addr, attempt_id=attempt_id)
    let (attempt) = attempts.read(player_attempt_key)
    let (last_loc) = _get_last_location(player_addr=caller_addr, attempt_id=attempt_id, swing_cnt=attempt.swing_cnt)
    let (hole_loc) = hole_location.read()
    with_attr error_message("This attempt has ended"):
        assert_not_zero(hole_loc.x - last_loc.x)
        assert_not_zero(hole_loc.y - last_loc.y)
        assert_not_zero(hole_loc.z - last_loc.z)
    end

    # Get new ball location
    # Possible pattern: call contract_interface to contract that contains physics engines
    let (new_loc) = _physics_engine(last_loc=last_loc)

    # Increase swing count
    attempts.write(
        player_attempt_key, 
        AttemptInfo(swing_cnt=attempt.swing_cnt + 1, status=attempt.status))

    # Store swing info
    swings.write(
        PlayerSwing(addr=caller_addr, attempt_id=attempt_id, swing_id=attempt.swing_cnt),
        Location(x=new_loc.x, y=new_loc.y, z=new_loc.z))

    return ()
end

func _get_last_location{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        player_addr : felt,
        attempt_id : felt,
        swing_cnt : felt
    ) -> (last_loc : Location):
    if swing_cnt == 0:
        let (last_loc) = tee_location.read()
        return (last_loc)
    else:
        let (last_loc) = swings.read(PlayerSwing(addr=player_addr, attempt_id=attempt_id, swing_id=swing_cnt - 1))
        return (last_loc)
    end
end

func _physics_engine{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        last_loc : Location
    ) -> (new_loc : Location):

    return (Location(x=last_loc.x, y=last_loc.y, z=last_loc.z))
end