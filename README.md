# ForestDynamics_CC
This project studies the impact of climate change on forest dynamics using BiomeE



# BiomeE description
Biome Ecological strategy simulator (BiomeE) has been published in "Weng, E., Dybzinski, R., Farrior, C. E., and Pacala, S. W.: Competition alters predicted forest carbon cycle responses to nitrogen availability and elevated CO2: simulations using an explicitly competitive, game-theoretic vegetation demographic model, Biogeosciences, 16, 4577–4599, https://doi.org/10.5194/bg-16-4577-2019, 2019." as its supplementary material I.

In this model, vegetation is represented as plant functional types sampled from high dimensional spaces of combined plant traits that can consistently coexist in plant individuals. Individual plants are the basic unit to carry out physiological and demographic processes, e.g., photosynthesis, respiration, growth, reproduction, and mortality, and compete with each other. By this way, the model simulates competition for light and soil resources, community assembly and vegetation structural dynamics. Biogeochemical cycles are driven by the physiological and demographic activates of plants and microbes. The carbon and nitrogen in plant pools enter soil pools with plant mortality and turnover. The microbial decomposition processes drive soil carbon release and nitrogen mineralization.

# Climate change
Climate change is studied by adding a deviation from ambient conditions provided by the forcing data by including new factors for each environmental factor.      

For precipitation intensity, the ambient rain conditions were multiplied by a factor Sc_prcp.    

For temperature, the ambient temperature was changed by adding a factor Tchange (Tair = Tair + Tchange).     

For precipitation frequency, the pdf of ambient rain conditions was reformulated in a way to change rain frequency but maintaining the same overall amount of water received during that year. **NOTE: THIS IS STILL NOT INCLUDED     

Example, Precipitation reduction: if Sc_prcp = 0.1, the magnitude of the rain during the whole period of forcing is reduced to 0.1 * Rain
