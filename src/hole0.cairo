%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_lt, assert_le, assert_not_zero
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.alloc import alloc
from src.structs import (
    Location, 
    SwingDirection, 
    PlayerAttempt, 
    PlayerSwing, 
    GolfClubEnum
)
from src.physics_engine import get_new_location

###########
# CONSTANTS
###########

const TEE_LOCATION_X = 0
const TEE_LOCATION_Y = 0
const TEE_LOCATION_Z = 0

##############
# STORAGE VARS
##############

@storage_var
func hole_location() -> (loc : Location):
end

@storage_var
func attempts(address : felt) -> (attempt_cnt : felt):
end

@storage_var
func swings(player_attempt : PlayerAttempt) -> (swing_cnt : felt):
end

@storage_var
func ball_locations(player_swing : PlayerSwing) -> (end_loc : Location):
end

#############
# CONSTRUCTOR
#############

@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    hole_location.write(Location(x=1417233560090700, y=0, z=0))
    return ()
end

#######
# VIEWS
#######

@view
func get_hole_location{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    ) -> (hole_loc : Location):
    let (hole_loc) = hole_location.read()
    
    return (hole_loc)
end

@view
func get_attempt_info{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        attempt_id : felt
    ) -> (swings_arr_len : felt, swings_arr : Location*):
    alloc_locals

    let (caller_addr) = get_caller_address()
    let (swing_cnt) = swings.read(PlayerAttempt(addr=caller_addr, attempt_id=attempt_id))

    let (local swings_arr : Location*) = alloc()

    _recurse_get_swing_info(player_addr=caller_addr, attempt_id=attempt_id, swing_cnt=swing_cnt, swings_len=0, swings_arr=swings_arr)

    return (swings_arr_len=swing_cnt, swings_arr=swings_arr)
end

###########
# EXTERNALS
###########

# adds new attempt for caller
@external
func approach_tee{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    ) -> (attempt_cnt : felt):
    let (caller_addr) = get_caller_address()
    let (attempt_cnt) = attempts.read(address=caller_addr)
    attempts.write(caller_addr, attempt_cnt + 1)

    return (attempt_cnt + 1)
end

# computes new location of ball 
@external
func swing{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        attempt_id : felt,
        golf_club : felt,
        swing_force : felt,
        direction : SwingDirection
    ) -> (new_loc : Location):
    alloc_locals

    # TODO assert valid golf club
    # TODO assert swing_force is between 0 and TBD max number

    let (local caller_addr : felt) = get_caller_address()

    _assert_attempt_id_is_valid(player_addr=caller_addr, attempt_id=attempt_id)

    # get ball's last location
    let player_attempt_key = PlayerAttempt(addr=caller_addr, attempt_id=attempt_id)
    let (curr_swing_cnt) = swings.read(player_attempt_key)
    let (last_loc) = _get_last_location(player_addr=caller_addr, attempt_id=attempt_id, swing_cnt=curr_swing_cnt)
    
    _assert_attempt_not_finished(last_loc=last_loc)

    let (swing_power) = _get_swing_power(golf_club)
    let (new_loc) = get_new_location(last_loc=last_loc, swing_power=swing_power, swing_force=swing_force, unit_vector=direction)

    # increase swing count
    swings.write(player_attempt_key, curr_swing_cnt + 1)

    # store new location
    ball_locations.write(
        PlayerSwing(addr=caller_addr, attempt_id=attempt_id, swing_id=curr_swing_cnt),
        Location(x=new_loc.x, y=new_loc.y, z=new_loc.z))

    return (new_loc)
end

#############
# VALIDATIONS
#############

func _assert_attempt_id_is_valid{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        player_addr : felt,
        attempt_id : felt
    ) -> ():
    let (attempt_cnt) = attempts.read(address=player_addr)
    with_attr error_message("Attempt ID does not exist"):
        assert_le(0, attempt_id)
        assert_lt(attempt_id, attempt_cnt)
    end

    return ()
end

func _assert_attempt_not_finished{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        last_loc : Location
    ) -> ():
    let (hole_loc) = hole_location.read()
    # TODO add tolerance of .05m for hole radius
    with_attr error_message("This attempt has ended"):
        assert_not_zero(hole_loc.x + hole_loc.y + hole_loc.z - last_loc.x - last_loc.y - last_loc.z)
    end

    return ()
end

###########
# INTERNALS
###########

func _recurse_get_swing_info{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        player_addr : felt,
        attempt_id : felt,
        swing_cnt : felt,
        swings_len : felt,
        swings_arr : Location*
    ) -> ():
    if swings_len == swing_cnt:
        return ()
    end

    let (ball_loc) = ball_locations.read(PlayerSwing(addr=player_addr, attempt_id=attempt_id, swing_id=swings_len))
    assert swings_arr[swings_len] = ball_loc

    _recurse_get_swing_info(player_addr=player_addr, attempt_id=attempt_id, swing_cnt=swing_cnt, swings_len=swings_len + 1, swings_arr=swings_arr)

    return ()
end

func _get_last_location{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        player_addr : felt,
        attempt_id : felt,
        swing_cnt : felt
    ) -> (last_loc : Location):
    if swing_cnt == 0:
        return (Location(x=TEE_LOCATION_X, y=TEE_LOCATION_Y, z=TEE_LOCATION_Z))
    else:
        let (last_loc) = ball_locations.read(PlayerSwing(addr=player_addr, attempt_id=attempt_id, swing_id=swing_cnt - 1))
        return (last_loc)
    end
end

# TODO refactor to obtain from golf club NFTs
func _get_swing_power{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        golf_club : felt
    ) -> (swing_power : felt):

    if golf_club == GolfClubEnum.DRIVER:
        return (1000)
    end

    if golf_club == GolfClubEnum.WOOD:
        return (500)
    end

    if golf_club == GolfClubEnum.IRON:
        return (100)
    end

    if golf_club == GolfClubEnum.WEDGE:
        return (10)
    end

    if golf_club == GolfClubEnum.PUTTER:
        return (1)
    end

    return (0)
end
