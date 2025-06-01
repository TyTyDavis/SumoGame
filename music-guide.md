# Guide to the various music building blocks

## General

I started at sound effect 50 to leave plenty of room for you to do sfx for the game on 1-49. To make it as flexible as possible I tried to limit my use of "patterns" so you could more easily turn on and off different layers of sounds via scripts. Only the melody instruments use patterns to facilitate for longer musical phrases.
There are "slow", "medium", and "fast" paced drum or melodic patterns. If you need to change the speed of the music alwayse ensure that the speeds are all divisible by half. The speed for slow divided in half is medium. And medium divided in half is fast. For example, I set the default to this:
- Slow: 40
- Medium: 20
- Fast: 10


## Taiko Drums

The following **sound effects** are drums

### sfx 50

50 is the "base" of all of the music. It's a steady low taiko drum _don_ rhythm. Like a heartbeat or a steady walk. This can be used as the base and always playing. (The more it's played the stronger the suspense/jarring effect would be if you turned it off during a pivital moment.)

_This is a_ Slow  _rhythm._

### sfx 51

51 is an off-beat accent using the taiko _ka_, or hitting the rim of the drum for a more piercing higher pitched sound. It can be used over top of 50 to "quicken" the music.

_This is a_ Medium _rhythm._

### sfx 52

52 is just a steady, yet quick _ka_ rhythm. Similar to 51, it can be used to quicken the music and heighten urgency. 

_This is a_ Medium _rhythm._

### sfx 53

53 quickens the music even more. It deviates from the rhytmic norm established by the previous sfxs using both _don_ and _ka_, so it can heighten the excitment. It is designed to be compatible with the previous rhythms so it can be layered over them without making it weird. But it may get a little noisy with too many layers.

_This is a_ Medium _rhythm._

### sfx 54

54 is the even faster version of sfx 54. It's faster drumming using various _ka_ which deviates from the norm of 50–52. It can be added in to even further heighten excitement.

_This is a_ Fast _rhythm._

### sfx 55

55 is a low _don_ drum roll growing in volume for building to a climax.

_This is a_ Fast _rhythm._

### sfx 56

56 is a high _ka_ drum roll growing in volume for building to a climax.

_This is a_ Fast _rhythm._

## Melodies

The following **patterns** or **sound effects** are melodic instruments

### pattern 51 + 52

Pattern 51 + 52 is my first whack at the melodic side of things. It's on the slower side and designed to be played over any of our drum rhythms. It's just comprised of sfx 57 and 58 to keep it short. 

_Note: I curently included drum rhythms 50 and 51 to give you an idea how the pieces can fit together. In the actual game we would turn off the drum tracks from the pattern so you have more control over what's playing at any given time._
