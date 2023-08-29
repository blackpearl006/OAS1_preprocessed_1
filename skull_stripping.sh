#!/bin/bash

# Specify the directory containing the folders with NIfTI files
data_dir="/Users/ninad/Downloads/OASIS_nifti_Part_2"
output_base_dir="/Users/ninad/Downloads/OASIS_Preprocessed_2"

# Create the main output directory if it doesn't exist
mkdir -p "$output_base_dir"

# Loop through each folder in the data directory
for folder in "$data_dir"/*; do
    if [[ -d "$folder" ]]; then
        # Check if the folder contains NIfTI files
        nifti_files=("$folder"/*.nii.gz)
        if [[ ${#nifti_files[@]} -gt 0 ]]; then
            subject_name=$(basename "$folder")
            output_dir="$output_base_dir/$subject_name"
            mkdir -p "$output_dir"
            
            echo "Processing folder: $folder"
            for nifti_file in "${nifti_files[@]}"; do
                nifti_filename=$(basename "$nifti_file" .nii.gz)
                
                fast -t 1 -n 3 -o "$output_dir/bias_corrected_brain" "$nifti_file"

                # Rename the required file for consistency
                mv "$output_dir/bias_corrected_brain_mixeltype.nii.gz" "$output_dir/bias_corrected_brain.nii.gz"
                
                # Register to MNI template using FLIRT
                registered_output="$output_dir/${subject_name}_${nifti_filename}_brain_n3_corrected_registered.nii.gz"
                flirt -in "$output_dir/bias_corrected_brain.nii.gz" -ref "$FSLDIR/data/standard/MNI152_T1_2mm.nii.gz" -out "$registered_output" -omat "$output_dir/${subject_name}_${nifti_filename}_registration.mat" -bins 256 -cost corratio -searchrx -180 180 -searchry -180 180 -searchrz -180 180 -dof 12 -interp trilinear
                
                # Skull stripping using bet2
                output_filename="${nifti_filename}_brain_n3_corrected_registered_skull_stripped.nii.gz"
                bet2 "$registered_output" "$output_dir/$output_filename" -f 0.5

                rm -f "$output_dir/bias_corrected_brain_pve_0.nii.gz" \
                    "$output_dir/bias_corrected_brain_pve_1.nii.gz" \
                    "$output_dir/bias_corrected_brain_pve_2.nii.gz" \
                    "$output_dir/bias_corrected_brain_pveseg.nii.gz" \
                    "$output_dir/bias_corrected_brain_seg.nii.gz" \
                    "$output_dir/bias_corrected_brain.nii.gz" \
                    "$output_dir/${subject_name}_${nifti_filename}_registration.mat" \
                    "$output_dir/${subject_name}_${nifti_filename}_brain_n3_corrected_registered.nii.gz"
            done
        fi
    fi
done
