# aster_ml.engine.memory (v0)
#
# Placeholder for buffer lifetime + memory planning.
#
# v0 note: scheduling currently uses an interpreter-style execution and does not
# yet allocate/plan device buffers. This file exists to reserve the API surface.

struct MemPlan
    var dummy is i32

def memplan_build(out is mut ref MemPlan) returns i32
    (*out).dummy = 0
    return 0

def memplan_free(out is mut ref MemPlan) returns ()
    (*out).dummy = 0
    return
