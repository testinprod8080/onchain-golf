# Onchain Golf

A golf game built for Starknet. Get the ball in the hole.

## Actions

- `approach_tee()` to play a hole from the starting tee and log a new attempt
- `swing()` with inputs below to move the ball towards the hole
  - `attempt_id` - designates to which attempt to apply this swing
  - `swing_power` - factors into equation to calculate new ball location
  - `direction` - vector (x, y, z) of ball trajectory

## End Game Events

Once the ball location is in the hole, no further swings can be added to the attempt.