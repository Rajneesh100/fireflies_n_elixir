# solution idea

preparing all veriable as configurations 
1) tf  : tick frequency , no of times fireflies clocks tick per second so 1/tf is precision of system.
2) n   : input parameter, number of fireflies, we have to create n processes representing n fireflies.
3) pf  : print frequency, print all fireflies in a line pf/second and before printing the line clear the previous line so at a time only one line is visible on screen

  -- below time values are expected in seconds unit --
4) oft : off time for which fireflies will be in off start after which they will switch state and trun on
5) ont : on time for which fireflies will in on state after which they will switch state to turn off
6) dt  : delta time max skip wait time , which fireflies can skip like if fireflies needs to wait for w time to swich on and they get a on ping from left side then they can skip wait for min(w, dt) which will cause them to switch on little earlier


refrance conversion:

here i wanted to deal with standerd integer values for time 
so first of all calculating the precision from tf since clocks tick tf time per second 

Assumption : considering miliseond precision

```
unit time ut = 1000/tf  (smallest time quantum of system in ms)

now converted each time values oft, ont, dt  to ut refrance basically since ut is minimum measurable time so all time will measured in system will be mutiple of ut
so standerd oft, ont and dt will be as follows:

soft =  1000*oft / ut
sont =  1000*ont / ut
sdt  =  1000*dt / ut

```

for n fireflies we will spawn n process each process will have following things:
```
    id         : int value starting from 1 to n
    clock      : it's basically a counter which increments value by 1 after each ut interval
    state      : 0 or 1  (zero means off 1 means on)
    listen     : each process should be listning {:on_state, firefly_id} and should call modify_clock method after listing any message.
    broadcasts : when a firefly changes it's state to on state clock is reset to 0  so when t=0 and state =1 it boradcasts {:on_state, self.id} to all other fireflies.
        -- and same above parameter values --
    ut
    soft
    sont
    sdt 
    ut
    pid
```

intial condition :
```
intially all firefly is on off state 
and each firefly's clock is set to some random float value from [0 to 2*tf ]   (between 0 to 2 sec)

for flaot : 
clock: :rand.uniform(max_random_time),

for int :
trunc(:rand.uniform(max_random_time)),
```


each process have clock, in intial state values might contain decimal fractions but after first sync it will natural number always

update_state : 
```
when in off state and clock >= soft  it chnages the state to on and clock resets to 0 and when it changes state at t=0 it broadcasts it's id {:on_state, self.id} to every one.

when in on state  and clock >= sont  it changes the state to off state and clock resets to 0
```

skip wait time logic : 
```
if state  == 0  # off state
  when recieves any broadcasts {:on_state , firefly_id}  if left_neighbour then add +sdt in clock 
if state  == 1
  do nothing
```

clock_manager : 
```
  just add one to clock
```


broadcast:
```
  use ets memory to get all fireflies pid and ping them
```

run_firefly:
```
created two flows :
  listner : 
    actively keeps listning and checks for skip wait time condition be be met and increase it's clock by +sdt. we collect all pids of each listner that were created when fireflies were created we will used this pids to send pings on state chnage

  manager_clock :
    after regular intervals increment the clock by 1 unit

on each clock ticks & skip_wait event state chnage logic is checked and state is updated and clocks are set to zero.
if new state is on state
just after state change execution at clock = 0  broadcasts will be done to all other fireflies and listner will cature and check if it's his left neighbour or not and modify clock time accordingly

```













---------------------------------------------------------------------------------------
EDGE cases : 
so let's say unit time is 100ms so if nothing happens then after 100ms tick will triiger and increment the counter 
well and good

now consider this :
let's say value of clock just changes to 2 and from it's left neighbour a ping came after 2 ms of so it adds 
let's say 3 unit of time so now it's at 5 unit but since he already spend 2 ms in current wait so he needed to wait 98 ms to complete the normal cycle but now he will go to next cycle which is not in perfect 100ms slot so that 2ms wait wait was not counted properly.
so implimented global shared clock for each firefly using ets storage and clock_update and listen was independently update clocks without lossing any time, to avoid race condition during clockupdate at new click by clock_manager and listner process, i have simply added 1ms wait time on listner which avoid race issue with normal clock_update, could have done somthing like mutex & semaphore to avoid this critical section problem but wanted to keep it simple and the current heck will have no consequences in terms of correctness.

```
normal :
200ms                                          300ms   400ms   500ms   600ms
tick                                           tick    tick    tick    tick

when ping :
200ms   202ms (ping)     502ms  -98ms later->  600ms  700ms ......
tick    jump             tick                  tick    tick
```

sapreated the clock_update and skip_wait logic as a indepenent flow and clock_update will get precedence 
to maintain time slip by different clocks now all of the regular clocks will tick at the same time

implimented shared memory space for state and clock access using ets.
-----------------------------------------------------------------------------------------------------------------------------

# how i have used llms
first of all i have used it llms for understanding the use case of elixir like why it was created in first place, and then thaught about solution and from my background with backend development i thaught it like for each firefly what thing i needs there were :
1) a internal counter
2) a listner (something like message queues but on inter process level)
3) a broadcaster (publishes to all the fireflies in the system through some thread id)
4) clock & state manupulation logic 

so i explored about how start learning about implimenting listner and braodcaster logic i found one yt video with help of gpt in which i got to know about inter process communication it was in context parallel cart management service where through elixir we can manage thousand of concurrent processes (link: https://www.youtube.com/watch?v=J2F9z_0XFj4) i watched few other short videos around it, to get together with syntax i went to gpt like instaed of send messages directly manually through elixir intractive session how to do it in code level. few times i used gpt to understand the sytax meaning like what does this one_on_one  ```Supervisor.start_link([], strategy: :one_for_one)``` means here (start the crashed process only , let it fail alone concept instead of affecting entire syatem, contain the failure).
so yeah i used llms for syntax understanding and exploring logic behind certain things.

-------------------------------------------------------------------------------------------------------------------------------

 
to execute the fireflies

run :
```

mix compile 

mix run --no-halt

```

Intractive session 
```
iex -S mix
```
after starting the session
to start the simulation run 
```
#store the pid of parent process
pid = FirefliesFestival.main()

```