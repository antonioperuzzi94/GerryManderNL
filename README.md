# GerryManderNL

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
Every year, citizens are allowed to change idea about their voting intention with a given probability, which can be setup though the MindChange global variable. 

Every even year, representatives elections are held. The representative of a given district is Republican if the majority within the district is Republican and vice versa for Democrats. Additionally the model keeps trace of the popular majority and of the standard deviation of votes composition between districts. The latter can be used as an index of polarization of the state.

Every 10 years, the incumbent (state governor) exploits gerrymandering after that representatives elections are held. For sake of simplicity, the incumbent is the party winning the popular vote in that year. Using the switch "packing-or-cracking", the observer can decide whether to implement one of two strategies, which will be described more in detail in the next subsection.

At the end of the 100-year time horizon, the global variable reversal reports the number of reversals happened to the majority of representatives. The lowest the number of reversals the most effective the gerrymandering strategy exploited.

### DESIGN CONCEPTS

The main design concepts I wish to discuss here are: the two gerrymandering strategies implemented and the two possible initial dispositions of citizens.

For what concerns cracking, the strategy is implemented as follows. Every time the incumbent has the possibility to gerrymander, it repeats the following actions n times: 1) it counts how many districts can be classified as strongly supportive (with 5 or more supporters) and how many districts can be classified as interesting (3 supporters and 4 opponents, or 2 supporters and 5 opponents); 2) the gerrymander than chooses one supporter randomly from the strong district and swaps it with one random opponent belonging to the interesting district.

In a similar fashion, packing is implemented as follows. Every time the incumbent has the possibility to gerrymander, it repeats the following actions $n$ times: 1) it counts how many districts can be classified as strongly adverse (with 5 or 6 opponents) and how many districts can be classified as interesting (3 supporters and 4 opponents, or 4 supporters and 3 opponents); 2) the gerrymander than chooses one supporter randomly from the strongly adverse district and swaps it with one random opponent belonging to the interesting district.

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

* Antonio Peruzzi. (2020).  GerryManderNL 

Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

