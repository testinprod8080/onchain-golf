%lang starknet

struct GolfClubEnum:
    member ONECLUBTORULETHEMALL : felt
    member DRIVER : felt
    member WOOD : felt
    member IRON : felt
    member WEDGE : felt
    member PUTTER : felt
end

struct Location:
    member x : felt
    member y : felt
    member z : felt
end

struct SwingDirection:
    member x : felt
    member y : felt
    member z : felt
end

struct PlayerAttempt:
    member addr : felt
    member attempt_id : felt
end

struct AttemptInfo:
    member swing_cnt : felt
    member status : felt
end

struct PlayerSwing:
    member addr : felt
    member attempt_id : felt
    member swing_id : felt
end