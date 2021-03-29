LINEAR_MOD=T
EST_LINEAR=T
EST_MATCH=F
EST_CDA=F
EST_ITER=4000

Make folders!
for EST_G in T F; do for COR in 0.2 0.5 0.8; do for COEF_COR in 2 10 20; do 
mkdir Simulations_Linear_T_EstG_${EST_G}_Cor_${COR}_CorCoef_${COEF_COR}
mkdir Simulations_Linear_T_EstG_${EST_G}_Cor_${COR}_CorCoef_${COEF_COR}/CombineErrors_GPS_F
for RANDOM_MOD in T F; do for EST_RANDOM in T F; do
mkdir Simulations_Linear_T_EstG_${EST_G}_Cor_${COR}_CorCoef_${COEF_COR}/\
Linear_T_Random_${RANDOM_MOD}_EstLinear_T_EstRandom_${EST_RANDOM}_EstMatch_F
mkdir Simulations_Linear_T_EstG_${EST_G}_Cor_${COR}_CorCoef_${COEF_COR}/\
Linear_T_Random_${RANDOM_MOD}_EstLinear_T_EstRandom_${EST_RANDOM}_EstMatch_F/Error_Output
done;done
done;done;done

for EST_G in T F; do for COR in 0.2 0.5 0.8; do for COEF_COR in 2 10 20; do for EST_RANDOM in T F; do for RANDOM_MOD in T F; do

export LINEAR_MOD RANDOM_MOD EST_LINEAR EST_RANDOM EST_MATCH EST_CDA EST_G COR COEF_COR EST_ITER 

RES=$(sbatch --parsable --array=1 -o Simulations_Linear_T_EstG_${EST_G}_Cor_${COR}_CorCoef_${COEF_COR}/\
Linear_T_Random_${RANDOM_MOD}_EstLinear_T_EstRandom_${EST_RANDOM}_EstMatch_F/Error_Output/out_%A_%a.stdout.txt \
-e Simulations_Linear_T_EstG_${EST_G}_Cor_${COR}_CorCoef_${COEF_COR}/\
Linear_T_Random_${RANDOM_MOD}_EstLinear_T_EstRandom_${EST_RANDOM}_EstMatch_F/Error_Output/error_%A_%a.stdout.txt \
--job-name=Simulations_Linear_T_EstG_${EST_G}_Cor_${COR}_CorCoef_${COEF_COR}/\
Linear_T_Random_${RANDOM_MOD}_EstLinear_T_EstRandom_${EST_RANDOM}_EstMatch_F \
--time=50 \
--mem=8000 \
run_diag_parallel_shared.sbatch)

echo "Simulations_Linear_T_EstG_${EST_G}_Cor_${COR}_CorCoef_${COEF_COR}/\
Linear_T_Random_${RANDOM_MOD}_EstLinear_T_EstRandom_${EST_RANDOM}_EstMatch_F: ${RES}" >> jobids.txt

sleep 1
done;done;done;done;done

sleep 15

while [[ $(squeue -u albertwu --sort=+i | grep "" -c) -gt 1 ]]; do
    sleep 2
    let NUM=$(squeue -u albertwu --sort=+i | grep "" -c)
    echo "Waiting for all jobs to Finish. Remaining: $((${NUM}-1))"
done

# Parses job run time and outputs to jobstime.txt
while IFS= read -r line; do
ID=$(cut -d ":" -f2 <<< "$line")
LEN=$(seff $ID | grep "Job Wall-clock time:" | sed 's/^.*: //')
echo "$ID: $LEN" >> jobstime.txt
done < jobids.txt

# Parses job CPU and memory load and outputs to jobs_comp_req.txt
while IFS= read -r line; do
ID=$(cut -d ":" -f2 <<< "$line")
MB=$(( $(echo $(sacct -j $ID --format=MaxRss --units=K) | cut -d "K" -f 1 | sed 's/^.*- //') / 1000 ))
echo "$ID: $MB" >> jobs_comp_req.txt
done < jobids.txt


# RUN EVERY JOB ABOVE JUST ONCE TO GAUGE THE MEMORY AND RUNTIME REQUIREMENTS CORRESPONDING TO EACH COMBINATION

INITIAL=1
ENDING=500
LINEAR_MOD=T
EST_LINEAR=T
EST_MATCH=F
EST_CDA=F
EST_ITER=5000
for EST_G in T F; do for COR in 0.2 0.5 0.8; do for COEF_COR in 2 10 20; do for EST_RANDOM in T F; do for RANDOM_MOD in T F; do
export LINEAR_MOD RANDOM_MOD EST_LINEAR EST_RANDOM EST_MATCH EST_CDA EST_G COR COEF_COR EST_ITER
ID_NUM=$(grep "Simulations_Linear_T_EstG_${EST_G}_Cor_${COR}_CorCoef_${COEF_COR}/Linear_${LINEAR_MOD}_Random_${RANDOM_MOD}_EstLinear_${EST_LINEAR}_EstRandom_${EST_RANDOM}_EstMatch_${EST_MATCH}: " jobids.txt | cut -d ":" -f2)
ID_TIME=$(grep ${ID_NUM} jobstime.txt | sed 's/^.*: //' | awk -F: '{ print ($1 * 3600) + ($2 * 60) + $3 }')
MEM_NUM=$(grep ${ID_NUM} jobs_comp_req.txt | cut -d ":" -f2)
INCREMENT="300"  # We add 300 Mb to each job to be safe
MEM_REQ=$(echo "$MEM_NUM + $INCREMENT" | bc)
echo $ID_NUM
echo $ID_TIME
echo $MEM_REQ
if ls Simulations_Linear_T_EstG_${EST_G}_Cor_${COR}_CorCoef_${COEF_COR}/Linear_T_Random_${RANDOM_MOD}_EstLinear_T_EstRandom_${EST_RANDOM}_EstMatch_F/Sim.Run.List.{${INITIAL}..${ENDING}}.rds >/dev/null 2>&1;
then
    echo "AVAILABLE Simulations_Linear_T_EstG_${EST_G}_Cor_${COR}_CorCoef_${COEF_COR}/Linear_T_Random_${RANDOM_MOD}_EstLinear_T_EstRandom_${EST_RANDOM}_EstMatch_F" && break
else
    echo "MISSING Simulations_Linear_T_EstG_${EST_G}_Cor_${COR}_CorCoef_${COEF_COR}/Linear_T_Random_${RANDOM_MOD}_EstLinear_T_EstRandom_${EST_RANDOM}_EstMatch_F"
fi
# 1, 1-10, 11-111, 112-130
sbatch --array=${INITIAL}-${ENDING} -o Simulations_Linear_T_EstG_${EST_G}_Cor_${COR}_CorCoef_${COEF_COR}/\
Linear_T_Random_${RANDOM_MOD}_EstLinear_T_EstRandom_${EST_RANDOM}_EstMatch_F/Error_Output/out_%A_%a.stdout.txt \
-e Simulations_Linear_T_EstG_${EST_G}_Cor_${COR}_CorCoef_${COEF_COR}/\
Linear_T_Random_${RANDOM_MOD}_EstLinear_T_EstRandom_${EST_RANDOM}_EstMatch_F/Error_Output/error_%A_%a.stdout.txt \
--job-name=Simulations_Linear_T_EstG_${EST_G}_Cor_${COR}_CorCoef_${COEF_COR}/\
Linear_T_Random_${RANDOM_MOD}_EstLinear_T_EstRandom_${EST_RANDOM}_EstMatch_F \
--time=$((${ID_TIME}+5)) \
--mem=${MEM_REQ} \
run_diag_parallel_shared.sbatch
sleep 0.5
done;done;done;done;done




# TOTALLY SMART AND SELF-CONTAINED

while [[ $(squeue -u albertwu --sort=+i | grep "" -c) -gt 1 ]]; do
    sleep 2
    let NUM=$(squeue -u albertwu --sort=+i | grep "" -c)
    echo "Waiting for all jobs to Finish. Remaining: $((${NUM}-1))"
done


function total() {
    squeue -u albertwu -r "$@" | awk '
    NR>1 {a[$4]++}
    END {
        for (i in a) {
            printf "Total jobs for %-5s is: %d\n", i, a[i]
        }
    }'
}

function total_only() {
    squeue -u albertwu -r "$@" | awk '
    NR>1 {a[$4]++}
    END {
        for (i in a) {
            printf "%d\n", a[i]
        }
    }'
}



INITIAL=1
ENDING=500
INITIAL_INDEX=0
while [[ $(total_only) -gt 0 && $ENDING -lt 500 ]]; do
if [[ $(total_only) -lt 9500 ]]; then
DIFF=$(( 10000 - $(total_only) ))
DIFF_ADJ=$(( $(( $DIFF - 100 )) / 72 ))
if [[ $DIFF_ADJ -lt 1 ]]; then
    echo "Not enough available spaces, with ${DIFF} and ${DIFF_ADJ}"
    continue
fi
if [[ $INITIAL_INDEX == 0 ]]; then
    if [[ $(( $ENDING - $INITIAL )) -gt $DIFF_ADJ ]]; then
        ENDING=$(( $INITIAL + $DIFF_ADJ ))
    fi
    echo "Starting Initial Job Iteration is: ${INITIAL}"
    echo "Ending Job Iteration is: ${ENDING}"
    echo "Total Jobs Remaining: " $(total_only)
elif [[ $DIFF_ADJ -gt $(( 500 - $ENDING )) ]]; then
    INITIAL=$(( $ENDING + 1 ))
    ENDING=500
else
    INITIAL=$(( $ENDING + 1 )) 
    ENDING=$(( $ENDING + $DIFF_ADJ ))
fi
[[ $INITIAL_INDEX -ne 0 ]] && echo "New Initial Job Iteration is: ${INITIAL}"
[[ $INITIAL_INDEX -ne 0 ]] && echo "New Ending Job Iteration is: ${ENDING}"
[[ $INITIAL_INDEX -ne 0 ]] && echo "Total Jobs Remaining: " $(total_only)
LINEAR_MOD=T
EST_LINEAR=T
EST_MATCH=F
EST_CDA=F
EST_ITER=4000
ITERATOR=0
for EST_G in T F; do for COR in 0.2 0.5 0.8; do for COEF_COR in 2 10 20; do for EST_RANDOM in T F; do for RANDOM_MOD in T F; do
ITERATOR=$(( $ITERATOR + 1 ))
echo "Iteration Number ${ITERATOR} out of 72 Total"
export LINEAR_MOD RANDOM_MOD EST_LINEAR EST_RANDOM EST_MATCH EST_CDA EST_G COR COEF_COR EST_ITER
ID_NUM=$(grep "Simulations_Linear_T_EstG_${EST_G}_Cor_${COR}_CorCoef_${COEF_COR}/Linear_${LINEAR_MOD}_Random_${RANDOM_MOD}_EstLinear_${EST_LINEAR}_EstRandom_${EST_RANDOM}_EstMatch_${EST_MATCH}: " jobids.txt | cut -d ":" -f2)
ID_TIME=$(grep ${ID_NUM} jobstime.txt | sed 's/^.*: //' | awk -F: '{ print ($1 * 3600) + ($2 * 60) + $3 }')
MEM_NUM=$(grep ${ID_NUM} jobs_comp_req.txt | cut -d ":" -f2)
INCREMENT="300"  # We add 300 Mb to each job to be safe
MEM_REQ=$(echo "$MEM_NUM + $INCREMENT" | bc)
echo $ID_NUM
echo $ID_TIME
echo $MEM_REQ
if ls Simulations_Linear_T_EstG_${EST_G}_Cor_${COR}_CorCoef_${COEF_COR}/Linear_T_Random_${RANDOM_MOD}_EstLinear_T_EstRandom_${EST_RANDOM}_EstMatch_F/Sim.Run.List.{${INITIAL}..${ENDING}}.rds >/dev/null 2>&1;
then
    echo "${INITIAL}..${ENDING}_ALL_AVAILABLE Simulations_Linear_T_EstG_${EST_G}_Cor_${COR}_CorCoef_${COEF_COR}/Linear_T_Random_${RANDOM_MOD}_EstLinear_T_EstRandom_${EST_RANDOM}_EstMatch_F" && continue
else
    #echo "${INITIAL}..${ENDING}_MISSING Simulations_Linear_T_EstG_${EST_G}_Cor_${COR}_CorCoef_${COEF_COR}/Linear_T_Random_${RANDOM_MOD}_EstLinear_T_EstRandom_${EST_RANDOM}_EstMatch_F"
    a=()
    for f in $(eval echo Simulations_Linear_T_EstG_${EST_G}_Cor_${COR}_CorCoef_${COEF_COR}/Linear_T_Random_${RANDOM_MOD}_EstLinear_T_EstRandom_${EST_RANDOM}_EstMatch_F/Sim.Run.List.{${INITIAL}..${ENDING}}.rds); do 
        [ -f "$f" ] || a+=("$f");
    done
    b=$(echo ${a[@]//*List\.})
    NUM_RUN=${b[@]//.rds}
    JOINED=$( set -- $NUM_RUN; IFS=,; echo "$*" )
    echo $JOINED
    sbatch --array=$JOINED -o Simulations_Linear_T_EstG_${EST_G}_Cor_${COR}_CorCoef_${COEF_COR}/Linear_T_Random_${RANDOM_MOD}_EstLinear_T_EstRandom_${EST_RANDOM}_EstMatch_F/Error_Output/out_%A_%a.stdout.txt \
    -e Simulations_Linear_T_EstG_${EST_G}_Cor_${COR}_CorCoef_${COEF_COR}/Linear_T_Random_${RANDOM_MOD}_EstLinear_T_EstRandom_${EST_RANDOM}_EstMatch_F/Error_Output/error_%A_%a.stdout.txt \
    --job-name=Simulations_Linear_T_EstG_${EST_G}_Cor_${COR}_CorCoef_${COEF_COR}/Linear_T_Random_${RANDOM_MOD}_EstLinear_T_EstRandom_${EST_RANDOM}_EstMatch_F \
    --time=$((${ID_TIME}+5)) \
    --mem=${MEM_REQ} \
    run_diag_parallel_shared.sbatch
fi
sleep 1
done;done;done;done;done
INITIAL_INDEX=$(( $INITIAL_INDEX + 1 ))
fi
sleep 10
done



