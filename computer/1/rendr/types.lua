local types = {}

types.GEAR_STATE = {
    UP = 1,
    LOWERING = 2,
    RASING = 3,
    DOWN = 4
}

types.ENGN_F_STATE = {
    FIRE = 1,
    EXT = 2,
    NORM = 3
}
types.PRIORITY = {
    BASIC          = "p0",
    ALERT          = "p1",
    CAUTION        = "p2",
    URGENT_CAUTION = "p3",
    WARNING        = "p4"

}

return types