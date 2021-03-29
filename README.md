# Automatic-Script-for-Running-Parallel-Jobs-in-Slurm
A bash script for handling millions of parallel jobs in Slurm. Accounts for fairshare limits by only applying the necessary time and memory required for repeated jobs. For example, suppose we would like to run simulations for an experiment with 10 factors, each with 2 levels, corresponding to 2^10 = 1024 combinations. For each of these combinations, we may want to run the simulation 1000 times to average out random noise, resulting in a 1024 * 1000 = 1,024,000 total simulations. 

To send these jobs manually will be **tedious** and **inefficent** since each of the combinations may result in different memory and run duration requirements. In other words, if you applied the same memory and run duration specifications for all jobs, some may need more memory/runtime, while others may waste resources by only needing a portion of what you had specified. The script combats this by first running a single representative run of each of the 1024 combinations, using a very generous amount of memory and runtime. It then saves the memory and runtime required for each of the combinations into a text file. Then, the script will run each of the 1024 combinations 999 times, parsing in the corresponding saved memory/runtime requirements from the file, with an extra amount of memory and time added to be safe.

Because Slurm usage limitations normally cap the total number of outstanding jobs at any given time at around 10,000, the script will actively make sure the jobs running at any given time do not exceed that amount. This is done by functions which monitor and parse results from the `squeue`, `sacct`, and `seff` commands in Slurm. The script also has error checking in that it will re-run any jobs that fail to run for whatever reason.

The specific version of the script included (`automatic_parallel_job_handler.sh`) was designed to run a specific set of simulations for the paper "Estimating Causal Effects Under Interference Using Bayesian Generalized Propensity Scores" https://arxiv.org/abs/1807.11038. The script has five factors which vary,

1) `EST_G` (if the model estimates interference) - 2 levels - True, False 
2) `COR` (how much correlation is in the generated data) - 3 levels - 0.2, 0.5, 0.8
3) `COEF_COR` (the coefficient in the interference model) - 3 levels - 2, 10, 20
4) `EST_RANDOM` (if the generated data accounts for random effects) - 2 levels, True, False
5) `RANDOM_MOD` (if the model accounts for random effects) - 2 levels, True, False

Each of these 72 settings are run in 500 repeated simulations, each with 4000 iterations, resulting in 2 * 3 * 3 * 2 * 2 * 500 = 72 * 500 = 36,000 total jobs needed to be submitted to Slurm, and a total of 36,000 * 4000 = 144,000,000 data structures we eventually obtained. Manually, one would typically need to send each of these 72 simulations in, each with a different memory and runtime specification, so as to not overload the 10,000 job cap. At a pace of 5 simulations a day, it may take two weeks to monitor and conduct this process. Using the script I wrote, I was instead able to do everything automatically with no monitoring and complete the simulations in 8 hours.



