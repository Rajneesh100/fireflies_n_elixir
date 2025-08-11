
---

# solution idea

preparing all variables as configurations

1. tf  : tick frequency, number of times fireflies’ clocks tick per second so 1/tf is precision of system.
2. n   : input parameter, number of fireflies, we have to create n processes representing n fireflies.
3. pf  : print frequency, print all fireflies in a line pf/second and before printing the line clear the previous line so at a time only one line is visible on screen

      -- below time values are expected in seconds unit --

4. oft : off time for which fireflies will be in off state after which they will switch state and turn on
5. ont : on time for which fireflies will be in on state after which they will switch state to turn off
6. dt  : delta time max skip wait time, which fireflies can skip, like if a firefly needs to wait for w time to switch on and they get an on ping from the left side, then they can skip wait for min(w, dt) which will cause them to switch on a little earlier

reference conversion:

here I wanted to deal with standard integer values for time
so first of all calculating the precision from tf since clocks tick tf times per second

Assumption : considering millisecond precision

```
unit time ut = 1000/tf  (smallest time quantum of system in ms)
```

now converted each time value oft, ont, dt to ut reference, basically since ut is the minimum measurable time, all time measured in the system will be multiple of ut
so standard oft, ont and dt will be as follows:

```
soft =  1000*oft / ut
sont =  1000*ont / ut
sdt  =  1000*dt / ut
```

for n fireflies we will spawn n processes, each process will have the following things:

```
    id         : int value starting from 1 to n
    clock      : it's basically a counter which increments value by 1 after each ut interval
    state      : 0 or 1  (zero means off, 1 means on)
    listen     : each firefly should be listening {:on_state, firefly_id} and should modify the clock time after listening to any message.
    broadcasts : when a firefly changes its state to on, its clock is reset to 0 so at t=0 and state = 1 it broadcasts {:on_state, self.id} to all other fireflies.
        -- and same above parameter values --
    ut
    soft
    sont
    sdt 
    ut
    pid
```

initial condition :

```
initially all fireflies are in off state 
and each firefly's clock is set to some random float value from [0 to 2*tf ]   (between 0 to 2 sec)

for float : 
clock: :rand.uniform(max_random_time),

for int :
trunc(:rand.uniform(max_random_time)),
```

each process has a clock, in the initial state values might contain decimal fractions but after first sync it will be a natural number always

update\_state :

```
when in off state and clock >= soft, it changes the state to on and clock resets to 0 and when it changes state at t=0 it broadcasts its id {:on_state, self.id} to everyone.

when in on state and clock >= sont, it changes the state to off and clock resets to 0
```

skip wait time logic :

```
if state  == 0  # off state
  when receives any broadcasts {:on_state , firefly_id}  if left_neighbour then add +sdt in clock 
if state  == 1
  do nothing
```

clock\_manager :

```
  just add one to clock
```

broadcast:

```
  use ets memory to get all fireflies' pids and ping them
```

run\_firefly:

```
created two flows :
  listener : 
    actively keeps listening and checks for skip wait time condition to be met and increases its clock by +sdt. we collect all pids of each listener that were created when fireflies were created and use these pids to send pings on state change

  manager_clock :
    after regular intervals increment the clock by 1 unit

on each clock tick & skip_wait event, state change logic is checked and state is updated and clocks are set to zero.
if new state is on state:
just after state change execution at clock = 0, broadcasts will be done to all other fireflies and listener will capture and check if it's their left neighbour or not and modify clock time accordingly
```

---

**EDGE cases** :
so let's say unit time is 100ms so if nothing happens then after 100ms tick will trigger and increment the counter, well and good.

now consider this:
let's say value of clock just changes to 2 and from its left neighbour a ping came after 2 ms so it adds, let's say, 3 units of time so now it's at 5 units but since it already spent 2 ms in the current wait, it needed to wait 98 ms to complete the normal cycle but now it will go to the next cycle which is not in a perfect 100ms slot so that 2ms wait was not counted properly.
so implemented global shared clock for each firefly using ets storage and clock\_update and listener were independently updating clocks without losing any time.
to avoid race condition during clock\_update at new tick by clock\_manager and listener process, I have simply added 1ms wait time on listener which avoids race issues with normal clock\_update. Could have done something like mutex & semaphore to avoid this critical section problem but wanted to keep it simple and the current hack will have no consequences in terms of correctness.

```
normal :
200ms                                          300ms   400ms   500ms   600ms
tick                                           tick    tick    tick    tick

when ping :
200ms   202ms (ping)     502ms  -98ms later->  600ms  700ms ......
tick    jump             tick                  tick    tick
```

separated the clock\_update and skip\_wait logic as an independent flow and clock\_update will get precedence.
to maintain time slip by different clocks, now all of the regular clocks will tick at the same time.

implemented shared memory space for state and clock access using ets.

---

# how I have used LLMs

first of all I have used LLMs for understanding the use case of Elixir, like why it was created in the first place, and then thought about a solution and from my background with backend development I thought like for each firefly what things I need:

1. an internal counter
2. a listener (something like message queues but on inter-process level)
3. a broadcaster (publishes to all the fireflies in the system through some thread id)
4. clock & state manipulation logic

now i had this minimal requiremnet that i needed to figur out, mostly the inter process message passing part.
so I explored about implementing listener and broadcaster logic. I found one YouTube video with help of GPT in which I got to know about inter-process communication, it was in context of a parallel cart management service which felt similar to what i needed. the video: ([link](https://www.youtube.com/watch?v=J2F9z_0XFj4)). I watched a few other short videos around it, to get together with syntax. I went to GPT for like instead of sending messages directly manually through Elixir interactive session, how to do it in code level. A few times I used GPT to understand the syntax meaning like what does this one\_on\_one here

```elixir
Supervisor.start_link([], strategy: :one_for_one)
```
mean here (start the crashed process only, let it fail alone concept instead of affecting the entire system, contain the failure).
So yeah, I used LLMs for syntax understanding and finding key resources to learn & impliment my ideas in simplest way possible.

---

to execute the fireflies:

run :

```
mix compile 
mix run --no-halt
```

Interactive session:

```
iex -S mix
```

after starting the session, to start the simulation run:

```
# store the pid of parent process
pid = FirefliesFestival.main()
```
---


to run code in git code space
```
sudo apt-get update
sudo apt-get install -y curl wget gnupg

sudo apt-get install -y elixir erlang

elixir -v

```