%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_lt, assert_le
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.alloc import alloc

###########
# CONSTANTS
###########

#######
# ENUMS
#######

struct GolfClubEnum:
    member ONECLUBTORULETHEMALL : felt
    member DRIVER : felt
    member WOOD : felt
    member IRON : felt
    member WEDGE : felt
    member PUTTER : felt
end

struct AttemptStatusEnum:
    member PLAYING : felt
    member FINISHED : felt
end

#########
# STRUCTS
#########

struct Location:
    member x : felt
    member y : felt
    member z : felt
end

struct ShotDirection:
    member x : felt
    member y : felt
    member z : felt
end

struct PlayerAttempt:
    member addr : felt
    member attempt_id : felt
end

struct AttemptInfo:
    member shot_cnt : felt
    member status : felt
end

struct PlayerShot:
    member addr : felt
    member attempt_id : felt
    member shot_id : felt
end

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
func shots(player_shot : PlayerShot) -> (end_loc : Location):
end

#############
# CONSTRUCTOR
#############

@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    tee_location.write(Location(x=0, y=0, z=0))
    return ()
end

#######
# VIEWS
#######

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

###########
# EXTERNALS
###########

@external
func approach_tee{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (attempt_cnt : felt):
    let (caller_addr) = get_caller_address()
    let (attempt_cnt) = players.read(address=caller_addr)
    players.write(caller_addr, attempt_cnt + 1)

    return (attempt_cnt + 1)
end

@external
func swing{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        attempt_id : felt,
        power : felt,
        direction : ShotDirection
    ):
    alloc_locals

    let (local caller_addr : felt) = get_caller_address()
    _assert_valid_attempt(player_addr=caller_addr, attempt_id=attempt_id)

    let player_attempt_key = PlayerAttempt(addr=caller_addr, attempt_id=attempt_id)
    let (attempt) = attempts.read(player_attempt_key)

    # Get last ball location
    if attempt.shot_cnt == 0:
        let (last_loc) = tee_location.read()
    else:
        let (last_loc) = shots.read(PlayerShot(addr=caller_addr, attempt_id=attempt_id, shot_id=attempt.shot_cnt - 1))
    end

    # Get new ball location
    local new_loc : Location* = new Location(x=last_loc.x + 1, y=last_loc.y + 1, z=0)

    # Increase shot count
    attempts.write(
        player_attempt_key, 
        AttemptInfo(shot_cnt=attempt.shot_cnt + 1, status=attempt.status))

    # Store shot info
    shots.write(
        PlayerShot(addr=caller_addr, attempt_id=attempt_id, shot_id=attempt.shot_cnt),
        Location(x=1, y=1, z=1))

    return ()
end

#############
# VALIDATIONS
#############

func _assert_valid_attempt{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        player_addr : felt,
        attempt_id : felt
    ):
    let (attempt_cnt) = players.read(address=player_addr)
    with_attr error_message("Attempt ID does not exist"):
        assert_le(0, attempt_id)
        assert_lt(attempt_id, attempt_cnt)
    end

    let (attempt) = attempts.read(PlayerAttempt(addr=player_addr, attempt_id=attempt_id))
    with_attr error_message("This attempt has ended"):
        assert attempt.status = AttemptStatusEnum.PLAYING
    end

    return ()
end

###########
# INTERNALS
###########