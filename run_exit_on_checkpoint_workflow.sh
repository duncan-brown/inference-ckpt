#! /bin/bash

set -e

TAG=large #${1}
SEED=6789 #${2}
#workflow_name=pisn_run_${TAG}_seed_${SEED}_exit_at_ckpt
#output_dir=pisn_run_${TAG}_seed_${SEED}_exit_at_ckpt
workflow_name=exit_on_checkpoint_test
output_dir=exit_on_checkpoint_test

export OMP_NUM_THREADS=1

pycbc_make_inference_inj_workflow \
    --workflow-name ${workflow_name} \
    --data-type simulated_data \
    --output-dir ${output_dir} \
    --output-file ${workflow_name}.dax \
    --inference-config-file pisn_inference_${TAG}_eoc.ini \
    --config-files workflow_${TAG}_${SEED}_eoc.ini \
    --config-overrides "results_page:output-path:${PWD}/${output_dir}/results_html" "pegasus_profile-inference:pegasus|gridstart:NoGridStart" "pegasus_profile-inference:condor|+WantBadgers:True" \
    --inj-seed ${SEED}

pushd ${output_dir}
pycbc_submit_dax \
    --append-site-profile 'local:condor|requirements:((MY.JobUniverse == 5) || (MY.JobUniverse == 7) || (MY.JobUniverse == 12))' \
    --append-pegasus-property 'pegasus.data.configuration=condorio' \
    --no-grid \
    --no-create-proxy \
    --dax ${workflow_name}.dax \
    --accounting-group sugwg.astro \
    --no-submit

popd
