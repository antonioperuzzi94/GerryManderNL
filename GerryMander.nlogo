globals[state-maj change-mind-prob polarization pop-vote rep-house-seats leader signal election house-win-list reversal strong-com swing-com]
extensions [ nw ]

breed [ dots dot ]
breed [ users user ]
breed [ citizens citizen ]

citizens-own[distr vote community-type pol-community stg-community ]

to setup

  clear-all
  ; Create lattice with dots at each patch

  set  house-win-list list 0 0 ;initialize list recording majority in the number of representatives

  ask patches [   ;initialize patches

    set pcolor 1
    sprout-dots 1 [

      set color 0
      set size 0.2
      set heading 0
      set shape "circle"
    ]
  ]


  ifelse city-country[ ;initialize districts according to city-country setup or random setup
    draw-starting-districts-city] [draw-starting-districts-random]

  election-result       ;initali election at tick 0
  count-strong-swing    ;initial count of strong and competitive (swing) districts
  reset-ticks
end


to draw-starting-districts-random ;procedure to implement the random setup

  create-citizens 63 [

    ifelse any? patches with [not any? citizens-here][ move-to one-of patches with [not any? citizens-here]][]
    set shape "person"
    set size 0.5
    ifelse random-float 1 > dem-probability [set color 15
      set vote 1

    ] [set color 95
    set vote -1
    ]


  ]

  ask citizens[

  create-links-with citizens-on neighbors4 with [pycor = [ycor] of myself]

  ]

  nw:set-context citizens links


let communities nw:louvain-communities
let colors sublist base-colors 0 (length communities) (foreach communities colors [ [community col] ->
  ask community [ set distr col ]
])

end



to draw-starting-districts-city ;procedure to implement the city-country setup

  create-citizens 63 [

    ifelse any? patches with [not any? citizens-here][ move-to one-of patches with [not any? citizens-here]][]
    set shape "person"
    set size 0.5

  ]

  ask citizens[

    ifelse random-float 1 > (1 - (ycor / 12)) ^ 2 ;<= change here if you want to model differently city-country
    [set color 15
      set vote 1

    ] [set color 95
    set vote -1
    ]



  create-links-with citizens-on neighbors4 with [pycor = [ycor] of myself]

  ]

  nw:set-context citizens links


let communities nw:louvain-communities
let colors sublist base-colors 0 (length communities) (foreach communities colors [ [community col] ->
  ask community [ set distr col ]
])

end


to go ;GO procedure

ask citizens [ set community-type "none" ]

changing-idea ;let citizens change their opinion

  ifelse (ticks + 2 + 1) / 2 = int ((ticks + 2 + 1) / 2) [ ;; hold elections every two years

    election-result

    set election 1
  ][set election 0]

if gerrymendering-on [
 ifelse (ticks + 10 + 1) / 10 = int ((ticks + 10 + 1) / 10) [  ;; gerrymandaring every ten years

    set signal 1
    gerry-mandaring][set signal 0]

  ]


  count-strong-swing ;count the number of strong and competitive districts
  tick

  if ticks = 99 [
    reversal-count] ; count the number of reversals in the time series % house seats

  if ticks >= 100 [ ;stop the model in the 100th year
  stop]
end


to election-result ;; compute election results
let college-vote 0
let communities nw:louvain-communities

  foreach communities[
    [community] ->

    let vote-community 0
    let monitor [vote] of citizens-on  community
    ifelse sum [vote] of citizens-on  community >= 0 [set vote-community 1] [set vote-community -1]
    set college-vote sentence college-vote vote-community


  ]


    polarizing-count ; compute the standard deviation across districts

set rep-house-seats (length filter [ i -> i = 1 ] college-vote)

set state-maj rep-house-seats / 9 ;

let house-win 0
  ifelse state-maj > 0.5 [set house-win 1][set house-win -1]

set house-win-list lput house-win house-win-list


set pop-vote   ( sum [vote] of citizens with [vote = 1]) / 63 ;; count popular vote

ifelse pop-vote > 0.5 [set leader "Republican candidate" ][set leader "Democrat candidate"]

end



to gerry-mandaring ;gerrymandering procedure



ifelse pop-vote > 0.5 [ ;if incumbent Republican -> GerryM in favor of Rep and viceversa

 if random-float 1 >= 1 - success-rate[ ;possibility of failing to gerrymander ( 0% by default)

      ifelse packing-or-craking[

       repeat n-times[
       republican-count-2   ;packing classification of citizens
        republican-tweak-2  ;packing swap of citizens
        ask citizens [set community-type 0 ]]


      ][


   repeat n-times[
  republican-count-1 ;cracking classification of citizens
  republican-tweak-1 ;cacking swap of citizens
          ask citizens [set community-type 0 ]]


      ]


  ]]

    [if random-float 1 >= 1 - success-rate[ ;if incumbent Dem -> GerryM in favor of Dem


      ifelse packing-or-craking[

     repeat n-times[
    democrat-count-2 ;packing classification of citizens
    democrat-tweak-2 ;packing swap of citizens
          ask citizens [set community-type 0 ]]


      ][

    repeat n-times[
    democrat-count-1 ;cracking classification of citizens
    democrat-tweak-1 ;cacking swap of citizens
          ask citizens [set community-type 0 ]]

      ]

  ]]

end


to republican-count-1 ;Cracking Classificationin favor of Rep

 let communities nw:louvain-communities

 foreach communities[
    [community] ->


    let strength-community sum [vote] of citizens-on community

      ifelse strength-community >= 3 [ask community[set community-type "strong_adv"]] []                                   ;<= Change here the classification procedure
      ifelse (strength-community = -1) or  (strength-community = -3) [ask community[set community-type "interesting"]] []  ;<= Change here the classification procedure
  ]


end

to republican-tweak-1 ; Cracking Swap favor of Rep
    if (any? citizens with [(community-type = "strong_adv")]) and (any? citizens with [(community-type = "interesting")])[
    ask one-of citizens with [(community-type = "strong_adv") and (vote = 1)] [set vote -1
    set color 95 ]
    ask one-of citizens with [(community-type = "interesting") and (vote = -1)] [set vote 1
        set color 15 ]
    ]


end


to republican-count-2 ;Packing Classificationin favor of Rep

 let communities nw:louvain-communities

 foreach communities[
    [community] ->


    let strength-community sum [vote] of citizens-on community

      ifelse (strength-community = -3) or (strength-community = -5) [ask community[set community-type "strong_dis"]] []  ;<= Change here the classification procedure
      ifelse (strength-community = -1) or (strength-community = 1) [ask community[set community-type "interesting"]] []  ;<= Change here the classification procedure
  ]


end




to republican-tweak-2  ;Packing Swap in favor of Rep

    if (any? citizens with [(community-type = "strong_dis")]) and (any? citizens with [(community-type = "interesting")])[
    ask one-of citizens with [(community-type = "strong_dis") and (vote = 1)] [set vote -1
    set color 95 ]

    ask one-of citizens with [(community-type = "interesting") and (vote = -1)] [set vote 1
        set color 15 ]
    ]


end







to democrat-count-1 ;Cracking Classification in favor of Dem

  let communities nw:louvain-communities


   foreach communities[
    [community] ->


    let strength-community sum [vote] of citizens-on community

      ifelse strength-community <= -3 [ask community[set community-type "strong_adv"]] []                                  ;<= Change here the classification procedure
      ifelse  (strength-community = 1) or  (strength-community = 3)  [ask community[set community-type "interesting"]] []  ;<= Change here the classification procedure
  ]

end

to democrat-tweak-1 ;Cracking Swap in favor of Dem

  if (any? citizens with [(community-type = "strong_adv")]) and (any? citizens with [(community-type = "interesting")])[


    ask one-of citizens with [(community-type = "strong_adv") and (vote = -1)] [set vote 1
    set color 15 ]

    ask one-of citizens with [(community-type = "interesting") and (vote = 1)] [set vote -1
        set color 95 ]
    ]

end


to democrat-count-2   ;Packing Classification in favor of Dem

  let communities nw:louvain-communities


   foreach communities[
    [community] ->


    let strength-community sum [vote] of citizens-on community

      ifelse (strength-community = 3) or (strength-community = 5) [ask community[set community-type "strong_dis"]] []
      ifelse (strength-community = 1) or (strength-community = -1) [ask community[set community-type "interesting"]] []
  ]



end


to democrat-tweak-2  ;Packing Swap in favor of Dem

  if (any? citizens with [(community-type = "strong_dis")]) and (any? citizens with [(community-type = "interesting")])[


    ask one-of citizens with [(community-type = "strong_dis") and (vote = -1)] [set vote 1
    set color 15 ]

    ask one-of citizens with [(community-type = "interesting") and (vote = 1)] [set vote -1
        set color 95 ]
    ]

end


to changing-idea ;; Changing idea procedure

ask citizens [


  if random-float 1 <= probability-mind-change [

      set vote (-1) * vote

      ifelse vote = 1 [set color 15] [set color 95]

    ]

  ]


end


to polarizing-count ;STD computation across districts

let communities nw:louvain-communities
  foreach communities[
    [community] ->
    ask community [
      set pol-community  ( sum [vote] of citizens-on community with [ vote = 1]) / 7   ]]

 set polarization standard-deviation [pol-community] of citizens

end




to reversal-count ; Procedure to count the number of reversals in the representtives majority sime series
set house-win-list but-first house-win-list
set house-win-list but-first house-win-list ;; remove the two initial zeros

let house-win-list-lag-one  but-last house-win-list ; cretae the lag one list
set house-win-list but-first house-win-list ;uniform the number of elements in house-win-list


let difference  (map + (house-win-list) (house-win-list-lag-one ))


set reversal length filter [i -> i = 0] difference

end


to count-strong-swing ;procedure to count the number of stron and competitive districts

 let communities nw:louvain-communities

 foreach communities[
    [community] ->

  ask community [
      set stg-community sum [vote] of citizens-on community]


  ]

  set strong-com (count citizens with [(stg-community = -7) or (stg-community = 7) or (stg-community = -5) or (stg-community = 5)  or (stg-community = -3) or (stg-community = 3)  ]) / 7

  set swing-com (count citizens with [(stg-community = -1) or (stg-community = 1) ]) / 7

end
@#$#@#$#@
GRAPHICS-WINDOW
256
10
653
520
-1
-1
55.7
1
14
1
1
1
0
0
0
1
0
6
0
8
0
0
1
ticks
30.0

BUTTON
10
110
73
143
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
115
155
178
188
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
25
155
102
188
go once
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
20
200
185
233
probability-mind-change
probability-mind-change
0
0.1
0.1
0.001
1
NIL
HORIZONTAL

SLIDER
20
245
185
278
success-rate
success-rate
0
1
1.0
0.05
1
NIL
HORIZONTAL

PLOT
685
195
990
340
 % republican vote (popular vote)
NIL
NIL
0.0
10.0
0.0
1.0
true
false
"" ""
PENS
"pen-1" 1.0 0 -2674135 true "" "plotxy ticks 0.5 "
"pen-2" 1.0 0 -16777216 true "" "plot pop-vote"

MONITOR
15
455
197
500
11 (9 + 2) electoral votes to
leader
17
1
11

PLOT
690
15
990
170
 %  republican house seats
NIL
NIL
0.0
10.0
0.0
1.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot state-maj"
"pen-2" 1.0 0 -3844592 true "" "plotxy ticks 0.5"

SLIDER
20
290
185
323
dem-probability
dem-probability
0
1
0.5
0.05
1
NIL
HORIZONTAL

PLOT
685
360
990
515
Standard Deviation of District %
NIL
NIL
0.0
10.0
0.0
0.5
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot polarization"
"pen-1" 1.0 0 -1184463 true "" "plot signal / 2"

PLOT
1025
370
1225
520
events
NIL
NIL
0.0
10.0
0.0
1.0
true
false
"" ""
PENS
"default" 1.0 0 -5298144 true "" "plot election"
"pen-1" 1.0 0 -1184463 true "" "plot signal"

SWITCH
25
60
162
93
City-Country
City-Country
1
1
-1000

SWITCH
25
15
202
48
gerrymendering-on
gerrymendering-on
1
1
-1000

MONITOR
15
395
87
440
Reversals
reversal
17
1
11

SWITCH
80
110
235
143
packing-or-craking
packing-or-craking
1
1
-1000

SLIDER
15
340
187
373
n-times
n-times
0
5
2.0
1
1
NIL
HORIZONTAL

PLOT
1025
205
1225
355
Number of strong districts
NIL
NIL
0.0
10.0
0.0
7.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot strong-com"
"pen-1" 1.0 0 -1184463 true "" "plot signal"

PLOT
1025
50
1225
200
Number of Competitive Districts
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot swing-com"
"pen-1" 1.0 0 -1184463 true "" "plot signal"

@#$#@#$#@
## WHAT IS IT?

The model aims at assessing the effect of different re-districting strategies in an ideal US state over a 100-year time horizon. The state is composed of 63 citizens grouped into 9 districts. The frame of the model is coherent with what we can observe in the US: two major parties (Republicans and Democrats), representatives elections held every even year and re-districting every ten years. Citizens are allowed to be either Republicans (in red, vote: +1) or Democrats (in blue, vote: -1) and change opinion with a given probability on a yearly basis (MindChange Probability).

Up to now, two famous strategies can be tested: cracking and packing. With cracking, the incumbent party tries to move supporting citizens from strong districts (where it has strong majority) to weak challenged districts where it has no majority but in which there is still the presence of some supporters. In the model, this involves swapping supporters from strong districts with adverse citizens from challenged districts. With packing, the incumbent party tries to pack adverse citizens in districts where the other party is already strong. This, in practice, involves swapping supporters in very weak districts with adversary citizens in challenged districts.

Of course, this is a simplification of how redistricting works. In fact, districts are re-drawn in practice and citizens are not required to move at all. The feasible actions for the gerrymander are in practice more limited than in the model.


NOTE: Be sure that the Nw extension is updated.
## HOW IT WORKS

### Entities, state variables and scales

The model moves along two main dimensions: space and time. Dealing with the space dimension, an ideal federal state is represented by a 9x7 lattice-world in which every node represents a citizen and every row of the lattice represents a district.

Citizens have one state variable "vote" which assumes values 1 if the citizen is inclined to vote for Republicans in a given year or -1  if the citizen is inclined to vote for Democrats in that year.
Moreover, citizen may assume other auxiliary state variables. "Community-type" is one of these and reports the characteristics of the citizen's district to the eyes of the incumbent, (whether a district is composed of strong supporters, strong antagonists or if it is potentially interesting).

For what concerns the time dimension, the horizon of the model is 100 years. In this time lapse, citizens vote for the state governor (incumbent) and for their representatives, change their opinion, and incumbents are allowed to exploit gerrymandering strategies.


### Process Overview and Scheduling
Every year, citizens are allowed to change idea about their voting intention with a given probability, which can be setup though the \emph{MindChange} global variable. 

Every even year, representatives elections are held. The representative of a given district is Republican if the majority within the district is Republican and vice versa for Democrats. Additionally the model keeps trace of the popular majority and of the standard deviation of votes composition between districts. The latter can be used as an index of polarization of the state.

Every 10 years, the incumbent (state governor) exploits gerrymandering after that representatives elections are held. For sake of simplicity, the incumbent is the party winning the popular vote in that year. Using the switch "packing-or-cracking", the observer can decide whether to implement one of two strategies, which will be described more in detail in the next subsection.

At the end of the 100-year time horizon, the global variable \emph{reversal} reports the number of reversals happened to the majority of representatives. The lowest the number of reversals the most effective the gerrymandering strategy exploited.

### DESIGN CONCEPTS

The main design concepts I wish to discuss here are: the two gerrymandering strategies implemented and the two possible initial dispositions of citizens.

For what concerns cracking, the strategy is implemented as follows. Every time the incumbent has the possibility to gerrymander, it repeats the following actions n times: 1) it counts how many districts can be classified as strongly supportive (with 5 or more supporters) and how many districts can be classified as interesting (3 supporters and 4 opponents, or 2 supporters and 5 opponents); 2) the gerrymander than chooses one supporter randomly from the strong district and swaps it with one random opponent belonging to the interesting district.

In a similar fashion, packing is implemented as follows. Every time the incumbent has the possibility to gerrymander, it repeats the following actions n times: 1) it counts how many districts can be classified as strongly adverse (with 5 or 6 opponents) and how many districts can be classified as interesting (3 supporters and 4 opponents, or 4 supporters and 3 opponents); 2) the gerrymander than chooses one supporter randomly from the strongly adverse district and swaps it with one random opponent belonging to the interesting district.

For what concerns the initial vote-state of citizens, I allow for two different options. The first and simplest is the random one. Every citizen has a probability "q" of being Republican and a probability "1-q" of being Democrat. By means of a slider ("Dem-probability"), the observe can control the probability of being Democrat. The second initial setup tries to mimic the stylized fact according to which democrats self-segregate in cities while republicans are predominant in rural area. This is done by linking the probability of being republican  to the y coordinate by means of a normalizing constant and a convex function. This way, democrats are more concentrated on the lower half of the lattice, hence simulating an ideal city. Of course, different solutions may be preferred.


## HOW TO USE IT

The initialization procedure is rather simple. 

1) As a first step, the observer decides whether he or she wants to allow for gerrymandering in the model. 

2) Then the observer chooses whether to adopt a random setup of citizens or a city-country setup. 

3) After that the decision is about which gerrymandering strategy to use: whether packing or cracking. 

4) SETUP & GO

Optionally, the observe can tweak the probability-of-mind-change, the gerrymandering  success rate (equal to 1oo% by default), the probability of being democrat (just in the random setup and 50% by default), and the number of rogerrymandering swaps implemented at each census (2 by default).


## THINGS TO NOTICE
Notice that the number of strong districts and standard deviation of districts composition increase on average with the packing strategy, while both decrease with the cracking strategy. Nonetheless, both strategies seems to lead to less reversals than no gerrymandering. This may suggest that both strategies are effective in favoring. incumbents

## THINGS TO TRY
Try to tweak the probability of mind change and see how the previously mentioned results vary. Try also to see the effect of natural seggregation by turning on the city-country switch.

## EXTENDING THE MODEL

The model could be extended and improved in several aspects. On the one hand, it may be interesting to codify different other strategies and study their effect. On the other hand, it may be interesting to add a continuous scale of voting beliefs for citizens ranging from convinced democrat to convinced republican. This way the probability that a citizen changes his/her opinion may vary according to the position along this scale.


## RELATED MODELS

* redistrictingPackNCrack
* NetDistrict by Collin Lysford
* Congressional Redistricting by Luke Elissiry 

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Antonio Peruzzi. (2020).  GerryMander 

Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.1.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="Experiment-pack-vs-crack" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>strong-com</metric>
    <metric>state-maj</metric>
    <metric>polarization</metric>
    <metric>reversal</metric>
    <enumeratedValueSet variable="success-rate">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="City-Country">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dem-probability">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="probability-mind-change">
      <value value="0"/>
      <value value="0.025"/>
      <value value="0.05"/>
      <value value="0.075"/>
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gerrymendering-on">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="packing-or-craking">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Experiment-reversal" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>reversal</metric>
    <enumeratedValueSet variable="success-rate">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="City-Country">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dem-probability">
      <value value="0.5"/>
    </enumeratedValueSet>
    <steppedValueSet variable="probability-mind-change" first="0.01" step="0.01" last="0.1"/>
    <enumeratedValueSet variable="gerrymendering-on">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="packing-or-craking">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Experiment-city-country-pack-vs-crack" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>strong-com</metric>
    <metric>state-maj</metric>
    <metric>polarization</metric>
    <metric>reversal</metric>
    <enumeratedValueSet variable="success-rate">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="city-country">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dem-probability">
      <value value="0.5"/>
    </enumeratedValueSet>
    <steppedValueSet variable="probability-mind-change" first="0.01" step="0.01" last="0.1"/>
    <enumeratedValueSet variable="gerrymendering-on">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="packing-or-craking">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
1
@#$#@#$#@
